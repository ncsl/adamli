function serverComputeConnectivity(patient, currentWin)
if nargin==0
    patient = 'pt3sz2';
    patient = 'pt1sz2';
    patient = 'Pat2sz1p';
    currentWin = 3;
end


% add libraries of functions
addpath(('../../'));
addpath(genpath('../../eeg_toolbox/'));
addpath(genpath('../../fragility_library/'));
% addpath(genpath('/Users/adam2392/Dropbox/eeg_toolbox/'));
% addpath(genpath('/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/eeg_toolbox/'));

IS_SERVER = 1;
IS_INTERICTAL = 1; % need to change per run of diff data
TYPE_CONNECTIVITY = 'leastsquares';
l2regularization = 0;
winSize = 500;
stepSize = 500;

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



%% DEFINE CHANNELS AND CLINICAL ANNOTATIONS
%- Edit this file if new patients are added.
[included_channels, ezone_labels, earlyspread_labels, latespread_labels, resection_labels, frequency_sampling, center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);

% set directory to find adjacency matrix data
dataDir = fullfile('./data/', center);

if IS_SERVER
    dataDir = strcat('../.', dataDir);
end        
        
% put clinical annotations into a struct
clinicalLabels = struct();
clinicalLabels.ezone_labels = ezone_labels;
clinicalLabels.earlyspread_labels = earlyspread_labels;
clinicalLabels.latespread_labels = latespread_labels;
clinicalLabels.resection_labels = resection_labels;

%% EZT/SEEG PATIENTS
if seeg
    patient_eeg_path = fullfile(dataDir, patient_id);
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
recording_start = 0; % since they dont' give absolute time of starting the recording
seizureStart = (onset_time - recording_start); % time seizure starts
seizureEnd = (offset_time - recording_start); % time seizure ends
recording_duration = size(data.data, 2);
num_channels = size(data.data, 1);

clear data
% check included channels length and how big eeg is
if length(labels(included_channels)) ~= size(eeg(included_channels,:),1)
    disp('Something wrong here...!!!!');
end

if frequency_sampling ~=1000
    eeg = eeg(:, 1:(1000/frequency_sampling):end);
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
    
tempDir = fullfile('./tempData/', patient, 'connectivity');
if ~exist(tempDir, 'dir')
    mkdir(tempDir);
end

BP_FILTER_RAW=1;
%- apply a bandpass filter raw data? (i.e. pre-filter the wave?)
if BP_FILTER_RAW==1,
    preFiltFreq      = [1 499];   %[1 499] [2 250]; first bandpass filter data from 1-499 Hz
    preFiltType      = 'bandpass';
    preFiltOrder     = 2;
    preFiltStr       = sprintf('%s filter raw; %.1f - %.1f Hz',preFiltType,preFiltFreq);
    preFiltStrShort  = '_BPfilt';
    eeg = buttfilt(eeg,[59.5 60.5], frequency_sampling,'stop',1);
%     eeg = buttfilt(eeg,[59.5 60.5], frequency_sampling,'stop',1);
else
    preFiltFreq      = []; %keep this empty to avoid any filtering of the raw data
    preFiltType      = 'stop';
    preFiltOrder     = 1;
    preFiltStr       = 'Unfiltered raw traces';
    preFiltStrShort  = '_noFilt';
end

% set stepsize and window size to reflect sampling rate (milliseconds)
stepSize = stepSize * frequency_sampling/1000; 
winSize = winSize * frequency_sampling/1000;

% paramters describing the data to be saved
% window parameters - overlap, #samples, stepsize, window pointer
lenData = size(eeg,2); % length of data in seconds
numWindows = lenData/stepSize;
numChans = size(eeg,1);

% initialize timePoints vector and adjacency matrices
timePoints = [1:stepSize:lenData-winSize+1; winSize:stepSize:lenData]';

% apply band notch filter to eeg data
tempeeg = eeg(:, timePoints(currentWin,1):timePoints(currentWin,2));

% test = whos
% sum = 0;
% for i=1:length(test)
%     sum = sum+test(i).bytes;
% end
% sum / 10^6
% clear eeg from RAM after usage
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

    save(fullfile(tempDir, 'infoAdjMat'), 'info');
end
fprintf('Should have finished saving info mat.\n');

% filename to be saved temporarily
fileName = strcat(patient, '_adjmats_', num2str(currentWin));
fid = fopen(fullfile(tempDir, strcat(patient, num2str(currentWin))), 'w');
fprintf(fid, 'Wrote');
fclose(fid);
% fprintf(fileName);

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