function serverComputeConnectivity(patient, winSize, stepSize, currentWin)
if nargin==0
    patient = 'pt3sz2';
    patient = 'pt1sz2';
    patient = 'Pat2sz1p';
    currentWin = 3;
end

if nargin<3
    winSize = 500;
    stepSize = 500;
end

%% INITIALIZATION
% data directories to save data into - choose one
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';     % work
% eegRootDirHome = '/Users/adam2392/Documents/MATLAB/Johns Hopkins/NINDS_Rotation';  % home
eegRootDirHome = '/Volumes/NIL_PASS/';
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
FILTER_RAW = 1; 
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

tempDir = fullfile('./tempData/', 'connectivity', strcat('win', num2str(winSize), ...
    '_step', numstr(stepSize)), patient);
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

% READ EEG FILE Mat File
% files to process
data = load(fullfile(patient_eeg_path, patient));
eeg = data.data;
labels = data.elec_labels;
onset_time = data.seiz_start_mark;
offset_time = data.seiz_end_mark;
seizureStart = (onset_time); % time seizure starts
seizureEnd = (offset_time); % time seizure ends

clear data
% check included channels length and how big eeg is
if length(labels(included_channels)) ~= size(eeg(included_channels,:),1)
    disp('Something wrong here...!!!!');
end

if frequency_sampling ~=1000
    seizureStart = seizureStart * frequency_sampling/1000;
    seizureEnd = seizureEnd * frequency_sampling/1000;
    winSize = winSize*frequency_sampling/1000;
    stepSize = stepSize*frequency_sampling/1000;
end

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
    eeg = buttfilt(eeg,[59.5 60.5], fs,'stop',1);
    eeg = buttfilt(eeg,[119.5 120.5], fs,'stop',1);
    if frequency_sampling >= 250
        eeg = buttfilt(eeg,[179.5 180.5], fs,'stop',1);
        eeg = buttfilt(eeg,[239.5 240.5], fs,'stop',1);

        if frequency_sampling >= 500
            eeg = buttfilt(eeg,[299.5 300.5], fs,'stop',1);
            eeg = buttfilt(eeg,[359.5 360.5], fs,'stop',1);
            eeg = buttfilt(eeg,[419.5 420.5], fs,'stop',1);
            eeg = buttfilt(eeg,[479.5 480.5], fs,'stop',1);
        end
    end
elseif FILTER_RAW == 2
     % apply an adaptive filtering algorithm.
    eeg = removePLI_multichan(eeg, fs, numHarmonics, [50,0.01,4], [0.1,2,4], 2, 60);
else 
    disp('no filtering?');
end


% paramters describing the data to be saved
% window parameters - overlap, #samples, stepsize, window pointer
lenData = size(eeg,2); % length of data in seconds
numChans = size(eeg,1);

% initialize timePoints vector and adjacency matrices
timePoints = [1:stepSize:lenData-winSize+1; winSize:stepSize:lenData]';

% get the window of data to compute adjacency
tempeeg = eeg(:, timePoints(currentWin,1):timePoints(currentWin,2));

clear eeg data

% save meta data for the computation 
if currentWin == 1
    info = struct();
    info.type_connectivity = TYPE_CONNECTIVITY;
    info.ezone_labels = ezone_labels;
    info.earlyspread_labels = earlyspread_labels;
    info.latespread_labels = latespread_labels;
    info.resection_labels = resection_labels;
    info.all_labels = labels;
    info.seizure_start = seizureStart;
    info.seizure_end = seizureEnd;
    info.winSize = winSize;
    info.stepSize = stepSize;
    info.timePoints = timePoints;
    info.included_channels = included_channels;
    info.frequency_sampling = frequency_sampling;
    info.FILTER_TYPE = FILTER_RAW;

    save(fullfile(tempDir, 'info', 'infoAdjMat.mat'), 'info');
end
fprintf('Should have finished saving info mat.\n');

% filename to be saved temporarily
fileName = strcat(patient, '_adjmats_', num2str(currentWin));

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
elseif strcmp(TYPE_CONNECTIVITY, 'spearman') || strcmp(TYPE_CONNECTIVITY, 'pearson')
    theta_adj = computePairwiseCorrelation(tmpdata, TYPE_CONNECTIVITY);
elseif strcmp(TYPE_CONNECTIVITY, 'PDC')
    A = theta_adj; 
    p_opt = 1;
    Nf = 250;
    [~, PDC] = computeDTFandPDC(A, p_opt, frequency_sampling, Nf);
elseif strcmp(TYPE_CONNECTIVITY, 'DTF')
    [DTF, ~] = computeDTFandPDC(A, p_opt, frequency_sampling, Nf);
end

% display a message for the user
fprintf(['Finished: ', num2str(currentWin), '\n']);

% save the file in temporary dir
save(fullfile(tempDir, fileName), 'theta_adj');
end