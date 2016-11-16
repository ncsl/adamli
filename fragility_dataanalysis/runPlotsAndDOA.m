% clear all;
% close all;
% clc;

adjMat = './adj_mats_win';
figDir = './figures/';
% runPlotsAndDOA(1000, 500, 500, 1.1);
% runPlotsAndDOA(500, 500, 500, 1.1);
% runPlotsAndDOA(250, 500, 500, 1.1);
% runPlotsAndDOA(1000, 250, 250, 1.1);
% runPlotsAndDOA(1000, 125, 125, 1.1);
% 
% runPlotsAndDOA(1000, 500, 500, 1.2);
% runPlotsAndDOA(1000, 500, 500, 1.5);
% runPlotsAndDOA(1000, 500, 500, 2.0);


% function runPlotsAndDOA(frequency_sampling, winSize, stepSize, radius)

% settings to run
patients = {...
    
%     'JH102sz1', 'JH102sz2', 'JH102sz3', 'JH102sz4', 'JH102sz5', 'JH102sz6',...
% %     'pt1sz4', 'pt2sz4', 
%         'pt3sz2', 'pt3sz4', ...
%     'pt8sz1', 'pt8sz2', 'pt8sz3', ...
%     'pt10sz1', 'pt10sz2', 'pt10sz3', ...
    %     'pt14sz1', 'pt14sz2', 'pt14sz3', 'pt15sz1', 'pt15sz2', 'pt15sz3', 'pt15sz4',...
%     'pt11sz1', 'pt11sz2', 'pt11sz3', 'pt11sz4', 
%     'pt17sz1', 
%     'pt17sz2',
%     'pt15sz2', 'pt15sz3'...
%     'pt16sz1', 
    'pt16sz2',... 
%     'pt16sz3',...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3'...
%     'JH104sz1', 'JH104sz2', 'JH104sz3'...
%     'EZT030seiz001', 'EZT030seiz002', 'EZT037seiz001', 'EZT037seiz002',...
%     'EZT045seiz001', 'EZT045seiz002',...
% 	'EZT070seiz001', 'EZT070seiz002', 'EZT005seiz001', 'EZT005seiz002', 'EZT007seiz001', 'EZT007seiz002', ...
%     'EZT019seiz001', 'EZT019seiz002', 'EZT090seiz002', 'EZT090seiz003' ...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
%     'pt1sz2', 'pt1sz3', 'pt2sz1', 'pt2sz3', 'JH105sz1', ...
%     'pt7sz19', 'pt7sz21', 'pt7sz22',  ...
    };
% patients = { 'EZT108_seiz002', 'EZT120_seiz001', 'EZT120_seiz002'}; %,
% patients = {'Pat2sz1p', 'Pat2sz2p', 'Pat2sz3p'};%, 'Pat16sz1p', 'Pat16sz2p', 'Pat16sz3p'};
perturbationTypes = ['R', 'C'];
w_space = linspace(-1, 1, 101);
threshold = 0.8;          % threshold on fragility metric
% if nargin==0
radius = 1.5;             % spectral radius
winSize = 500;            % 500 milliseconds
stepSize = 500; 
frequency_sampling = 1000; % in Hz
% end
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

        fclose(fid);
    else
        %% EZT/SEEG PATIENTS
        patient_eeg_path = strcat('./data/Seiz_Data/', patient_id);

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
        num_channels = size(data.data, 1);
    end

    try
    if ~isempty(included_channels)
        labels = labels(included_channels);
    end
    catch e
        disp(e)
    end
    
%% 03: PLOT PERTURBATION RESULTS
    for j=1:length(perturbationTypes)
        perturbationType = perturbationTypes(j);
       
        toSaveFinalDataDir = fullfile(strcat(adjMat, num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), strcat(perturbationType, '_finaldata', ...
            '_radius', num2str(radius)));
        
        toSaveFigDir = fullfile(figDir, perturbationType, strcat(patient, '_win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)));
        if ~exist(toSaveFigDir, 'dir')
            mkdir(toSaveFigDir);
        end
        
        toSaveWeightsDir = fullfile(figDir, strcat(perturbationType, '_electrode_weights'), strcat(patient, num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)));
        if ~exist(toSaveWeightsDir, 'dir')
            mkdir(toSaveWeightsDir);
        end

        plot_args = struct();
        plot_args.perturbationType = perturbationType;
        plot_args.radius = radius;
        plot_args.winSize = winSize;
        plot_args.stepSize = stepSize;
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
%         try
            analyzePerturbations(patient_id, seizure_id, plot_args, clinicalLabels);
%         catch e
%             disp(e)
%             patient
%             perturbationType
%         end
    end

    %% 04: Compute Jaccard Index
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
%         
%     end
end
% end