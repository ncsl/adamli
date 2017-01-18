function serverAdjMainScript(patient, winSize, stepSize, frequency_sampling)
addpath(genpath('../../fragility_library/'));
addpath(genpath('../../eeg_toolbox/'));
addpath('../../');
IS_SERVER = 1;
if nargin == 0 % testing purposes
    patient='EZT005seiz001';
%     patient='JH102sz6';
%     patient='pt1sz4';
    % window paramters
    winSize = 500; % 500 milliseconds
    stepSize = 500; 
    frequency_sampling = 1000; % in Hz
    IS_SERVER = 1;
end

% setupScripts;
disp(['Looking at patient: ',patient]);

%% New Setup Scripts
TYPE_CONNECTIVITY = 'leastsquares';     % type of functional conn.?
BP_FILTER_RAW = 1;                      % apply notch filter before functional conn. computation?
IS_INTERICTAL = 0;                      % is this interictal data?
l2regularization = 0;                   % apply l2 regularization to estimation of functional conn.?

% set directory to find adjacency matrix data
toSaveAdjDir = fullfile(strcat('./fixed_adj_mats_win', num2str(winSize), ...
    '_step', num2str(stepSize), '_freq', num2str(frequency_sampling))); % at lab
dataDir = './data/';

% toSaveAdjDir = fullfile(strcat('/Volumes/NIL_PASS/serverdata/fixed_adj_mats_win', num2str(winSize), ...
%     '_step', num2str(stepSize), '_freq', num2str(frequency_sampling))); % at home
% dataDir = '/Volumes/NIL_PASS/data/';

if IS_SERVER
    toSaveAdjDir = fullfile('../..', 'serverdata', toSaveAdjDir);
    dataDir = strcat('../.', dataDir);
end

% create directory if it does not exist
if ~exist(toSaveAdjDir, 'dir')
    mkdir(toSaveAdjDir);
end

% set patientID and seizureID
patient_id = patient(1:strfind(patient, 'seiz')-1);
seizure_id = strcat('_', patient(strfind(patient, 'seiz'):end));
seeg = 1;
if isempty(patient_id)
    patient_id = patient(1:strfind(patient, 'sz')-1);
    seizure_id = patient(strfind(patient, 'sz'):end);
    seeg = 0;
end
if isempty(patient_id)
    patient_id = patient(1:strfind(patient, 'aslp')-1);
    seizure_id = patient(strfind(patient, 'aslp'):end);
    dataDir= './data/interictal_data/';
    if IS_SERVER
        dataDir = '../data/interictal_data/';
    end
end
if isempty(patient_id)
    patient_id = patient(1:strfind(patient, 'aw')-1);
    seizure_id = patient(strfind(patient, 'aw'):end);
end

%% DEFINE CHANNELS AND CLINICAL ANNOTATIONS
%- Edit this file if new patients are added.
[included_channels, ezone_labels, earlyspread_labels, latespread_labels, resection_labels, frequency_sampling] ...
            = determineClinicalAnnotations(patient_id, seizure_id);

% put clinical annotations into a struct
clinicalLabels = struct();
clinicalLabels.ezone_labels = ezone_labels;
clinicalLabels.earlyspread_labels = earlyspread_labels;
clinicalLabels.latespread_labels = latespread_labels;
clinicalLabels.resection_labels = resection_labels;

%% EZT/SEEG PATIENTS
if seeg
    patient_eeg_path = strcat(dataDir, 'Seiz_Data/', patient_id);
    patient = strcat(patient_id, seizure_id);
else
    patient_eeg_path = strcat(dataDir, patient);
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

% check to make sure eeg mat file was saved correctly with the right meta
% data
if seizureStart == 0 || seizureEnd == 0
    disp('Mat file from .csv was not saved correctly.');
end

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

% define args for computing the functional connectivity
adj_args = struct();
adj_args.BP_FILTER_RAW = BP_FILTER_RAW;                         % apply notch filter or not?
adj_args.frequency_sampling = frequency_sampling;   % frequency that this eeg data was sampled at
adj_args.winSize = winSize;                         % window size
adj_args.stepSize = stepSize;                       % step size
adj_args.seizureStart = seizureStart;               % the second relative to start of seizure
adj_args.seizureEnd = seizureEnd;                   % the second relative to end of seizure
adj_args.l2regularization = l2regularization; 
adj_args.TYPE_CONNECTIVITY = TYPE_CONNECTIVITY;

if size(eeg, 1) < winSize
    % compute connectivity
    [adjMats, timePoints] = computeConnectivity(eeg, adj_args);
else
    disp([patient, ' is underdetermined, must use optimization techniques']);
end

%%- Create the structure for the adjacency matrices for this patient/seizure
adjmat_struct = struct();
adjmat_struct.type_connectivity = TYPE_CONNECTIVITY;
adjmat_struct.ezone_labels = ezone_labels;
adjmat_struct.earlyspread_labels = earlyspread_labels;
adjmat_struct.latespread_labels = latespread_labels;
adjmat_struct.resection_labels = resection_labels;
adjmat_struct.all_labels = labels;
adjmat_struct.seizure_start = seizureStart;
adjmat_struct.seizure_end = seizureEnd;
adjmat_struct.winSize = winSize;
adjmat_struct.stepSize = stepSize;
adjmat_struct.timePoints = timePoints;
adjmat_struct.adjMats = adjMats;
adjmat_struct.included_channels = included_channels;
adjmat_struct.frequency_sampling = frequency_sampling;

fileName = strcat(patient, '_adjmats_', lower(TYPE_CONNECTIVITY), '.mat');

try
    save(fullfile(toSaveAdjDir, fileName), 'adjmat_struct');
catch e
    disp(e);
    save(fullfile(toSaveAdjDir, fileName), 'adjmat_struct', '-v7.3');
end

end