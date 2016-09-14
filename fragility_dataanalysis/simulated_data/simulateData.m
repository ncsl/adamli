clear all;
close all;
clc;

%% 0: LOAD in the adj matrix files, and eeg file for initial condition
% adjustable parameters
pat_id = 'pt2'; sz_id = 'sz1';
frequency_sampling = 1000;
if strcmp(pat_id, 'pt1')
    included_channels = [1:36 42 43 46:69 72:95];
    ezone_labels = {'POLPST1', 'POLPST2', 'POLPST3', 'POLAD1', 'POLAD2'}; %pt1
    ezone_labels = {'POLATT1', 'POLATT2', 'POLAD1', 'POLAD2', 'POLAD3'}; %pt1
    earlyspread_labels = {'POLATT3', 'POLAST1', 'POLAST2'};
    latespread_labels = {'POLATT4', 'POLATT5', 'POLATT6', ...
                        'POLSLT2', 'POLSLT3', 'POLSLT4', ...
                        'POLMLT2', 'POLMLT3', 'POLMLT4', 'POLG8', 'POLG16'};
elseif strcmp(pat_id, 'pt2')
    included_channels = [1:19 21:37 43 44 47:74 75 79]; %pt2
    ezone_labels = {'POLMST1', 'POLPST1', 'POLTT1'}; %pt2
    earlyspread_labels = {'POLTT2', 'POLAST2', 'POLMST2', 'POLPST2', 'POLALEX1', 'POLALEX5'};
elseif strcmp(pat_id, 'JH105')
    included_channels = [1:4 7:12 14:19 21:37 42 43 46:49 51:53 55:75 78:99]; % JH105
    ezone_labels = {'POLRPG4', 'POLRPG5', 'POLRPG6', 'POLRPG12', 'POLRPG13', 'POLG14',...
        'POLAPD1', 'POLAPD2', 'POLAPD3', 'POLAPD4', 'POLAPD5', 'POLAPD6', 'POLAPD7', 'POLAPD8', ...
        'POLPPD1', 'POLPPD2', 'POLPPD3', 'POLPPD4', 'POLPPD5', 'POLPPD6', 'POLPPD7', 'POLPPD8', ...
        'POLASI3', 'POLPSI5', 'POLPSI6', 'POLPDI2'}; % JH105
end

% location of adj. matrix matfiles
patient = strcat(pat_id, sz_id)
addpath('/Users/adam2392/Documents/adamli/fragility_dataanalysis'); % access to main functions
dataDir = fullfile('../adj_mats_500_05', patient);
matFiles = dir(fullfile(dataDir, '*.mat'));
matFiles = {matFiles.name};                     % cell array of all mat file names in order
matFiles = natsortfiles(matFiles);

% load in eeg file for initial condition
% files to process
patient_eeg_path = fullfile('../data', patient);
f = dir([patient_eeg_path '/*eeg.csv']);
patient_file_path = fullfile(patient_eeg_path, strcat(patient, '.csv'));

patient_file_names = cell(1, length(f));
for i=1:length(f)
    patient_file_names{i} = f(i).name;
end

formatSpec = '%s%{MM/dd/yyyy}D%{HH:mm:ss}D%{HH:mm:ss}D%{HH:mm:ss}D%f%f%s%[^\n\r]';
% Open the text file.
fileID = fopen(patient_file_path,'r');
% Read columns of data according to format string.
dataArray = textscan(fileID, formatSpec, 'Delimiter',',', 'HeaderLines' ,1 , 'ReturnOnError', false);
% Close the text file.
fclose(fileID);

% Allocate imported array to column variable names
patient_id = dataArray{:, 1};
date1 = dataArray{:, 2};
recording_start = dataArray{:, 3};
onset_time = dataArray{:, 4};
offset_time = dataArray{:, 5};
recording_duration = dataArray{:, 6};
num_channels = length(included_channels);
number_of_samples = frequency_sampling * recording_duration;

patient_files = containers.Map(patient_file_names, number_of_samples)
disp(['Number of channels ', num2str(num_channels)]);
%% 1. Extract EEG and Perform Analysis
filename = patient_file_names{1};
num_values = patient_files(patient_file_names{1});

% 1A. extract eeg 
eeg = csv2eeg(patient_eeg_path, filename, num_values, num_channels);
eeg = eeg(included_channels, :); % only get the included channels

% 2A. starting from time point zero as initial condition
initial_cond = eeg(:, 1);
x_current = initial_cond;
w = linspace(-1, 1, 101); 
radius = 1.1;
noise_var = var(initial_cond); % variance across all channels

load(fullfile(dataDir, matFiles{4}));
timeStart = data.timeStart / frequency_sampling;     % time data starts (sec)
timeEnd = data.timeEnd / frequency_sampling;         % time data ends (sec)
seizureTime = data.seizureTime / frequency_sampling; % time seizure starts (sec)
winSize = data.winSize / frequency_sampling;                % window size (sec)
stepSize = data.stepSize / frequency_sampling;              % step size (sec)

x_simulated = zeros(num_channels, (timeEnd-timeStart)/stepSize);
x_simulated(:,1) = x_current;

% 2B. Simulate data using the mat Files one by one and add noise
for i=2:length(matFiles)
    % load in the adjacency matrix
    load(fullfile(dataDir, matFiles{i}));
    theta_adj = data.theta_adj;
    timewrtSz = data.timewrtSz / frequency_sampling;
    index = data.index;

    % simulate the next round of data x_(t+1) + noise
    if timewrtSz < seizureTime % still pre-seizure
        % use adj. mat
        x_next = theta_adj * x_current;
    else % seizure zone
        % use adj. mat + Delta
        delta = computeDelta(w, radius, theta_adj);
        x_next = (theta_adj + Delta) * x_current;
    end
    
    % add noise
    x_next = x_next + normrnd(0, noise_var, num_channels, 1);
    
    % store the generated vector
    x_current = x_next;
    x_simulated(:,i) = x_next;
end

% 3A. Plot Simulated EEG Data

