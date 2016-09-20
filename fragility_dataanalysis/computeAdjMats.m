%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: computeAdjMats
% DESCRIPTION: This function takes a time range of EEG data, step size, 
% window size and computes an adjacency matrix, A for each window using 
% a vector autoregression model.
%
% INPUT:
% - patient_id = The id of the patient (e.g. pt1, JH105, UMMC001)
% - seizure_id = the id of the seizure (e.g. sz1, sz3)
% - included_channels = the list of included channels for this patient
% which can be copy/pasted from EZTrack's patient csv file
% - timeRange = [preseizuretime, postseizuretime]
% - winSize = the window size of each data segment to be used for an
% adjacency matrix. It is in milliseconds
% - stepSize = the step size over this window of analysis (in milliseconds)
%
% OUTPUT:
% - None, but it saves a mat file for the patient/seizure over all windows
% in the time range
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function computeAdjMats(patient_id, seizure_id, included_channels, ...
    timeRange, winSize, stepSize, ezone_labels, earlyspread_labels, latespread_labels)

if nargin == 0
    patient_id = 'pt1';
    seizure_id = 'sz2';
    included_channels = [1:36 42 43 46:69 72:95];
end
if nargin < 4 % set the timeRange, winSize, stepSize if they are not set
    timeRange = [60, 10];
    winSize = 500;
    stepSize = 500;
end

%% 0: READ PATIENT ID FILE
patient = strcat(patient_id, seizure_id); % patient
%- set processing data vars 
frequency_sampling = 1000; % sampling freq. at 1 kHz
BP_FILTER_RAW = 1;

% create the adjacency file directory to store the computed adj. mats
adjDir = fullfile(strcat('./adj_mats_win', num2str(winSize), ...
    '_step', num2str(stepSize)), patient);
if ~exist(adjDir, 'dir')
    mkdir(adjDir);
end

%- set file path for the patient file 
dataDir = './data/';
patient_eeg_path = strcat('./data/', patient);
patient_file_path = fullfile(dataDir, patient, strcat(patient, '.csv'));

%- set the meta data using the patient input file
[patient_id, date1, recording_start, ...
 onset_time, offset_time, ...
 recording_duration, num_channels] = readLabels(patient_file_path);
number_of_samples = frequency_sampling * recording_duration;

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

%% 1. Extract EEG and Perform Analysis
filename = patient_file_names{1};
num_values = patient_files(patient_file_names{1});

% 1A. extract eeg 
eeg = csv2eeg(patient_eeg_path, filename, num_values, num_channels);
% 1B. apply band notch filter
eeg = buttfilt(eeg,[59.5 60.5], frequency_sampling,'stop',1);
% 1C. only get columns of interest and time points of interest
seizureStart = milliseconds(onset_time - recording_start); % time seizure starts
file_length = length(eeg); 
num_channels = length(included_channels);

% window parameters - overlap, #samples, stepsize, window pointer
preseizureTime = timeRange(1); % e.g. 60 seconds 
postseizureTime = timeRange(2); % e.g. 10 seconds
dataWindow = seizureStart - preseizureTime*frequency_sampling;  % current data window                      % where to grab data (milliseconds)

% begin computation and time it
tic;
index = 1;
limit = seizureStart + postseizureTime*frequency_sampling; % go to seizure start, or + 10 seconds

disp(['The range locked to seizure to look over is', num2str(-timeRange(1)), ...
    ' until ', num2str(timeRange(2))]); 
disp(['Total number of channels ', num2str(num_channels)]);
disp(['Length of to be included channels ', num2str(length(included_channels))]);
disp(['Seizure starts at ', num2str(limit), ' milliseconds']);
 
while (dataWindow <= limit)
    % step 1: extract the data and apply the notch filter. Note that column
    %         #i in the extracted matrix is filled by data samples from the
    %         recording channel #i.
    tmpdata = eeg(included_channels, dataWindow + 1:dataWindow + winSize);
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
    
    %% save the theta_adj made
    fileName = strcat(patient, '_', num2str(index), '.mat');
    
    %- save the data into a struct into a mat file
    data.theta_adj = theta_adj;
    data.seizureTime = seizureStart;
    data.winSize = winSize;
    data.stepSize = stepSize;
    data.timewrtSz = dataWindow - seizureStart;
    data.timeStart = seizureStart - preseizureTime*frequency_sampling;
    data.timeEnd = seizureStart + postseizureTime*frequency_sampling;
    data.index = index;
    data.included_channels = included_channels;
    save(fullfile(adjDir, fileName), 'data');
    
    % step 3: update the pointer and window
    dataWindow = sample_to_access + stepSize;
    index = index + 1;
end
end