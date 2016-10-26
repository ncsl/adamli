% used to resave mat files for the SEEG data, so that it is 

clear all;
close all;
clc;

% settings to run
patients = {'EZT005', 'EZT007', 'EZT045', 'EZT019', 'EZT090', 'EZT030', 'EZT037'};
    
%     'pt1sz2', 'pt1sz3', 'pt2sz1', 'pt2sz3', 'pt7sz19', 'pt7sz21', 'pt7sz22', 'JH105sz1', ...
%             'Pat2sz1p', 'Pat2sz2p', 'Pat2sz3p'};%, 'Pat16sz1p', 'Pat16sz2p', 'Pat16sz3p'};

% add libraries of functions
addpath('./fragility_library/');

for p=1:length(patients)
    patient = patients{p};
    
    dataDir = './data/Seiz_Data/';
    patDir = fullfile(dataDir, patient);
    matFiles = dir(fullfile(patDir, strcat(patient,'*.mat')));
    matFiles = {matFiles.name};
    
    % load in the data
    for i=1:length(matFiles)
        load(fullfile(patDir, matFiles{i}));
        save(fullfile(patDir, matFiles{i}), 'data', 'seiz_end_mark', 'seiz_end_time', ...
                    'seiz_start_mark', 'seiz_start_time', 'label', 'elec_labels');
    end
end
disp('done')