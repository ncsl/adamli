function serverAdjMainScript(patient, winSize, stepSize, frequency_sampling)
addpath('../fragility_library/');
addpath(genpath('../eeg_toolbox/'));
addpath('../');

if nargin == 0 % testing purposes
    patient='EZT005seiz001';
    patient='JH102sz6';
    patient='pt1sz4';
    % window paramters
    winSize = 500; % 500 milliseconds
    stepSize = 500; 
    frequency_sampling = 1000; % in Hz
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

%% DEFINE CHANNELS AND CLINICAL ANNOTATIONS
[included_channels, ezone_labels, earlyspread_labels, latespread_labels] ...
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
toSaveAdjDir = fullfile(strcat('../adj_mats_win', num2str(winSize), ...
    '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient);
if ~exist(toSaveAdjDir, 'dir')
    mkdir(toSaveAdjDir);
end

%%- grab eeg data in different ways... depending on who we got it from
if ~seeg
    %% NIH, JHU PATIENTS
    %- set file path for the patient file 
    patient_eeg_path = strcat('../data/', patient);

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
    patient_eeg_path = strcat('../data/Seiz_Data/', patient_id);

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
if ~isempty(included_channels)
    try
        eeg = eeg(included_channels, :);
    catch e
        disp(e)
        disp('server adj main script.')
    end
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
% define args for computing the functional connectivity
adj_args = struct();
adj_args.BP_FILTER_RAW = 1; % apply notch filter or not?
adj_args.frequency_sampling = frequency_sampling; % frequency that this eeg data was sampled at
adj_args.winSize = winSize;
adj_args.stepSize = stepSize;
adj_args.timeRange = timeRange;
adj_args.toSaveAdjDir = toSaveAdjDir;
adj_args.included_channels = included_channels;
adj_args.seizureStart = seizureStart;
adj_args.seizureEnd = seizureEnd;
adj_args.labels = labels;

if size(eeg, 1) < winSize
    % compute connectivity
    computeConnectivity(patient_id, seizure_id, eeg, clinicalLabels, adj_args);
else
    disp([patient, ' is underdetermined, must use optimization techniques']);
end
end