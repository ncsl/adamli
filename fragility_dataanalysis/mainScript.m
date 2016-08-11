% SCRIPT to run extraction of eeg and creating matrix from the channel data
% x = Ax
%% READ PATIENT ID FILE
patient_id_path = './pt1sz2.csv';

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
included_channels = dataArray{:, 8};

%%
patient_file_path = './data/pt1sz2/';
frequency = 1000; % sampling freq. at 1 kHz

% files to process
f = dir([patient_file_path '*eeg.csv']);
patient_file_names = cell(1, length(f));
for i=1:length(f)
    patient_file_names{i} = f(i).name;
end

patient_files = containers.Map(patient_file_names, file_sizes)
