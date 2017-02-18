function sensitivityScript(patient, numRemove)
% script to perform sensitivity analysis for different electrodes removed
%- add libraries to path
addpath(genpath('../fragility_library/'));
addpath(genpath('../eeg_toolbox/'));
addpath('../../');

if nargin==0
    patient = 'pt1sz2';
    numRemove = 2;
end
% fprintf(patient);
% fprintf(numRemove);

%%- 0. Load in data for a wellperforming patient
% patient = 'pt1sz2';
TYPE_CONNECTIVITY = 'leastsquares';
winSize = 500;
stepSize = 500;
APPLY_FILTER = 0;
BP_FILTER_RAW = 1;

% set working directory
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
    seeg = 0;
end
if isempty(patient_id)
    patient_id = patient(1:strfind(patient, 'aw')-1);
    seizure_id = patient(strfind(patient, 'aw'):end);
    seeg = 0;
end

[included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
    resection_labels, frequency_sampling, center] ...
        = determineClinicalAnnotations(patient_id, seizure_id);
        
%- load in data dir of patient
dataDir = fullfile(rootDir, '/data/', center, patient);
data = load(fullfile(dataDir, patient));

eegdata = data.data;
included_labels = data.elec_labels;
seizureStart = data.seiz_start_mark;
seizureEnd = data.seiz_end_mark;

% apply included channels to eeg and labels
if ~isempty(included_channels)
    eegdata = eegdata(included_channels, :);
    included_labels = included_labels(included_channels);
end

% strip the data of electrode(s)
[N, T] = size(eegdata);

% find random electrodes to remove not within the EZ
ezone_indices = findElectrodeIndices(ezone_labels, included_labels);
earlyspread_indices = findElectrodeIndices(earlyspread_labels, included_labels);
latespread_indices = findElectrodeIndices(latespread_labels, included_labels);

% only keep electrodes not in EZ
elec_indices = 1:N;
elec_indices(ezone_indices) = [];

randIndices = randsample(elec_indices, numRemove);
eegdata(randIndices,:) = [];

%- location to save data
toSaveAdjDir = fullfile(rootDir, '/serverdata/adjmats', patient, strcat(patient, '_numelecs', N));

%%- 1. Run adjmat computation with data
% put clinical annotations into a struct
clinicalLabels = struct();
clinicalLabels.ezone_labels = ezone_labels;
clinicalLabels.earlyspread_labels = earlyspread_labels;
clinicalLabels.latespread_labels = latespread_labels;
clinicalLabels.resection_labels = resection_labels;

%% Set EEG Data Path
if seeg
    patient_eeg_path = fullfile(dataDir, patient_id);
    patient = strcat(patient_id, seizure_id);
else
    patient_eeg_path = fullfile(dataDir, patient);
end
patient_eeg_path
patient

if APPLY_FILTER % apply some filter for a set of patients at certain electrodes
    eegdata = apply_filter(eegdata, labels, patient_id);
end

% check to make sure eeg mat file was saved correctly with the right meta
% data
if seizureStart == 0 || seizureEnd == 0
    disp('Mat file from .csv was not saved correctly.');
end

if frequency_sampling ~=1000
    eegdata = eegdata(:, 1:(1000/frequency_sampling):end);
    seizureStart = seizureStart * frequency_sampling/1000;
    seizureEnd = seizureEnd * frequency_sampling/1000;
    winSize = winSize*frequency_sampling/1000;
    stepSize = stepSize*frequency_sampling/1000;
end

%% PERFORM ADJACENCY COMPUTATION
% define args for computing the functional connectivity
adj_args = struct();
adj_args.BP_FILTER_RAW = BP_FILTER_RAW;                         % apply notch filter or not?
adj_args.frequency_sampling = frequency_sampling;   % frequency that this eeg data was sampled at
adj_args.winSize = winSize;                         % window size
adj_args.stepSize = stepSize;                       % step size
adj_args.seizureStart = seizureStart;               % the second relative to start of seizure
adj_args.seizureEnd = seizureEnd;                   % the second relative to end of seizure
adj_args.TYPE_CONNECTIVITY = TYPE_CONNECTIVITY;

% compute connectivity
if size(eegdata, 1) < winSize
    [adjMats, timePoints] = computeConnectivity(eegdata, adj_args);
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


%%- 2. then Run perturbation algorithm