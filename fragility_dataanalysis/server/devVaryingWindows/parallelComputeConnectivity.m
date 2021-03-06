function parallelComputeConnectivity(patient, winSize, stepSize, ...
                                            iProc, numProcs)
% function to compute the ltv model for a certain window based on
% - # of processors
% - # of windows
% - current processor used: iProc = {1, ..., 8}
if nargin == 0 % testing purposes
    patient='EZT009seiz001';
%     patient='JH102sz6';
    patient='pt1sz2';
    patient='Pat2sz2p';
    patient='UMMC001_sz1';
    % window paramters
    winSize = 250; % 500 milliseconds
    stepSize = 125; 
    iProc = 2;
    numProcs = 1;
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
l2regularization = 0;
% set options for connectivity measurements
OPTIONS.l2regularization = l2regularization;

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

% set dir to find raw data files
dataDir = fullfile(rootDir, '/data/', center);
% dataDir = fullfile('/Volumes/NIL_Pass/data', center);

tempDir = fullfile('./tempData/', 'connectivity', strcat('win', num2str(winSize), ...
    '_step', num2str(stepSize)), patient);
if ~exist(tempDir, 'dir')
    mkdir(tempDir);
end
        
% put clinical annotations into a struct
clinicalLabels = struct();
clinicalLabels.ezone_labels = ezone_labels;
clinicalLabels.earlyspread_labels = earlyspread_labels;
clinicalLabels.latespread_labels = latespread_labels;
clinicalLabels.resection_labels = resection_labels;

%% Read in EEG Raw Data and Preprocess
if seeg
    patient_eeg_path = fullfile(dataDir, patient_id);
    patient = strcat(patient_id, seizure_id);
else
    patient_eeg_path = fullfile(dataDir, patient);
end

fprintf('Loading data...');
% READ EEG FILE Mat File
% files to process
data = load(fullfile(patient_eeg_path, strcat(patient, '.mat')));
eeg = data.data;
labels = data.elec_labels;
engelscore = data.engelscore;
frequency_sampling = data.fs;
outcome = data.outcome;
seizure_eonset_ms = data.seizure_eonset_ms;
seizure_eoffset_ms = data.seizure_eoffset_ms;
seizure_conset_ms = data.seizure_conset_ms;
seizure_coffset_ms = data.seizure_coffset_ms;
fprintf('Loaded data...');
clear data
% check included channels length and how big eeg is
if length(labels(included_channels)) ~= size(eeg(included_channels,:),1)
    disp('Something wrong here...!!!!');
end

%- initialize the number of samples in the window / step (ms) 
numSampsInWin = winSize * frequency_sampling / 1000;
numSampsInStep = stepSize * frequency_sampling / 1000;

numWins = floor(size(eeg, 2) / numSampsInStep - numSampsInWin/numSampsInStep + 1);

%- determine current window
windows = iProc:numProcs*8:numWins;

% apply included channels to eeg and labels
if ~isempty(included_channels)
    eeg = eeg(included_channels, :);
    labels = labels(included_channels);
end

% set the number of harmonics
numHarmonics = floor(frequency_sampling/2/60) - 1;

%- apply filtering on the eegWave
if FILTER_RAW == 1
   % apply band notch filter to eeg data
    eeg = buttfilt(eeg,[59.5 60.5], frequency_sampling,'stop',1);
    eeg = buttfilt(eeg,[119.5 120.5], frequency_sampling,'stop',1);
    if frequency_sampling >= 250
        eeg = buttfilt(eeg,[179.5 180.5], frequency_sampling,'stop',1);
        eeg = buttfilt(eeg,[239.5 240.5], frequency_sampling,'stop',1);

        if frequency_sampling >= 500
            eeg = buttfilt(eeg,[299.5 300.5], frequency_sampling,'stop',1);
            eeg = buttfilt(eeg,[359.5 360.5], frequency_sampling,'stop',1);
            eeg = buttfilt(eeg,[419.5 420.5], frequency_sampling,'stop',1);
            eeg = buttfilt(eeg,[479.5 480.5], frequency_sampling,'stop',1);
        end
    end
elseif FILTER_RAW == 2
     % apply an adaptive filtering algorithm.
    eeg = removePLI_multichan(eeg, frequency_sampling, numHarmonics, [50,0.01,4], [0.1,2,4], 2, 60);
else 
    disp('no filtering?');
end

% paramters describing the data to be saved
% window parameters - overlap, #samples, stepsize, window pointer
lenData = size(eeg,2); % length of data in seconds
numChans = size(eeg,1);

% initialize timePoints vector and adjacency matrices
timePoints = [1:numSampsInStep:lenData-numSampsInWin+1; numSampsInWin:numSampsInStep:lenData]';

%- compute seizureStart/End Mark in time windows
seizureStartMark = find(timePoints(:,2) - seizure_eonset_ms * frequency_sampling / 1000 == 0);
seizureEndMark = find(timePoints(:,2) - seizure_eoffset_ms * frequency_sampling / 1000 == 0);

% save meta data for the computation 
if iProc == 1
    info = struct();
    info.type_connectivity = TYPE_CONNECTIVITY;
    info.ezone_labels = ezone_labels;
    info.earlyspread_labels = earlyspread_labels;
    info.latespread_labels = latespread_labels;
    info.resection_labels = resection_labels;
    info.all_labels = labels;
    info.seizure_estart_ms = seizure_eonset_ms;       % store in ms
    info.seizure_eend_ms = seizure_eoffset_ms;
    info.seizure_cstart_ms = seizure_conset_ms;
    info.seizure_coffset_ms = seizure_coffset_ms;
    info.seizure_estart_mark = seizureStartMark;
    info.seizure_eend_mark = seizureEndMark;
    info.engelscore = engelscore;
    info.outcome = outcome;
    info.winSize = winSize;
    info.stepSize = stepSize;
    info.numSamplesInWin = numSampsInWin;
    info.numSamplesInStep = numSampsInStep;
    info.rawtimePoints = timePoints;
    temptimePoints = timePoints;
    temptimePoints(:, 1) = timePoints(:, 1) - 1;
    info.timePoints = (temptimePoints - seizure_eonset_ms * frequency_sampling / 1000) ./ frequency_sampling;
    info.included_channels = included_channels;
    info.frequency_sampling = frequency_sampling;
    info.FILTER_TYPE = FILTER_RAW;

    if ~exist(fullfile(tempDir, 'info'), 'dir')
        mkdir(fullfile(tempDir, 'info'));
    end
    
    save(fullfile(tempDir,'info', 'infoAdjMat.mat'), 'info');
end
fprintf('Should have finished saving info mat.\n');


%- save file for all the windows
for iWin=1:length(windows)
    currentWin = windows(iWin);
    % filename to be saved temporarily
    fileName = strcat(patient, '_adjmats_', num2str(currentWin));

    % get the window of data to compute adjacency
    tempeeg = eeg(:, timePoints(currentWin,1):timePoints(currentWin,2));

    %% Perform Least Squares Computations
    % step 2: compute some functional connectivity 
    if strcmp(TYPE_CONNECTIVITY, 'leastsquares')
        fprintf('About to start least squares');
        % linear model: Ax = b; A\b -> x
        b = double(tempeeg(:)); % define b as vectorized by stacking columns on top of another
        b = b(numChans+1:end); % only get the time points after the first one

        % - use least square computation
        theta = computeLeastSquares(tempeeg, b, OPTIONS);
        fprintf('Finished least squares');
        theta_adj = reshape(theta, numChans, numChans)';    % reshape fills in columns first, so must transpose
    end

    % display a message for the user
    fprintf(['Finished: ', num2str(currentWin), '\n']);

    % save the file in temporary dir
    save(fullfile(tempDir, fileName), 'theta_adj');
end
end