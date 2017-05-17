function parallelComputePerturbation(patient, winSize, stepSize, ... 
    radius, iProc, numProcs)
% function to compute the ltv model for a certain window based on
% - # of processors
% - # of windows
% - current processor used: iProc = {1, ..., 8}
if nargin == 0 % testing purposes
    patient='EZT009seiz001';
%     patient='JH102sz6';
    patient='pt1sz2';
    % window paramters
    winSize = 250; % 500 milliseconds
    stepSize = 125; 
    iProc = 2;
    numProcs = 1;
    radius = 1.5;
    numWins = 103;
end

%% INITIALIZATION
% data directories to save data into - choose one
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';     % work
% eegRootDirHome = '/Users/adam2392/Documents/MATLAB/Johns Hopkins/NINDS_Rotation';  % home
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';
% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

%- 0 == no filtering
%- 1 == notch filtering
%- 2 == adaptive filtering
FILTER_RAW = 2; 
TYPE_CONNECTIVITY = 'leastsquares';
frequency_sampling = 1000;

patient_id = [];
seeg = 1;
if isempty(patient_id)
    patient_id = patient(1:strfind(patient, 'sz')-1);
    seizure_id = patient(strfind(patient, 'sz'):end);
    seeg = 0;
end
if isempty(patient_id)
    patient_id = patient(1:strfind(patient, 'aslp')-1);
    seizure_id = patient(strfind(patient, 'aslp'):end);
    seeg = 0;
end
if isempty(patient_id)
    patient_id = patient(1:strfind(patient, 'aw')-1);
    seizure_id = patient(strfind(patient, 'aw'):end);
    seeg = 0;
end
 buffpatid = patient_id;
if strcmp(patient_id(end), '_')
    patient_id = patient_id(1:end-1);
end
%% DEFINE CHANNELS AND CLINICAL ANNOTATIONS
%- Edit this file if new patients are added.
[included_channels, ezone_labels, earlyspread_labels,...
    latespread_labels, resection_labels, frequency_sampling, ...
    center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
patient_id = buffpatid;

perturbationTypes = ['C', 'R'];
w_space = linspace(-radius, radius, 51);
sigma = sqrt(radius^2 - w_space.^2); % move to the unit circle 1, for a plethora of different radial frequencies
b = [0; 1];                          % initialize for perturbation computation later

% add to sigma and w to create a whole circle search
w_space = [w_space, w_space];
sigma = [-sigma, sigma];

%- temp directory
tempDir = fullfile('./tempData/', 'perturbation', strcat('win', num2str(winSize), ...
    '_step', num2str(stepSize)), patient);
if ~exist(tempDir, 'dir')
    mkdir(tempDir);
end
        
%% Read in LTV Model Data
fprintf('Loading data...');

%- load the adjacency computed data
if FILTER_RAW == 1
    connDir = fullfile(rootDir, 'serverdata/adjmats/notchfilter/', strcat('win', num2str(winSize), ...
    '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient); % at lab
elseif FILTER_RAW == 2
    connDir = fullfile(rootDir, 'serverdata/adjmats/adaptivefilter/', strcat('win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient); % at lab
else 
    connDir = fullfile(rootDir, 'serverdata/adjmats/nofilter/', strcat('win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient); % at lab
end
load(fullfile(connDir, strcat(patient, '_adjmats_leastsquares.mat')));

%- initialize the number of samples in the window / step (ms) 
numWins = size(adjmat_struct.adjMats, 1);

%- determine current window
windows = iProc:numProcs*8:numWins;


adjmat_struct.type_connectivity;
adjmat_struct.ezone_labels;
adjmat_struct.earlyspread_labels;
adjmat_struct.latespread_labels;
adjmat_struct.resection_labels;
adjmat_struct.all_labels;
adjmat_struct.seizure_estart_ms;       % store in ms
adjmat_struct.seizure_eend_ms;
adjmat_struct.seizure_cstart_ms;
adjmat_struct.seizure_cend_ms;
adjmat_struct.seizure_estart_mark;
adjmat_struct.seizure_eend_mark;
adjmat_struct.engelscore;
adjmat_struct.outcome;
adjmat_struct.winSize;
adjmat_struct.stepSize;
adjmat_struct.timePoints;
adjmat_struct.adjMats;
adjmat_struct.included_channels;
adjmat_struct.frequency_sampling;
adjmat_struct.FILTER;

%% Loop Through Each Window and Compute Perturbation
for iWin=1:length(windows)
    currentWin = windows(iWin);
    
    %- save the first window into an info struct for the perturbation
    if iWin==1 && iProc == 1
        %- set meta data struct
        info.ezone_labels = adjmat_struct.ezone_labels;
        info.earlyspread_labels = adjmat_struct.earlyspread_labels;
        info.latespread_labels = adjmat_struct.latespread_labels;
        info.resection_labels = adjmat_struct.resection_labels;
        info.all_labels = adjmat_struct.all_labels;
        info.seizure_estart_ms = adjmat_struct.seizure_estart_ms;       % store in ms
        info.seizure_eend_ms = adjmat_struct.seizure_eend_ms;
        info.seizure_cstart_ms = adjmat_struct.seizure_cstart_ms;
        info.seizure_coffset_ms = adjmat_struct.seizure_cend_ms;
        info.seizure_estart_mark = adjmat_struct.seizure_estart_mark;
        info.seizure_eend_mark = adjmat_struct.seizure_eend_mark;
        info.winSize = adjmat_struct.winSize;
        info.stepSize = adjmat_struct.stepSize;
        info.frequency_sampling = adjmat_struct.fs;
        info.included_channels = adjmat_struct.included_channels;
        info.FILTER = adjmat_struct.FILTER;
        info.timePoints = adjmat_struct.timePoints;
        info.TYPE_CONNECTIVITY = adjmat_struct.type_connectivity;

        if ~exist(fullfile(tempDir, 'info'), 'dir')
            mkdir(fullfile(tempDir, 'info'));
        end
        save(fullfile(tempDir, 'info', 'infoPertMat.mat'), 'info'); 
    end
    
    %- extract adjMat at this window
    adjMat = squeeze(adjmat_struct.adjMats(iWin,:,:));
    [N, ~] = size(adjMat);
    
    % initialize the perturbation struct to save for this window
    perturbation_struct = struct();
    
    %%- Perform both perturbations
    for iPert=1:length(perturbationTypes)
        perturbationType = perturbationTypes(iPert);
        
        % initialize vectors to store
        minNormPerturbMat = zeros(N,1);
        fragilityMat = zeros(N,1);
        del_table = cell(N,1);

        perturb_args = struct();
        perturb_args.perturbationType = perturbationType;
        perturb_args.w_space = w_space;
        perturb_args.radius = radius;

        [minNormPert, del_vecs, ERRORS] = minNormPerturbation(patient, adjMat, perturb_args);

        % store results
        minNormPerturbMat = minNormPert;
        del_table = del_vecs;

        %% 3. Compute fragility rankings per column by normalization
        % Compute fragility rankings per column by normalization
        for i=1:N      % loop through each channel
            fragilityMat(i) = (max(minNormPerturbMat(:)) - minNormPerturbMat(i)) ...
                                        / max(minNormPerturbMat(:));
        end

        % initialize struct to save
        perturbation_struct.(perturbationType) = struct();
        perturbation_struct.(perturbationType).del_table = del_table;
        perturbation_struct.(perturbationType).minNormPertMat = minNormPerturbMat;
        perturbation_struct.(perturbationType).fragilityMat = fragilityMat;
    end
    
    % display a message for the user
    fprintf(['Finished: ', num2str(currentWin), '\n']);

        % filename to be saved temporarily
    fileName = strcat(patient, '_pertmats_', num2str(currentWin));

    
    % save the file in temporary dir
    save(fullfile(tempDir, fileName), 'perturbation_struct');
end
end