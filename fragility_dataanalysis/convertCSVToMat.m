%
% convertCSVToMat
% By: Adam Li
%
% Description: Used to help convert csv files from Persyst of the
% interictal spike data files to .mat files.
% 
% Date Modified: 6/2/17 
%
clear all;
close all;
clc;

INTERICTAL = 0; % set to 1 when running 'aw'/'aslp' patients
% settings to run
patients = {,...
    'm10', 'm19', 'm23', 'm26', 'm30', 'm32', 'm36', 'm40',...
};
% add libraries of functions
addpath('./fragility_library/');

dataDir = '/media/ali39/NIL_PASS/interictal spike raw edf data/';

%%- Begin Loop Through Different Patients Here
for p=1:length(patients)
    patient = patients{p}
    
    % READ EEG FILE
    patient_data_path = fullfile(dataDir, strcat(patient, '_eeg.csv'));
    
    % open up labels to get all the channels
    fid = fopen(patient_data_path); 
    tline = fgetl(fid);
    labels = strsplit(tline);
    fclose(fid);
    
    % extract eeg 
    eeg = dlmread(patient_data_path, ',', 1, 0);

    data = eeg;
    elec_labels = upper(strtrim(labels));


    varinfo = whos('data');
    saveopt='';
    if varinfo.bytes >= 2^31
        saveopt='-v7.3';
    end
    save(fullfile(dataDir, strcat(patient, '_eeg', '.mat')), 'data', 'elec_labels', saveopt);
end
