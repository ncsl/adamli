clear all;
close all;
clc;

addpath('../'); % access to main functions

%% 0: LOAD in the adj matrix files, and eeg file for initial condition
% adjustable parameters
pat_id = 'pt2'; sz_id = 'sz1';
patient = strcat(pat_id, sz_id);
frequency_sampling = 1000;
if strcmp(pat_id, 'pt1')
    included_channels = [1:36 42 43 46:69 72:95];
    
    if strcmp(sz_id, 'sz2')
        included_channels = [1:36 42 43 46:54 56:69 72:95];
    end
    ezone_labels = {'POLPST1', 'POLPST2', 'POLPST3', 'POLAD1', 'POLAD2'}; %pt1
    ezone_labels = {'POLATT1', 'POLATT2', 'POLAD1', 'POLAD2', 'POLAD3'}; %pt1
    earlyspread_labels = {'POLATT3', 'POLAST1', 'POLAST2'};
    latespread_labels = {'POLATT4', 'POLATT5', 'POLATT6', ...
                        'POLSLT2', 'POLSLT3', 'POLSLT4', ...
                        'POLMLT2', 'POLMLT3', 'POLMLT4', 'POLG8', 'POLG16'};
elseif strcmp(pat_id, 'pt2')
%     included_channels = [1:19 21:37 43 44 47:74 75 79]; %pt2
    included_channels = [1:14 16:19 21:25 27:37 43 44 47:74];
    ezone_labels = {'POLMST1', 'POLPST1', 'POLTT1'}; %pt2
    earlyspread_labels = {'POLTT2', 'POLAST2', 'POLMST2', 'POLPST2', 'POLALEX1', 'POLALEX5'};
elseif strcmp(pat_id, 'JH105')
    included_channels = [1:4 7:12 14:19 21:37 42 43 46:49 51:53 55:75 78:99]; % JH105
    ezone_labels = {'POLRPG4', 'POLRPG5', 'POLRPG6', 'POLRPG12', 'POLRPG13', 'POLG14',...
        'POLAPD1', 'POLAPD2', 'POLAPD3', 'POLAPD4', 'POLAPD5', 'POLAPD6', 'POLAPD7', 'POLAPD8', ...
        'POLPPD1', 'POLPPD2', 'POLPPD3', 'POLPPD4', 'POLPPD5', 'POLPPD6', 'POLPPD7', 'POLPPD8', ...
        'POLASI3', 'POLPSI5', 'POLPSI6', 'POLPDI2'}; % JH105
end

fid = fopen(strcat('../data/',patient, '/', patient, '_labels.csv')); % open up labels to get all the channels
labels = textscan(fid, '%s', 'Delimiter', ',');
labels = labels{:}; labels = labels(included_channels);
fclose(fid);
                
% define cell function to search for the EZ labels
cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));
ezone_indices = zeros(length(ezone_labels),1);
for i=1:length(ezone_labels)
    indice = cellfun(cellfind(ezone_labels{i}), labels, 'UniformOutput', 0);
    indice = [indice{:}];
    test = 1:length(labels);
    if ~isempty(test(indice))
        ezone_indices(i) = test(indice);
    end
end

% location of adj. matrix matfiles
patient = strcat(pat_id, sz_id)
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
num_channels = dataArray{:, 7};
number_of_samples = frequency_sampling * recording_duration;

patient_files = containers.Map(patient_file_names, number_of_samples)
disp(['Number of channels ', num2str(num_channels)]);
%% 1. Extract EEG and Perform Analysis
filename = patient_file_names{1};
num_values = patient_files(patient_file_names{1});

% 1A. extract eeg 
eeg = csv2eeg(patient_eeg_path, filename, num_values, num_channels);
num_channels=length(included_channels);
eeg = eeg(included_channels, :); % only get the included channels

%- load an example file to extract meta data
load(fullfile(dataDir, matFiles{4}));
timeStart = data.timeStart / frequency_sampling;     % time data starts (sec)
timeEnd = data.timeEnd / frequency_sampling;         % time data ends (sec)
seizureTime = data.seizureTime / frequency_sampling; % time seizure starts (sec)
winSize = data.winSize / frequency_sampling;                % window size (sec)
stepSize = data.stepSize / frequency_sampling;              % step size (sec)

% 2A. starting from time point zero as initial condition
initial_cond = eeg(:, 1);
x_current = initial_cond;
w = linspace(-1, 1, 101); 
radius = 1.1;
noise_var = 1/2 * abs(mean(eeg(1,1:500)));%var(eeg(1,1:data.timeStart)); % variance across all channels
% noise_var = 1;

%- initialize simulated electrode info
x_simulated = zeros(num_channels, (seizureTime-timeStart)/stepSize * 500 + 20/stepSize * 500);
x_simulated(:,1) = x_current;

preseizureTime = (seizureTime-timeStart)/stepSize * 500 ;
postseizureTime = 20/stepSize * 500; % currently set to 20 seconds
index_simulation = 2;

% add the first 500 milliseconds
load(fullfile(dataDir, matFiles{1}));
theta_adj = data.theta_adj;
timewrtSz = data.timewrtSz / frequency_sampling;
index = data.index; 
[V D W] = eig(theta_adj); % perform eigenvalue decomposition

error_adjmat = zeros(length(matFiles), 1);
n = size(theta_adj, 1); 

% move eigenvalues into |lambda| <= 1
if max(eig(theta_adj)) > 1
    indices_to_change = abs(D) > 1;
    epsilon = (abs(D(indices_to_change)) - 1) .^ 2;
    D(indices_to_change) = sqrt((1+epsilon).^2 - imag(D(indices_to_change)).^2) + imag(D(indices_to_change))*1i;
end

% store the min norm between
error_adjmat(1) = norm(theta_adj - V*D*W);
theta_adj = V*D*W;

for j=1:499
    x_next = theta_adj * x_current + normrnd(0, noise_var, num_channels, 1); % update next simulation
    
    % store generated vector
    x_current = x_next;
    x_simulated(:, index_simulation) = x_next;
    
    index_simulation = index_simulation+1; % increment index
end
disp('Index Simulation Should be 501');
index_simulation

%  clear eeg;
% 2B. Simulate preseizure data using the mat Files one by one and add noise
for i=2:length(matFiles)-21
    load(fullfile(dataDir, matFiles{i}));
    theta_adj = data.theta_adj;
    timewrtSz = data.timewrtSz / frequency_sampling;
    index = data.index; 
    
    noise_var = 1/2 * abs(mean(eeg(1,500*(i-1):500*i)));
    
    if max(eig(theta_adj)) < 1
        [V D W] = eig(theta_adj); % eigenvalue decomposition
        indices_to_change = abs(D) > 1;
        epsilon = (abs(D(indices_to_change)) - 1) .^ 2;
        D(indices_to_change) = sqrt((1+epsilon).^2 - imag(D(indices_to_change)).^2) + imag(D(indices_to_change))*1i;

        % store the min norm between
        error_adjmat(i) = norm(theta_adj - V*D*W);
        
        % update theta_adj to be the new one
        theta_adj = V*D*W;
    end
    
    for iSample=1:500 % the next 500 milliseonds of simulation
        x_next = theta_adj * x_current + normrnd(0, noise_var, num_channels, 1); % update next simulation
    
        % store generated vector
        x_current = x_next;
        x_simulated(:, index_simulation) = x_next;

        index_simulation = index_simulation+1; % increment index
    end
end

% 2C. Simulate postseizure
load(fullfile(dataDir, matFiles{end}));
theta_adj = data.theta_adj;
timewrtSz = data.timewrtSz / frequency_sampling;
index = data.index;

% move adjacency matrix into unstable 
delta = computeDelta(w, radius, theta_adj);
theta_adj = theta_adj + delta;
for i=1:postseizureTime
    % use adj. mat
    x_next = theta_adj * x_current;

    % add noise
    x_next = x_next + normrnd(0, noise_var, num_channels, 1);

    % store the generated vector
    x_current = x_next;
    x_simulated(:,index_simulation) = x_next;        

    index_simulation = index_simulation + 1; % increment index
end
EEG = x_simulated;
save('EEG', 'EEG');

% 3A. Plot Simulated EEG Data and real EEG
% initialize variables for plotting
max_prev_eeg = 0;
figure;
xTickLabels = (timeStart - seizureTime):2:(timeStart - seizureTime + 10);
xTicks = 1: 2000 : 10*frequency_sampling;
centers = [];
ez_electrodes = {};

%%- Plot every electrode in the EZ
for i=1:length(ezone_indices)
    simulated_eeg = x_simulated(ezone_indices(i), 1:10000);% + max_prev_eeg;
    real_eeg = eeg(ezone_indices(i), 1:10000);% + max_prev_eeg;
    
    if noise_var ~= 1
        simulated_eeg = simulated_eeg ./ max(simulated_eeg) + max_prev_eeg;
        real_eeg = real_eeg ./ max(real_eeg) + max_prev_eeg;
        max_prev_eeg = max_prev_eeg + 4;
    else
        simulated_eeg = simulated_eeg  + max_prev_eeg;
        real_eeg = real_eeg + max_prev_eeg;
        max_prev_eeg = max(max(simulated_eeg), max(real_eeg)) + 3;
    end
    centers = [centers; mean(real_eeg)];
    ez_electrodes{end+1} = ezone_labels{i};
    
    M1 = 'simulated EEG';
    M2 = 'real EEG';
    a1 = plot(simulated_eeg, 'k-');   hold on;
    a2 = plot(real_eeg, 'r-');
    ax = gca;
    set(ax, 'XTick', xTicks, 'XTickLabel', xTickLabels);
end
set(ax, 'YTick', centers, 'YTickLabel', ez_electrodes);
title({'Example Traces of Real vs. Simulated EEG', 'Using Adjacency Matrices'});
xlabel('Time WRT Seizure Onset');
legend([a1;a2], M1, M2);

