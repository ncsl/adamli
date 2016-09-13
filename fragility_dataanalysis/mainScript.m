% SCRIPT to run extraction of eeg and creating matrix from the channel data
% x = Ax
%% 0: READ PATIENT ID FILE
% change these paramters depending on patient
pat_id = 'pt2'; sz_id = 'sz3';
%pat_id = 'JH105'; sz_id = 'sz1';

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
patient = strcat(pat_id, sz_id)
patfile = strcat(patient, '.csv');
patient_eeg_path = strcat('./data/', patient);

%%- set file path for the patient file 
dataDir = './data/';
patient_file_path = fullfile(dataDir, patient, patfile);
frequency_sampling = 1000; % sampling freq. at 1 kHz
BP_FILTER_RAW = 1;

bands = [0 4; 4 8; 8 13; 13 30; 30 90];
gamma = bands(5, :);

% For more information, see the TEXTSCAN documentation.
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
% included_channels = dataArray{:, 8};
% included_channels = included_channels{:};

number_of_samples = frequency_sampling * recording_duration;

% filter parameters
%- apply a bandpass filter raw data? (i.e. pre-filter the wave?)
if BP_FILTER_RAW==1,
    preFiltFreq      = [1 499];   %[1 499] [2 250]; first bandpass filter data from 1-499 Hz
    preFiltType      = 'bandpass';
    preFiltOrder     = 2;
    preFiltStr       = sprintf('%s filter raw; %.1f - %.1f Hz',preFiltType,preFiltFreq);
    preFiltStrShort  = '_BPfilt';
else
    preFiltFreq      = []; %keep this empty to avoid any filtering of the raw data
    preFiltType      = 'stop';
    preFiltOrder     = 1;
    preFiltStr       = 'Unfiltered raw traces';
    preFiltStrShort  = '_noFilt';
end

% READ EEG FILE
% files to process
f = dir([patient_eeg_path '/*eeg.csv']);
patient_file_names = cell(1, length(f));
for i=1:length(f)
    patient_file_names{i} = f(i).name;
end

patient_files = containers.Map(patient_file_names, number_of_samples)

disp(['Number of channels ', num2str(num_channels)]);

%% 1. Extract EEG and Perform Analysis
filename = patient_file_names{1};
num_values = patient_files(patient_file_names{1});

% 1A. extract eeg 
eeg = csv2eeg(patient_eeg_path, filename, num_values, num_channels);

% 1B. apply band notch filter
eeg = buttfilt(eeg,[59.5 60.5], frequency_sampling,'stop',1); %-filter is overkill: order 1 --> 25 dB drop (removing 5-15dB peak)

% 1C. pre-process channel data by normalization at each time point
% eeg = eeg - repmat(mean(eeg, 1), size(eeg, 1), 1);
% eeg = eeg ./ repmat(std(eeg, [], 1), size(eeg, 1), 1);

% 1C. only get columns of interest and time points of interest
timeSStart = milliseconds(onset_time - recording_start); % time seizure starts
file_length = length(eeg);
num_channels = length(included_channels);

% window parameters - overlap, #samples, stepsize, window pointer
sliding_window_overlap = 0.5;                                            % window overlap (seconds)
preseizureTime = 60;
postseizureTime = 10;
nsamples = round(sliding_window_overlap * frequency_sampling);           % number of samples to analyze (milliseconds)
stepwin = 0.5*frequency_sampling;                                          % step size of sliding horizon (milliseconds)
lastwindow = timeSStart - preseizureTime*frequency_sampling;                         % where to grab data (milliseconds)
sample_to_access = lastwindow;                  

tic;
index = 1;
limit = fix((file_length - (nsamples - stepwin * frequency_sampling)) / (stepwin * frequency_sampling));
limit = timeSStart + postseizureTime*frequency_sampling; % go to seizure start, or + 10 seconds
disp(['Seizure starts at ', num2str(limit), ' milliseconds']);
 
while (sample_to_access <= limit)
    % step 1: extract the data and apply the notch filter. Note that column
    %         #i in the extracted matrix is filled by data samples from the
    %         recording channel #i.
    tmpdata = eeg(included_channels, lastwindow + 1:lastwindow + nsamples);

    [nc, t] = size(tmpdata)
    
    % step 2: compute some functional connectivity 
    % linear model: Ax = b; A\b -> x
    b = tmpdata(:); % define b as vectorized by stacking columns on top of another
    b = b(num_channels+1:end); % only get the time points after the first one
    
    tmpdata = tmpdata';
    tic;
    % build up A matrix with a loop modifying #time_samples points and #chans at a time
    A = zeros(length(b), num_channels^2);               % initialize A for speed
    n = 1:num_channels:size(A,1);                       % set the indices through rows
    A(n, 1:num_channels) = tmpdata(1:end-1,:);          % set the first loop
    
    for i=2 : num_channels % loop through columns #channels per loop
        rowInds = n+(i-1);
        colInds = (i-1)*num_channels+1:i*num_channels;
        A(rowInds, colInds) = tmpdata(1:end-1,:);
    end
    toc;
    
    % create the reshaped adjacency matrix
    tic;
    theta = A\b;                                                % solve for x, connectivity
    theta_adj = reshape(theta, num_channels, num_channels)';    % reshape fills in columns first, so must transpose
    imagesc(theta_adj)
    toc;
    
%     R = corrcoef(tmpdata');
%     outputfile = sprintf('theta_mat_%s.mat', num2str(sample_to_access));
%     save(outputfile, 'theta');

%     %%- Do some check on the eigenspectrum of the connectivity matrix
    E = eig(theta_adj);
    
    % step 3: Plotting Eigenspectrum
    titleStr = {['Eigenspectrum of A\b=x for ', patient], ...
        ['time point (seconds) before seizure: ', num2str((timeSStart - lastwindow)/frequency_sampling)]};
    plot(real(E), imag(E), 'o')
    title(titleStr);
    xlabel('Real'); ylabel('Imaginary');
    
    %% save the theta_adj made
    fileName = strcat(patient, '_', num2str(index), '.mat');
    adjDir = fullfile('./adj_mats_500_05/', patient);
    if ~exist(adjDir)
        mkdir(adjDir);
    end
    
    data.theta_adj = theta_adj;
    data.seizureTime = timeSStart;
    data.winSize = nsamples;
    data.stepSize = stepwin;
    data.timewrtSz = lastwindow - timeSStart;
    data.timeStart = timeSStart - preseizureTime*frequency_sampling;
    data.timeEnd = timeSStart + postseizureTime*frequency_sampling;
    data.index = index;
    
    save(fullfile(adjDir, fileName), 'data');
    
    % step 3: update the pointer and window
    sample_to_access = sample_to_access + stepwin;
    lastwindow = sample_to_access;
    index = index + 1;
end
    