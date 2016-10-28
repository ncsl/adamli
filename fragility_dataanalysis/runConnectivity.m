clear all;
close all;
clc;

% settings to run
patients = {'pt11sz1' 'pt3sz2' 'pt3sz4' 'pt8sz1' 'pt8sz2' 'pt8sz3'...
		'pt10sz1' 'pt10sz2' 'pt10sz3'  'pt11sz2' 'pt11sz3' 'pt11sz4'...
%     'JH102sz1', 'JH102sz2', 'JH102sz3', 'JH102sz4', 'JH102sz5', 'JH102sz6',...
    %'EZT030seiz001' ...
%     'EZT030seiz002' 'EZT037seiz001' 'EZT037seiz002',...
% 	'EZT070seiz001' 'EZT070seiz002', ...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
%     'pt1sz2', 'pt1sz3', 'pt2sz1', 'pt2sz3', 'JH105sz1', 'pt7sz19', 'pt7sz21', 'pt7sz22',  ...
%     'EZT005_seiz001', 'EZT005_seiz002', 'EZT007_seiz001', 'EZT007_seiz002', ...
%     'EZT019_seiz001', 'EZT019_seiz002', 'EZT090_seiz002', 'EZT090_seiz003', ...
    };
% patients = { 'EZT108_seiz002', 'EZT120_seiz001', 'EZT120_seiz002'}; %,
% patients = {'Pat2sz1p', 'Pat2sz2p', 'Pat2sz3p'};%, 'Pat16sz1p', 'Pat16sz2p', 'Pat16sz3p'};
perturbationTypes = ['R', 'C'];
w_space = linspace(-1, 1, 101);
radius = 1.5;             % spectral radius
threshold = 0.8;          % threshold on fragility metric
winSize = 500;            % 500 milliseconds
stepSize = 500; 
frequency_sampling = 1000; % in Hz
timeRange = [60 0];


% add libraries of functions
addpath('./fragility_library/');
addpath(genpath('/Users/adam2392/Dropbox/eeg_toolbox'));
addpath(genpath('/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/eeg_toolbox/'));

%%- Begin Loop Through Different Patients Here
for p=1:length(patients)
    patient = patients{p};
   
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
        dataDir = './data/';
        patient_eeg_path = strcat('./data/', patient);
        patient_file_path = fullfile(dataDir, patient, strcat(patient, '.csv'));

        %- set the meta data using the patient input file
        [~, ~, recording_start, ...
         onset_time, offset_time, ...
         recording_duration, num_channels] = readLabels(patient_file_path);
        number_of_samples = frequency_sampling * recording_duration;
        seizureStart = milliseconds(onset_time - recording_start); % time seizure starts
        seizureEnd = milliseconds(offset_time - recording_start); % time seizure ends

        % extract labels
        patient_label_path = fullfile(dataDir, patient, strcat(patient, '_labels.csv'));
        fid = fopen(patient_label_path); % open up labels to get all the channels
        labels = textscan(fid, '%s', 'Delimiter', ',');
        labels = labels{:}; 
        try
            labels = labels(included_channels);
        catch
            disp('labels already clipped');
            length(labels) == length(included_channels)
        end
        fclose(fid);

        % READ EEG FILE
        % files to process
        f = dir([patient_eeg_path '/*eeg.csv']);
        patient_file_names = cell(1, length(f));
        for iChan=1:length(f)
            patient_file_names{iChan} = f(iChan).name;
        end
        patient_files = containers.Map(patient_file_names, number_of_samples)
        
        %- Extract EEG and Perform Analysis
        filename = patient_file_names{1};
        num_values = patient_files(patient_file_names{1});
        % extract eeg 
        eeg = csv2eeg(patient_eeg_path, filename, num_values, num_channels);
    else
        %% EZT/SEEG PATIENTS
        patient_eeg_path = strcat('./data/Seiz_Data/', patient_id);

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
        eeg = eeg(included_channels, :);
    end
    
    if frequency_sampling ~=1000
        disp('downsampling to ');
        frequency_sampling
        size(eeg)
        seizureStart
        seizureEnd
        eeg = eeg(:, 1:(1000/frequency_sampling):end);
        seizureStart = seizureStart * frequency_sampling/1000;
        seizureEnd = seizureEnd * frequency_sampling/1000;

        size(eeg)
        seizureStart
        seizureEnd
    end
    
    % only take included_channels
    if ~isempty(included_channels)
        num_channels = num_channels;
    end
    
    % create the adjacency file directory to store the computed adj. mats
    toSaveAdjDir = fullfile(strcat('./adj_mats_win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient);
    if ~exist(toSaveAdjDir, 'dir')
        mkdir(toSaveAdjDir);
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
    
%     if seizureStart < 60 * frequency_sampling
%         disp('not 60 seconds of preseizure data');
%         waitforbuttonpress;
%     end
    
    % compute connectivity
    computeConnectivity(patient_id, seizure_id, eeg, clinicalLabels, adj_args);
    
    %% 02: RUN PERTURBATION ANALYSIS
    for j=1:length(perturbationTypes)
        perturbationType = perturbationTypes(j);
        
        toSaveFinalDataDir = fullfile(strcat('./adj_mats_win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), strcat(perturbationType, '_finaldata', ...
            '_radius', num2str(radius)));
        if ~exist(toSaveFinalDataDir, 'dir')
            mkdir(toSaveFinalDataDir);
        end
        
        perturb_args = struct();
        perturb_args.perturbationType = perturbationType;
        perturb_args.w_space = w_space;
        perturb_args.radius = radius;
        perturb_args.frequency_sampling = frequency_sampling;
        perturb_args.adjDir = toSaveAdjDir;
        perturb_args.toSaveFinalDataDir = toSaveFinalDataDir;
        perturb_args.labels = labels;
        perturb_args.included_channels = included_channels;
        perturb_args.num_channels = size(eeg, 1);
        
        computePerturbations(patient_id, seizure_id, perturb_args);
    end
end
