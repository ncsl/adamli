function serverAdjMainScript(patient, winSize, stepSize)
IS_SERVER = 1;
if nargin == 0 % testing purposes
    center = 'cc';
    patient='EZT009seiz001';
%     patient='JH102sz6';
    patient='pt7sz19';
    patient ='UMMC009_sz2';
    % window paramters
    winSize = 250; % 500 milliseconds
    stepSize = 125; 
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
FILTERTYPE = 2; 
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
    latespread_labels, resection_labels, fs, ...
    center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
patient_id = buffpatid;

% set dir to find raw data files
dataDir = fullfile(rootDir, '/data/', center);
% dataDir = fullfile('/Volumes/NIL_Pass/data', center);

if FILTERTYPE == 1
    toSaveDir = fullfile(rootDir, strcat('/serverdata/adjmats/notchfilter', '/win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
elseif FILTERTYPE == 2
    toSaveDir = fullfile(rootDir, strcat('/serverdata/adjmats/adaptivefilter', '/win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
else 
    toSaveDir = fullfile(rootDir, strcat('/serverdata/adjmats/nofilter', 'win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
end
% create directory if it does not exist
if ~exist(toSaveDir, 'dir')
    mkdir(toSaveDir);
end
toSaveDir
        
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

fprintf('\nLoading data...');
% READ EEG FILE Mat File
% files to process
data = load(fullfile(patient_eeg_path, strcat(patient, '.mat')));
eeg = data.data;
labels = data.elec_labels;
engelscore = data.engelscore;
fs = data.fs;
outcome = data.outcome;
seizure_eonset_ms = data.seizure_eonset_ms;
seizure_eoffset_ms = data.seizure_eoffset_ms;
seizure_conset_ms = data.seizure_conset_ms;
seizure_coffset_ms = data.seizure_coffset_ms;
fprintf('\nLoaded data...');
clear data
% check included channels length and how big eeg is
if length(labels(included_channels)) ~= size(eeg(included_channels,:),1)
    disp('Something wrong here...!!!!');
end

% apply included channels to eeg and labels
if ~isempty(included_channels)
    eeg = eeg(included_channels, :);
    labels = labels(included_channels);
end

%- apply filtering on the eegWave
if FILTERTYPE == 1
   % apply band notch filter to eeg data
    eeg = buttfilt(eeg,[59.5 60.5], fs,'stop',1);
    eeg = buttfilt(eeg,[119.5 120.5], fs,'stop',1);
    if fs >= 250
        eeg = buttfilt(eeg,[179.5 180.5], fs,'stop',1);
        eeg = buttfilt(eeg,[239.5 240.5], fs,'stop',1);

        if fs >= 500
            eeg = buttfilt(eeg,[299.5 300.5], fs,'stop',1);
            eeg = buttfilt(eeg,[359.5 360.5], fs,'stop',1);
            eeg = buttfilt(eeg,[419.5 420.5], fs,'stop',1);
            eeg = buttfilt(eeg,[479.5 480.5], fs,'stop',1);
        end
    end
elseif FILTERTYPE == 2
    % set the number of harmonics
    numHarmonics = floor(fs/2/60) - 1;

     % apply an adaptive filtering algorithm.
    eeg = removePLI_multichan(eeg, fs, numHarmonics, [50,0.01,4], [0.1,2,4], 2, 60);
else 
    disp('no filtering?');
end

%- initialize the number of samples in the window / step (ms) 
numSampsInWin = winSize * fs / 1000;
numSampsInStep = stepSize * fs / 1000;
numWins = floor(size(eeg, 2) / numSampsInStep - numSampsInWin/numSampsInStep + 1);

% paramters describing the data to be saved
% window parameters - overlap, #samples, stepsize, window pointer
lenData = size(eeg,2); % length of data in seconds
num_channels = size(eeg,1);

% initialize timePoints vector and adjacency matrices
timePoints = [1 : numSampsInStep : lenData-numSampsInWin+1; numSampsInWin : numSampsInStep : lenData]';
adjMats = zeros(size(timePoints,1), num_channels, num_channels);

%- compute seizureStart/End Mark in time windows
seizure_estart_mark = find(timePoints(:,2) - seizure_eonset_ms * fs / 1000 == 0);
seizure_eend_mark = find(timePoints(:,2) - seizure_eoffset_ms * fs / 1000 == 0);

timeStarts = timePoints(:, 1);
timeEnds = timePoints(:, 2);

buffeeg = cell(numWins, 1);
for iWin=1:numWins
    buffeeg{iWin} = eeg(:, timeStarts(iWin):timeEnds(iWin));
end
clear eeg

% compute for each window
parfor iWin=1:numWins 
     % get the window of data to compute adjacency
%     tempeeg = eeg(:, timeStarts(iWin):timeEnds(iWin));
    tempeeg = buffeeg{iWin};

     %% Perform Least Squares Computations
    % step 2: compute some functional connectivity 
    if strcmp(TYPE_CONNECTIVITY, 'leastsquares')
        fprintf('About to start least squares');
        % linear model: Ax = b; A\b -> x
        b = double(tempeeg(:)); % define b as vectorized by stacking columns on top of another
        b = b(num_channels+1:end); % only get the time points after the first one

        % - use least square computation
        theta = computeLeastSquares(tempeeg, b, OPTIONS);
        fprintf('Finished least squares');
        theta_adj = reshape(theta, num_channels, num_channels)';    % reshape fills in columns first, so must transpose
    end
    
    adjMats(iWin, :, :) = theta_adj;

    % display a message for the user
    fprintf(['Finished: ', num2str(iWin), '\n']);
end

%%- Create the structure for the adjacency matrices for this patient/seizure
adjmat_struct = struct();
adjmat_struct.type_connectivity = TYPE_CONNECTIVITY;
adjmat_struct.ezone_labels = ezone_labels;
adjmat_struct.earlyspread_labels = earlyspread_labels;
adjmat_struct.latespread_labels = latespread_labels;
adjmat_struct.resection_labels = resection_labels;
adjmat_struct.all_labels = labels;
adjmat_struct.seizure_estart_ms = seizure_eonset_ms;       % store in ms
adjmat_struct.seizure_eend_ms = seizure_eoffset_ms;
adjmat_struct.seizure_cstart_ms = seizure_conset_ms;
adjmat_struct.seizure_cend_ms = seizure_coffset_ms;
adjmat_struct.seizure_estart_mark = seizure_estart_mark;
adjmat_struct.seizure_eend_mark = seizure_eend_mark;
adjmat_struct.engelscore = engelscore;
adjmat_struct.outcome = outcome;
adjmat_struct.winSize = winSize;
adjmat_struct.stepSize = stepSize;
adjmat_struct.timePoints = timePoints;
adjmat_struct.adjMats = adjMats;
adjmat_struct.included_channels = included_channels;
adjmat_struct.fs = fs;
adjmat_struct.FILTER = FILTERTYPE;

fileName = strcat(patient, '_adjmats_', lower(TYPE_CONNECTIVITY), '.mat');

try
    save(fullfile(toSaveDir, fileName), 'adjmat_struct');
catch e
    disp(e);
    save(fullfile(toSaveDir, fileName), 'adjmat_struct', '-v7.3');
end

end