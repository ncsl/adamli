function parallelComputeConnectivity(patient, winSize, stepSize, reference, iTask)
% function to compute the ltv model for a certain window based on
% - # of processors
% - # of windows
% - current processor used: iProc = {1, ..., 8}
if nargin == 0 % testing purposes
    patient='EZT009seiz001';
%     patient='JH102sz6';
    patient='pt1sz2';
%     patient='Pat2sz2p';
%     patient='UMMC001_sz1';
%     patient='LA01_ICTAL';
    % window paramters
    winSize = 250; % 500 milliseconds
    stepSize = 125; 
    iTask = 2;
    numProcs = 1;
    numWins = 103;
    reference = 'avgref';
end
fprintf('Inside parallel computing connectivity...\n');

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
% FILTER_RAW = 2; 
filterType = 'notchfilter';
TYPE_CONNECTIVITY = 'leastsquares';
l2regularization = 0;
% set options for connectivity measurements
OPTIONS.l2regularization = l2regularization;
fs = 1000; % 1 kHz sampling by default

% filename to be saved temporarily
fileName = strcat(patient, '_adjmats', reference, '_', num2str(iTask));

%% DEFINE CHANNELS AND CLINICAL ANNOTATIONS
% set patientID and seizureID
[~, patient_id, seizure_id, seeg] = splitPatient(patient);

%- Edit this file if new patients are added.
[included_channels, ezone_labels, earlyspread_labels,...
    latespread_labels, resection_labels, fs, ...
    center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);

% set dir to find raw data files
dataDir = fullfile(dataDir, '/data/', center);

tempDir = fullfile(rootDir, 'server/marccDev/matlab_lib/tempData/', ...
                'connectivity', filterType, ...
                strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
                patient, reference);
if ~exist(tempDir, 'dir')
    mkdir(tempDir);
end

%% Read in EEG Raw Data
if seeg
    patient_eeg_path = fullfile(dataDir, patient);
%     patient = strcat(patient_id, seizure_id); % for EZT pats
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

%- initialize the number of samples in the window / step (ms) 
numSampsInWin = winSize * frequency_sampling / 1000;
numSampsInStep = stepSize * frequency_sampling / 1000;
numWins = floor(size(eeg, 2) / numSampsInStep - numSampsInWin/numSampsInStep + 1);

% apply included channels to eeg and labels
if ~isempty(included_channels)
    eeg = eeg(included_channels, :);
end

%% Perform Preprocessing - Referencing and Filtering
% perform common average referencing if needed
if strcmp(reference, 'avgref')
    if size(eeg, 1) > size(eeg, 2)
        eeg = eeg';
    end
    avg = mean(eeg, 1);
    eeg = eeg-avg;
end

% paramters describing the data to be saved
% window parameters - overlap, #samples, stepsize, window pointer
lenData = size(eeg,2); % length of data in seconds
numChans = size(eeg,1);

%- apply filtering on the eegWave
if strcmp(filterType, 'notchfilter')
   % apply band notch filter to eeg data
    eeg = buttfilt(eeg,[59.5 60.5], frequency_sampling,'stop',1);
    eeg = buttfilt(eeg,[119.5 120.5], frequency_sampling,'stop',1);
    if frequency_sampling >= 500
        eeg = buttfilt(eeg,[179.5 180.5], frequency_sampling,'stop',1);
        eeg = buttfilt(eeg,[239.5 240.5], frequency_sampling,'stop',1);

        if frequency_sampling >= 1000
            eeg = buttfilt(eeg,[299.5 300.5], frequency_sampling,'stop',1);
            eeg = buttfilt(eeg,[359.5 360.5], frequency_sampling,'stop',1);
            eeg = buttfilt(eeg,[419.5 420.5], frequency_sampling,'stop',1);
            eeg = buttfilt(eeg,[479.5 480.5], frequency_sampling,'stop',1);
        end
    end
elseif strcmp(filterType, 'adaptivefilter')
    % set the number of harmonics
    numHarmonics = floor(frequency_sampling/2/60) - 1;

     % apply an adaptive filtering algorithm.
    eeg = removePLI_multichan(eeg, frequency_sampling, numHarmonics, [50,0.01,4], [0.1,2,4], 2, 60);
else 
    disp('no filtering?');
end

% initialize timePoints vector and adjacency matrices
timePoints = [1:numSampsInStep:lenData-numSampsInWin+1; numSampsInWin:numSampsInStep:lenData]';

%- compute seizureStart/End Mark in time windows
seizureStartMark = find(timePoints(:,2) - seizure_eonset_ms * frequency_sampling / 1000 == 0);
seizureEndMark = find(timePoints(:,2) - seizure_eoffset_ms * frequency_sampling / 1000 == 0);

% save meta data for the computation 
if iTask == 1
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
    info.FILTER_TYPE = filterType;

    if ~exist(fullfile(tempDir, 'info'), 'dir')
        mkdir(fullfile(tempDir, 'info'));
    end
    
    save(fullfile(tempDir,'info', 'infoAdjMat.mat'), 'info');
end
fprintf('Should have finished saving info mat.\n');

% get the window of data to compute adjacency
tempeeg = eeg(:, timePoints(iTask,1):timePoints(iTask,2));

%% Perform Least Squares Computations
% step 2: compute some functional connectivity 
if strcmp(TYPE_CONNECTIVITY, 'leastsquares')
    fprintf('About to start least squares\n');
    % linear model: Ax = b; A\b -> x
    b = double(tempeeg(:)); % define b as vectorized by stacking columns on top of another
    b = b(numChans+1:end); % only get the time points after the first one

    % - use least square computation
    theta = computeLeastSquares(tempeeg, b, OPTIONS);
    fprintf('Finished least squares');
    theta_adj = reshape(theta, numChans, numChans)';    % reshape fills in columns first, so must transpose
end

% display a message for the user
fprintf([reference, ' Finished: ', num2str(iTask), '\n']);

% save the file in temporary dir
save(fullfile(tempDir, fileName), 'theta_adj');
end