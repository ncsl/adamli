function serverPerturbationScript(patient, radius, winSize, stepSize, frequency_sampling)
addpath('../fragility_library/');
addpath(genpath('../eeg_toolbox/'));
addpath('../');
perturbationTypes = ['R', 'C'];
w_space = linspace(-1, 1, 101);

if nargin == 0 % testing purposes
    patient='EZT007seiz001';
    patient ='pt7sz19';
    % window paramters
    radius = 1.1;
    winSize = 250; % 500 milliseconds
    stepSize = 250; 
    frequency_sampling = 1000; % in Hz
end

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

%%- grab eeg data in different ways... depending on who we got it from
if ~seeg
    %% NIH, JHU PATIENTS
    %- set file path for the patient file 
    patient_eeg_path = strcat('../data/', patient);

    % READ EEG FILE Mat File
    % files to process
    data = load(fullfile(patient_eeg_path, patient));
    labels = data.elec_labels;
    onset_time = data.seiz_start_mark;
    offset_time = data.seiz_end_mark;
    recording_start = 0; % since they dont' give absolute time of starting the recording
    seizureStart = (onset_time - recording_start); % time seizure starts
    seizureEnd = (offset_time - recording_start); % time seizure ends
    recording_duration = size(data.data, 2);
    num_channels = length(included_channels);
else
    %% EZT/SEEG PATIENTS
    patient_eeg_path = strcat('../data/Seiz_Data/', patient_id);

    % READ EEG FILE Mat File
    % files to process
    data = load(fullfile(patient_eeg_path, patient));
    labels = data.elec_labels;
    onset_time = data.seiz_start_mark;
    offset_time = data.seiz_end_mark;
    recording_start = 0; % since they dont' give absolute time of starting the recording
    seizureStart = (onset_time - recording_start); % time seizure starts
    seizureEnd = (offset_time - recording_start); % time seizure ends
    recording_duration = size(data.data, 2);
    num_channels = length(included_channels);
end

if frequency_sampling ~=1000
    seizureStart = seizureStart * frequency_sampling/1000;
    seizureEnd = seizureEnd * frequency_sampling/1000;
end

%% 01:  RUN PERTURBATION ANALYSIS
% only take included_channels
if ~isempty(included_channels)
    num_channels = num_channels;
end

% create the adjacency file directory to store the computed adj. mats
toSaveAdjDir = fullfile(strcat('../adj_mats_win', num2str(winSize), ...
    '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient);
if ~exist(toSaveAdjDir, 'dir')
    mkdir(toSaveAdjDir);
end

% try
    for j=1:length(perturbationTypes)
        perturbationType = perturbationTypes(j);

        toSaveFinalDataDir = fullfile(strcat('../adj_mats_win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), strcat(perturbationType, '_finaldata', ...
            '_radius', num2str(radius)));
        if ~exist(toSaveFinalDataDir, 'dir')
            mkdir(toSaveFinalDataDir);
        end

        perturb_args = struct();
        perturb_args.perturbationType = perturbationType;
        perturb_args.w_space = w_space;
        perturb_args.radius = radius;
        perturb_args.adjDir = toSaveAdjDir;
        perturb_args.toSaveFinalDataDir = toSaveFinalDataDir;
        perturb_args.labels = labels;
        perturb_args.included_channels = included_channels;
        perturb_args.num_channels = num_channels;
        perturb_args.frequency_sampling = frequency_sampling;

        computePerturbations(patient_id, seizure_id, perturb_args);
    end
% catch e
%     disp(e);
%     disp([patient, ' is underdetermined in perturbation analysis, must use optimization techniques']);
end