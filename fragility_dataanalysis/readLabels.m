function [patient_id, date1, recording_start, ...
    onset_time, offset_time, recording_duration, num_channels] = readLabels(patient_file_path)

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
end