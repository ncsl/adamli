l2regularization = 0.0;
adjMat = './adj_mats_win';
dataDir = './data/';
if IS_SERVER
    adjMat = '../adj_mats_win';
    dataDir = '../data/';
end

timeRange = [60 0];

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
[included_channels, ezone_labels, earlyspread_labels, latespread_labels, frequency_sampling] ...
            = determineClinicalAnnotations(patient_id, seizure_id);

% put clinical annotations into a struct
clinicalLabels = struct();
clinicalLabels.ezone_labels = ezone_labels;
clinicalLabels.earlyspread_labels = earlyspread_labels;
clinicalLabels.latespread_labels = latespread_labels;

%% DEFINE COMPUTATION PARAMETERS AND DIRECTORIES TO SAVE DATA
patient = strcat(patient_id, seizure_id);
disp(['Looking at patient: ',patient]);

% create the adjacency file directory to store the computed adj. mats
toSaveAdjDir = fullfile(strcat(adjMat, num2str(winSize), ...
    '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient);
if ~exist(toSaveAdjDir, 'dir')
    mkdir(toSaveAdjDir);
end

%%- grab eeg data in different ways... depending on who we got it from
if ~seeg
    %% NIH, JHU PATIENTS
    %- set file path for the patient file 
    patient_eeg_path = strcat(dataDir, patient);

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
else
    %% EZT/SEEG PATIENTS
    patient_eeg_path = strcat(dataDir, 'Seiz_Data/', patient_id);

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
end

% only take included_channels
if ~isempty(included_channels) && ~exist('ECG', 'var')
    try
        eeg = eeg(included_channels, :);
        labels = labels(included_channels);
    catch e
        disp(e)
        disp('server adj main script.')
    end
end

if length(labels) ~= size(eeg,1)
    disp('Something wrong here...!!!!');
end

if frequency_sampling ~=1000
    eeg = eeg(:, 1:(1000/frequency_sampling):end);
    seizureStart = seizureStart * frequency_sampling/1000;
    seizureEnd = seizureEnd * frequency_sampling/1000;
%     winSize = winSize*frequency_sampling/1000;
%     stepSize = stepSize*frequency_sampling/1000;
end

%% 01: RUN FUNCTIONAL CONNECTIVITY COMPUTATION
if seizureStart < 60 * frequency_sampling
        timeRange(1) = seizureStart/frequency_sampling;
end