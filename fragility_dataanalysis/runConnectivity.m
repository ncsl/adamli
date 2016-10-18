clear all;
close all;
clc;

% settings to run
patients = {'pt1sz2', 'pt1sz3', 'pt2sz1', 'pt2sz3', 'JH105sz1', 'pt7sz19', 'pt7sz21', 'pt7sz22',  ...
%     'EZT005_seiz001', 'EZT005_seiz002', 'EZT007_seiz001', 'EZT007_seiz002', ...
%     'EZT019_seiz001', 'EZT019_seiz002', 'EZT090_seiz002', 'EZT090_seiz003', ...
    };
% patients = { 'EZT108_seiz002', 'EZT120_seiz001', 'EZT120_seiz002'}; %,
% patients = {'Pat2sz1p', 'Pat2sz2p', 'Pat2sz3p'};%, 'Pat16sz1p', 'Pat16sz2p', 'Pat16sz3p'};
perturbationTypes = ['R', 'C'];
w_space = linspace(-1, 1, 101);
radius = 1.1;             % spectral radius
threshold = 0.8;          % threshold on fragility metric
winSize = 500;            % 500 milliseconds
stepSize = 500; 
frequency_sampling = 500; % in Hz
timeRange = [60 0];


% add libraries of functions
addpath('./fragility_library/');
addpath(genpath('/Users/adam2392/Dropbox/eeg_toolbox'));
addpath(genpath('/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/eeg_toolbox/'));

%%- Begin Loop Through Different Patients Here
for p=1:length(patients)
    patient = patients{p};
   
    patient_id = patient(1:strfind(patient, 'seiz')-2);
    seizure_id = strcat('_', patient(strfind(patient, 'seiz'):end));
    seeg = 1;
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'sz')-1);
        seizure_id = patient(strfind(patient, 'sz'):end);
        seeg = 0;
    end

    %% DEFINE CHANNELS AND CLINICAL ANNOTATIONS
    if strcmp(patient_id, 'EZT007')
        included_channels = [1:16 18:53 55:71 74:78 81:94];
        ezone_labels = {'O7', 'E8', 'E7', 'I5', 'E9', 'I6', 'E3', 'E2',...
            'O4', 'O5', 'I8', 'I7', 'E10', 'E1', 'O6', 'I1', 'I9', 'E6',...
            'I4', 'O3', 'O2', 'I10', 'E4', 'Y1', 'O1', 'I3', 'I2'}; %pt1
        earlyspread_labels = {};
        latespread_labels = {};
    elseif strcmp(patient_id, 'EZT005')
        included_channels = [1:21 23:60 63:88];
        ezone_labels = {'U4', 'U3', 'U5', 'U6', 'U8', 'U7'}; 
        earlyspread_labels = {};
         latespread_labels = {};
    elseif strcmp(patient_id, 'EZT019')
        included_channels = [1:5 7:22 24:79];
        ezone_labels = {'I5', 'I6', 'B9', 'I9', 'T10', 'I10', 'B6', 'I4', ...
            'T9', 'I7', 'B3', 'B5', 'B4', 'I8', 'T6', 'B10', 'T3', ...
            'B1', 'T8', 'T7', 'B7', 'I3', 'B2', 'I2', 'T4', 'T2'}; 
        earlyspread_labels = {};
         latespread_labels = {}; 
     elseif strcmp(patient_id, 'EZT045') % FAILURES 2 EZONE LABELS?
        included_channels = [1 3:14 16:20 24:28 30:65];
        ezone_labels = {'X2', 'X1'}; %pt2
        earlyspread_labels = {};
         latespread_labels = {}; 
      elseif strcmp(patient_id, 'EZT090') % FAILURES
        included_channels = [1:25 27:42 44:49 51:73 75:90 95:111];
        ezone_labels = {'N2', 'N1', 'N3', 'N8', 'N9', 'N6', 'N7', 'N5'}; 
        earlyspread_labels = {};
         latespread_labels = {};
    elseif strcmp(patient_id, 'EZT108')
        included_channels = [];
        ezone_labels = {'F2', 'V7', 'O3', 'O4'}; % marked ictal onset areas
        earlyspread_labels = {};
        latespread_labels = {};
    elseif strcmp(patient_id, 'EZT120')
        included_channels = [];
        ezone_labels = {'C7', 'C8', 'C9', 'C6', 'C2', 'C10', 'C1'};
        earlyspread_labels = {};
        latespread_labels = {};
    elseif strcmp(patient_id, 'Pat2')
        included_channels = [];
        ezone_labels = {};
        earlyspread_labels = {};
        latespread_labels = {};
    elseif strcmp(patient_id, 'Pat16')
        included_channels = [];
        ezone_labels = {};
        earlyspread_labels = {};
        latespread_labels = {};
    elseif strcmp(patient_id, 'pt7')
        included_channels = [1:17 19:35 37:38 41:62 67:109];
        ezone_labels = {};
        earlyspread_labels = {};
        latespread_labels = {};
    elseif strcmp(patient_id, 'pt1')
        included_channels = [1:36 42 43 46:69 72:95];
        ezone_labels = {'POLATT1', 'POLATT2', 'POLAD1', 'POLAD2', 'POLAD3'}; %pt1
        earlyspread_labels = {'POLATT3', 'POLAST1', 'POLAST2'};
        latespread_labels = {'POLATT4', 'POLATT5', 'POLATT6', ...
                            'POLSLT2', 'POLSLT3', 'POLSLT4', ...
                            'POLMLT2', 'POLMLT3', 'POLMLT4', 'POLG8', 'POLG16'};
    elseif strcmp(patient_id, 'pt2')
        included_channels = [1:14 16:19 21:25 27:37 43 44 47:74];
        ezone_labels = {'POLMST1', 'POLPST1', 'POLTT1'}; %pt2
        earlyspread_labels = {'POLTT2', 'POLAST2', 'POLMST2', 'POLPST2', 'POLALEX1', 'POLALEX5'};
         latespread_labels = {};
    elseif strcmp(patient_id, 'JH105')
        included_channels = [1:4 7:12 14:19 21:37 42 43 46:49 51:53 55:75 78:99]; % JH105
        ezone_labels = {'POLRPG4', 'POLRPG5', 'POLRPG6', 'POLRPG12', 'POLRPG13', 'POLG14',...
            'POLAPD1', 'POLAPD2', 'POLAPD3', 'POLAPD4', 'POLAPD5', 'POLAPD6', 'POLAPD7', 'POLAPD8', ...
            'POLPPD1', 'POLPPD2', 'POLPPD3', 'POLPPD4', 'POLPPD5', 'POLPPD6', 'POLPPD7', 'POLPPD8', ...
            'POLASI3', 'POLPSI5', 'POLPSI6', 'POLPDI2'}; % JH105
        earlyspread_labels = {};
         latespread_labels = {};
    end

    % put clinical annotations into a struct
    clinicalLabels = struct();
    clinicalLabels.ezone_labels = ezone_labels;
    clinicalLabels.earlyspread_labels = earlyspread_labels;
    clinicalLabels.latespread_labels = latespread_labels;

    %% DEFINE COMPUTATION PARAMETERS AND DIRECTORIES TO SAVE DATA
    patient = strcat(patient_id, seizure_id);
    disp(['Looking at patient: ',patient]);

    % create the adjacency file directory to store the computed adj. mats
    toSaveAdjDir = fullfile(strcat('.adj_mats_win', num2str(winSize), ...
    '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)), patient);
    if ~exist(toSaveAdjDir, 'dir')
        mkdir(toSaveAdjDir);
    end

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

        % READ EEG FILE
        % files to process
        f = dir([patient_eeg_path '/*eeg.csv']);
        patient_file_names = cell(1, length(f));
        for iChan=1:length(f)
            patient_file_names{iChan} = f(iChan).name;
        end
        patient_files = containers.Map(patient_file_names, number_of_samples)

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

    %% 01: RUN FUNCTIONAL CONNECTIVITY COMPUTATION
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

    if seizureStart < 60 * frequency_sampling
        disp('not 60 seconds of preseizure data');
        waitforbuttonpress;
    end
    
    % compute connectivity
    computeConnectivity(patient_id, seizure_id, eeg, clinicalLabels, adj_args);
    
    %% 02: RUN PERTURBATION ANALYSIS
    for j=1:length(perturbationTypes)
        perturbationType = perturbationTypes(j);
        
        toSaveFinalDataDir = fullfile(strcat('./adj_mats_win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)),...
            strcat(perturbationType, '_finaldata'));
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
        perturb_args.num_channels = size(eeg, 1);
        
        computePerturbations(patient_id, seizure_id, perturb_args);
    end
    
    %% 03: PLOT PERTURBATION RESULTS
    for j=1:length(perturbationTypes)
        perturbationType = perturbationTypes(j);

        toSaveFinalDataDir = fullfile(strcat('./adj_mats_win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)),...
            strcat(perturbationType, '_finaldata'));
        if ~exist(toSaveFinalDataDir, 'dir')
            mkdir(toSaveFinalDataDir);
        end
        
        toSaveFigDir = fullfile('./figures/', perturbationType, strcat(patient, num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)));
        if ~exist(toSaveFigDir, 'dir')
            mkdir(toSaveFigDir);
        end
        
        toSaveWeightsDir = fullfile('./figures/', strcat(perturbationType, '_electrode_weights'), strcat(patient, num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)));
        if ~exist(toSaveWeightsDir, 'dir')
            mkdir(toSaveWeightsDir);
        end

        plot_args = struct();
        plot_args.perturbationType = perturbationType;
        plot_args.radius = radius;
        plot_args.finalDataDir = toSaveFinalDataDir;
        plot_args.toSaveFigDir = toSaveFigDir;
        plot_args.toSaveWeightsDir = toSaveWeightsDir;
        plot_args.labels = labels;
        plot_args.seizureStart = seizureStart;
        plot_args.dataStart = seizureStart - timeRange(1)*frequency_sampling;
        plot_args.dataEnd = seizureStart + timeRange(2)*frequency_sampling;
        plot_args.FONTSIZE = 22;
        plot_args.YAXFontSize = 9;
        plot_args.LT = 1.5;
        plot_args.threshold = threshold;
        plot_args.frequency_sampling = frequency_sampling;
        
        close all
        analyzePerturbations(patient_id, seizure_id, plot_args, clinicalLabels);
    end
    
%     for j=1:length(perturbationTypes)
%         perturbationType = perturbationTypes(j);
% 
%         toSaveFinalDataDir = fullfile(strcat('./adj_mats_win', num2str(winSize), ...
%         '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)),...
%             strcat(perturbationType, '_finaldata'));
%         if ~exist(toSaveFinalDataDir, 'dir')
%             mkdir(toSaveFinalDataDir);
%         end
%         
%         toSaveFigDir = fullfile('./figures/', strcat(perturbationType, '_electrode_weights'), strcat(patient, num2str(winSize), ...
%             '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)));
%         if ~exist(toSaveFigDir, 'dir')
%             mkdir(toSaveFigDir);
%         end
%         stats_args = struct();
%         stats_args.perturbationType = perturbationType;
%         stats_args.w_space = w_space;
%         stats_args.radius = radius;
%         stats_args.adjDir = toSaveAdjDir;
%         stats_args.toSaveFinalDataDir = toSaveFinalDataDir;
%         stats_args.labels = labels;
%         stats_args.included_channels = included_channels;
%         stats_args.num_channels = size(eeg, 1);
%         
%         
%     end
end
