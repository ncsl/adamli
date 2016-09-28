close all;
clear all;
clc;

%- directory variables and patients to run over
addpath('./fragility_library/'); % add this to functions.
patient_ids = {'pt1', 'pt2'};
seizure_ids = {'sz2', 'sz3'};
perturbationTypes = ['C', 'R'];

%- set variables for computing adjacency matrix
timeRange = [-60, 20];
winSize = 500;
stepSize = 500;

%% COMPUTE ADJACENCY MATRICES
for p_id=1:length(patient_ids)              % loop through patients
    for s_id=1:length(seizure_ids)          % loop through seziures
        patient_id = patient_ids{p_id};
        seizure_id = seizure_ids{s_id};
        patient = strcat(patient_id, seizure_id);
        
        % 
        if strcmp(patient_id, 'pt1')
            included_channels = [1:36 42 43 46:69 72:95];
            ezone_labels = {'POLPST1', 'POLPST2', 'POLPST3', 'POLAD1', 'POLAD2'}; %pt1
            ezone_labels = {'POLATT1', 'POLATT2', 'POLAD1', 'POLAD2', 'POLAD3'}; %pt1
            earlyspread_labels = {'POLATT3', 'POLAST1', 'POLAST2'};
            latespread_labels = {'POLATT4', 'POLATT5', 'POLATT6', ...
                                'POLSLT2', 'POLSLT3', 'POLSLT4', ...
                                'POLMLT2', 'POLMLT3', 'POLMLT4', 'POLG8', 'POLG16'};
        elseif strcmp(patient_id, 'pt2')
        %     included_channels = [1:19 21:37 43 44 47:74 75 79]; %pt2
            included_channels = [1:14 16:19 21:25 27:37 43 44 47:74];
            ezone_labels = {'POLMST1', 'POLPST1', 'POLTT1'}; %pt2
            earlyspread_labels = {'POLTT2', 'POLAST2', 'POLMST2', 'POLPST2', 'POLALEX1', 'POLALEX5'};
             latespread_labels = {};
        elseif strcmp(patient_id, 'JH105')
            included_channels = [1:4 7:12 14:19 21:37 42 43 46:49 51:53 55:75 78:99]; % JH105
            ezone_labels = {'POLRPG4', 'POLRPG5', 'POLRPG6', 'POLRPG12', 'POLRPG13', 'POLG14',...
                'POLAPD1', 'POLAPD2', 'POLAPD3', 'POLAPD4', 'POLAPD5', 'POLAPD6', 'POLAPD7', 'POLAPD8', ...
                'POLPPD1', 'POLPPD2', 'POLPPD3', 'POLPPD4', 'POLPPD5', 'POLPPD6', 'POLPPD7', 'POLPPD8', ...
                'POLASI3', 'POLPSI5', 'POLPSI6', 'POLPDI2'}; % JH105
             latespread_labels = {};
        end
        
        computeparallelAdjMats(patient_id, seizure_id, included_channels, ...
            timeRange, winSize, stepSize, ezone_labels, earlyspread_labels, latespread_labels)
    end
end

%% COMPUTE PERTURBATIONS
patients = {'pt1sz2',  'pt1sz3', 'pt2sz1', 'pt2sz3'};
w_space = linspace(-1, 1, 101);
radius = 1.1;
% for j=1:length(perturbationTypes)
%     perturbationType = perturbationTypes(j);
%     for i=1:length(patients)
%         patient = patients{i};
%         patient_id = patient(1:strfind(patient, 'sz')-1);
%         seizure_id = patient(4:end);
%             if strcmp(patient_id, 'pt1')
%                 included_channels = [1:36 42 43 46:69 72:95];
%                 ezone_labels = {'POLPST1', 'POLPST2', 'POLPST3', 'POLAD1', 'POLAD2'}; %pt1
%                 ezone_labels = {'POLATT1', 'POLATT2', 'POLAD1', 'POLAD2', 'POLAD3'}; %pt1
%                 earlyspread_labels = {'POLATT3', 'POLAST1', 'POLAST2'};
%                 latespread_labels = {'POLATT4', 'POLATT5', 'POLATT6', ...
%                                     'POLSLT2', 'POLSLT3', 'POLSLT4', ...
%                                     'POLMLT2', 'POLMLT3', 'POLMLT4', 'POLG8', 'POLG16'};
%             elseif strcmp(patient_id, 'pt2')
%             %     included_channels = [1:19 21:37 43 44 47:74 75 79]; %pt2
%                 included_channels = [1:14 16:19 21:25 27:37 43 44 47:74];
%                 ezone_labels = {'POLMST1', 'POLPST1', 'POLTT1'}; %pt2
%                 earlyspread_labels = {'POLTT2', 'POLAST2', 'POLMST2', 'POLPST2', 'POLALEX1', 'POLALEX5'};
%                  latespread_labels = {};
%             elseif strcmp(patient_id, 'JH105')
%                 included_channels = [1:4 7:12 14:19 21:37 42 43 46:49 51:53 55:75 78:99]; % JH105
%                 ezone_labels = {'POLRPG4', 'POLRPG5', 'POLRPG6', 'POLRPG12', 'POLRPG13', 'POLG14',...
%                     'POLAPD1', 'POLAPD2', 'POLAPD3', 'POLAPD4', 'POLAPD5', 'POLAPD6', 'POLAPD7', 'POLAPD8', ...
%                     'POLPPD1', 'POLPPD2', 'POLPPD3', 'POLPPD4', 'POLPPD5', 'POLPPD6', 'POLPPD7', 'POLPPD8', ...
%                     'POLASI3', 'POLPSI5', 'POLPSI6', 'POLPDI2'}; % JH105
%                  latespread_labels = {};
%             end
% 
%         computePerturbations(patient_id, seizure_id, winSize, stepSize, ...
%             included_channels, ezone_labels, earlyspread_labels, latespread_labels, ...
%             w_space, radius, perturbationType)
%     end
% end
%% PLOT PERTURBATIONS
threshold = 0.8;
for j=1:length(perturbationTypes)
    perturbationType = perturbationTypes(j);
    for i=1:length(patients)
        patient = patients{i};
        patient_id = patient(1:strfind(patient, 'sz')-1);
        seizure_id = patient(4:end);
        analyzePerturbations(patient_id, seizure_id, perturbationType, threshold, winSize, stepSize)
    end
end
