function parallelComputePerturbation(patient, winSize, stepSize, ... 
    radius, reference, iTask)
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
    reference = '';
    iTask = 100;
end

%% INITIALIZATION
% data directories to save data into - choose one
eegRootDirHD = '/Volumes/NIL Pass/';
eegRootDirHD = '/Volumes/ADAM LI/';
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
% eegRootDirHome = 'test';
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';    % at JHU workstation
eegRootDirMarcctest = '/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/'; % at MARCC server
eegRootDirMarcc = '/scratch/groups/ssarma2/adamli/fragility_dataanalysis/';

% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
% elseif ~isempty(dir(eegRootDirHD)), rootDir = eegRootDirHD;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
elseif ~isempty(dir(eegRootDirMarcc)), rootDir = eegRootDirMarcc;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), dataDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHD)), dataDir = eegRootDirHD;
elseif ~isempty(dir(eegRootDirJhu)), dataDir = eegRootDirJhu;
elseif ~isempty(dir(eegRootDirMarcc)), dataDir = eegRootDirMarcc;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

%% Parameters HARD CODED
%- 0 == no filtering
%- 1 == notch filtering
%- 2 == adaptive filtering
filterType = 'notchfilter';

perturbationTypes = ['C', 'R'];
w_space = linspace(-radius, radius, 51);
sigma = sqrt(radius^2 - w_space.^2); % move to the unit circle 1, for a plethora of different radial frequencies

% add to sigma and w to create a whole circle search
w_space = [w_space, w_space(2:end-1)];
sigma = [-sigma, sigma(2:end-1)];

% results of the ltv model 
ltvmodel_filename = strcat(patient, '_adjmats', reference, '_leastsquares.mat');

% filename to be saved temporarily
fileName = strcat(patient, '_pertmats', reference, '_', num2str(iTask));
    
%% DEFINE CHANNELS AND CLINICAL ANNOTATIONS
% set patientID and seizureID
[~, patient_id, seizure_id, ~] = splitPatient(patient);

%- Edit this file if new patients are added.
[~, ~, ~,...
    ~, ~, fs, ...
    ~] ...
            = determineClinicalAnnotations(patient_id, seizure_id);

tempDir = fullfile(rootDir, 'server/marccDev/matlab_lib/tempData/', ...
                'perturbation', filterType, ...
                strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
                patient, reference);
if ~exist(tempDir, 'dir')
    mkdir(tempDir);
end
        
%% Read in LTV Model Data
fprintf('Loading connectivity data...');
%- load the adjacency computed data
connDir = fullfile(dataDir, 'serverdata/adjmats', strcat(filterType), ...
                strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)),...
                patient, reference);
data = load(fullfile(connDir, ltvmodel_filename));
adjmat_struct = data.adjmat_struct;

% save meta data for the computation 
if iTask == 1
    fprintf('Making info struct\n');
    info = struct();
    info.type_connectivity = adjmat_struct.type_connectivity;
    info.ezone_labels = adjmat_struct.ezone_labels;
    info.earlyspread_labels = adjmat_struct.earlyspread_labels;
    info.latespread_labels = adjmat_struct.latespread_labels;
    info.resection_labels = adjmat_struct.resection_labels;
    info.all_labels = adjmat_struct.all_labels;
    info.included_channels = adjmat_struct.included_channels;
    info.frequency_sampling = adjmat_struct.frequency_sampling;
    
    info.seizure_estart_ms = adjmat_struct.seizure_estart_ms;       % store in ms
    info.seizure_eend_ms = adjmat_struct.seizure_eend_ms;
    info.seizure_cstart_ms = adjmat_struct.seizure_cstart_ms;
    info.seizure_coffset_ms = adjmat_struct.seizure_cend_ms;
    info.seizure_estart_mark = adjmat_struct.seizure_estart_mark;
    info.seizure_eend_mark = adjmat_struct.seizure_eend_mark;
    info.winSize = adjmat_struct.winSize;
    info.stepSize = adjmat_struct.stepSize;
    info.numSamplesInWin = adjmat_struct.numSamplesInWin;
    info.numSamplesInStep = adjmat_struct.numSamplesInStep;
    info.rawtimePoints = adjmat_struct.rawtimePoints;
    info.timePoints = adjmat_struct.timePoints;

    info.FILTER = adjmat_struct.FILTER;

    if ~exist(fullfile(tempDir, 'info'), 'dir')
        mkdir(fullfile(tempDir, 'info'));
    end
    
    save(fullfile(tempDir,'info', 'infoPertMat.mat'), 'info');
end

%- extract adjMat at this window
adjMat = squeeze(adjmat_struct.adjMats(iTask,:,:));
[N, ~] = size(adjMat);

% initialize the perturbation struct to save for this window
perturbation_struct = struct();
    
%%- Perform both perturbations
for iPert=1:length(perturbationTypes)
    perturbationType = perturbationTypes(iPert);

    % initialize vectors to store
%     minNormPerturbMat = zeros(N,1);
    fragilityMat = zeros(N,1);
%     del_table = cell(N,1);

    perturb_args = struct();
    perturb_args.perturbationType = perturbationType;
    perturb_args.w_space = w_space;
    perturb_args.radius = radius;
    perturb_args.sigma = sigma;

    [minNormPert, del_vecs, del_freqs, ERRORS] = minNormPerturbation(adjMat, perturb_args);

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
    perturbation_struct.(perturbationType).del_freqs = del_freqs;
    perturbation_struct.(perturbationType).minNormPertMat = minNormPerturbMat;
    perturbation_struct.(perturbationType).fragilityMat = fragilityMat;
end
    
% display a message for the user
fprintf(['Finished: ', num2str(iTask), '\n']);

% save the file in temporary dir
save(fullfile(tempDir, fileName), 'perturbation_struct');
end