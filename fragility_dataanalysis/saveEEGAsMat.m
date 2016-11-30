clear all;
close all;
clc;

INTERICTAL = 0;
% settings to run
patients = {,...
%     'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1' 'pt2sz3' 'pt2sz4', ...
%     'pt3sz2' 'pt3sz4', ...
    'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1' 'pt10sz2' 'pt10sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt14sz1' 'pt14sz2' 'pt14sz3' 'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2' 'pt17sz3',...
%     'JH101sz1' 'JH101sz2' 'JH102sz3' 'JH102sz4',...
% 	'JH102sz1' 'JH102sz2' 'JH102sz3' 'JH102sz4' 'JH102sz5' 'JH102sz6',...
% 	'JH103sz1' 'JH102sz2' 'JH102sz3',...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
% 	'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
% 	'JH106sz1' 'JH106sz2' 'JH106sz3' 'JH106sz4' 'JH106sz5' 'JH106sz6',...
% 	'JH107sz1' 'JH107sz2' 'JH107sz3' 'JH107sz4' 'JH107sz5' 'JH107sz6' 'JH107sz7' 'JH107sz8' 'JH107sz8',...
};
% add libraries of functions
addpath('./fragility_library/');

if INTERICTAL
    for p=1:length(patients)
        patient = patients{p};
        
        patient_id = patient(1:strfind(patient, 'aw')-1);
        seizure_id = strcat(patient(strfind(patient, 'aw'):end));
        if isempty(patient_id)
            patient_id = patient(1:strfind(patient, 'aslp')-1);
            seizure_id = patient(strfind(patient, 'aslp'):end);
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
        % window paramters
        winSize = 500; % 500 milliseconds
        stepSize = 500; 
        frequency_sampling = 1000; % in Hz

        patient = strcat(patient_id, seizure_id);
        disp(['Looking at patient: ',patient]);

        %% NIH, JHU PATIENTS
        %- set file path for the patient file 
        dataDir = './data/interictal_data/';
        patient_eeg_path = strcat(dataDir, patient);
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
        fclose(fid);

        %- Extract EEG and Perform Analysis
        filename = patient_file_names{1};
        num_values = patient_files(patient_file_names{1});
        % extract eeg 
        eeg = csv2eeg(patient_eeg_path, filename, num_values, num_channels);

        data = eeg;
        elec_labels = labels;
        seiz_end_mark = length(eeg);
        seiz_start_mark = length(eeg);

        save(fullfile(patient_eeg_path, patient), 'data', 'elec_labels', 'seiz_end_mark', 'seiz_start_mark');
    end
else
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
        [included_channels, ezone_labels, earlyspread_labels, latespread_labels] ...
                    = determineClinicalAnnotations(patient_id, seizure_id);

        % put clinical annotations into a struct
        clinicalLabels = struct();
        clinicalLabels.ezone_labels = ezone_labels;
        clinicalLabels.earlyspread_labels = earlyspread_labels;
        clinicalLabels.latespread_labels = latespread_labels;

        %% DEFINE COMPUTATION PARAMETERS AND DIRECTORIES TO SAVE DATA
        % window paramters
        winSize = 500; % 500 milliseconds
        stepSize = 500; 
        timeRange = [60 0];
        frequency_sampling = 1000; % in Hz

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

            if length(number_of_samples) > 1
                number_of_samples = number_of_samples(1);
            end
            if length(num_channels) > 1
                num_channels = num_channels(1);
            end
            
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
            fclose(fid);

            %- Extract EEG and Perform Analysis
            filename = patient_file_names{1};
            num_values = patient_files(patient_file_names{1});
            % extract eeg 
            eeg = csv2eeg(patient_eeg_path, filename, num_values, num_channels);

            data = eeg;
            elec_labels = labels;
            seiz_end_mark = 0;
            seiz_start_mark = length(eeg);

            save(fullfile(patient_eeg_path, patient), 'data', 'elec_labels', 'seiz_end_mark', 'seiz_start_mark');
        end
    end
end