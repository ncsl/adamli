% SCRIPT to run extraction of eeg and creating matrix from the channel data
% x = Ax
%% READ PATIENT ID FILE
% change these paramters depending on patient
patient_id_path = './pt1sz2.csv';
included_channels = [1:36 42 43 46:54 56:69 72:95];
patient_file_path = './data/pt1sz2/';
frequency_sampling = 1000; % sampling freq. at 1 kHz
BP_FILTER_RAW = 1;

% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%{MM/dd/yyyy}D%{HH:mm:ss}D%{HH:mm:ss}D%{HH:mm:ss}D%f%f%s%[^\n\r]';

% Open the text file.
fileID = fopen(patient_id_path,'r');

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

%% READ EEG FILE
% files to process
f = dir([patient_file_path '*eeg.csv']);
patient_file_names = cell(1, length(f));
for i=1:length(f)
    patient_file_names{i} = f(i).name;
end

patient_files = containers.Map(patient_file_names, number_of_samples)

disp(['Number of channels ', num2str(num_channels)]);

%% 1. Extract EEG and Perform Analysis
filename = patient_file_names{1};
num_values = patient_files(patient_file_names{1});

% 1A. extract eeg and apply band notch filter between 59.5 - 60.5
eeg = csv2eeg(patient_file_path, filename, num_values, num_channels);
eeg = buttfilt(eeg,[59.5 60.5], frequency_sampling,'stop',1); %-filter is overkill: order 1 --> 25 dB drop (removing 5-15dB peak)

% 1B. pre-process channel data by normalization at each time point
eeg = eeg - repmat(mean(eeg, 1), size(eeg, 1), 1);
eeg = eeg ./ repmat(std(eeg, [], 1), size(eeg, 1), 1);

% 1C. only get columns of interest and time points of interest
timeSStart = seconds(onset_time - recording_start) * frequency_sampling;
timeWindow = [timeSStart - 20*frequency_sampling: timeSStart - 10*frequency_sampling];
winSize = 10*frequency_sampling;

eeg = eeg(included_channels, timeWindow);

size(eeg)
bands = [0 4; 4 8; 8 13; 13 30; 30 90];
gamma = bands(5, :);

