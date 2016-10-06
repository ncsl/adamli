close all;
clear all;
clc;

%- directory variables and patients to run over
addpath('./fragility_library/'); % add this to functions.
patient_ids = {'pt1', 'pt2'};
seizure_ids = {'sz2', 'sz3'};
perturbationTypes = ['C', 'R'];

%- set variables for computing adjacency matrix
timeRange = [60, 0];
winSize = 500;
stepSize = 500;

patient_ids = {'007'}; %'005', '019'};
% patient_ids = {'019'};
% seizure_ids = {'seiz003', 'seiz002'};
patient_ids = {'005'};
seizure_ids = {'seiz001', 'seiz002'};
% patient_ids = {'090'};
% seizure_ids = {'seiz003', 'seiz002'};

patient_ids = {'pt7'};
seizure_ids = {'sz19'};

patients = {'pt7sz19'}; %'JH105sz1', 'pt7sz21', 'pt7sz22', 'pt1sz2', 'pt2sz3'};
COMPUTE_ADJ = 0;
COMPUTE_PERT = 1;
PLOT = 1;
%% Compute Adj Mats for Each Patient and 2 seizures
if COMPUTE_ADJ
%     for p=1:length(patients)
%         patient = patients{p};
%         split = strfind(patient, 'sz');
%         patient_id = patient(1:split-1);
%         seizure_id = patient(split:end);
        
    for p_id=1:length(patient_ids)
        for s_id=1:length(seizure_ids)
            patient_id = patient_ids{p_id};
            seizure_id = seizure_ids{s_id};
            if strcmp(patient_id, '007')
                included_channels = [];
                ezone_labels = {'O7', 'E8', 'E7', 'I5', 'E9', 'I6', 'E3', 'E2',...
                    'O4', 'O5', 'I8', 'I7', 'E10', 'E1', 'O6', 'I1', 'I9', 'E6',...
                    'I4', 'O3', 'O2', 'I10', 'E4', 'Y1', 'O1', 'I3', 'I2'}; %pt1
                earlyspread_labels = {};
                latespread_labels = {};
            elseif strcmp(patient_id, '005')
                included_channels = [];
                ezone_labels = {'U4', 'U3', 'U5', 'U6', 'U8', 'U7'}; 
                earlyspread_labels = {};
                 latespread_labels = {};
            elseif strcmp(patient_id, '019')
                included_channels = [];
                ezone_labels = {'I5', 'I6', 'B9', 'I9', 'T10', 'I10', 'B6', 'I4', ...
                    'T9', 'I7', 'B3', 'B5', 'B4', 'I8', 'T6', 'B10', 'T3', ...
                    'B1', 'T8', 'T7', 'B7', 'I3', 'B2', 'I2', 'T4', 'T2'}; 
                earlyspread_labels = {};
                 latespread_labels = {}; 
             elseif strcmp(patient_id, '045') % FAILURES
                included_channels = [];
                ezone_labels = {'X2', 'X1'}; %pt2
                earlyspread_labels = {};
                 latespread_labels = {}; 
              elseif strcmp(patient_id, '090') % FAILURES
                included_channels = [];
                ezone_labels = {'N2', 'N1', 'N3', 'N8', 'N9', 'N6', 'N7', 'N5'}; 
                earlyspread_labels = {};
                 latespread_labels = {}; 
            elseif strcmp(patient_id, 'pt7')
                included_channels = [1:17 19:35 37:38 41:62 67:109];
                ezone_labels = {};
                earlyspread_labels = {};
                latespread_labels = {};
            elseif strcmp(patient_id, 'pt1')
                included_channels = [1:36 42 43 46:69 72:95];
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
                earlyspread_labels = {};
                 latespread_labels = {};
            end
            computeAdjMats(patient_id, seizure_id, included_channels, ...
                timeRange, winSize, stepSize, ezone_labels, earlyspread_labels, latespread_labels);
%             computeEZTAdjMats(patient_id, seizure_id, included_channels, ...
%                 timeRange, winSize, stepSize, ezone_labels, earlyspread_labels, latespread_labels)
        end
    end
end

%% COMPUTE PERTURBATIONS
if COMPUTE_PERT
%     patients = {'pt1sz2',  'pt1sz3', 'pt2sz1', 'pt2sz3'};
    w_space = linspace(-1, 1, 101);
    radius = 1.1;
    for j=1:length(perturbationTypes)
        perturbationType = perturbationTypes(j);
        
%         for i=1:length(patients)
%             patient = patients{i};
%             split = strfind(patient, 'sz');
%             patient_id = patient(1:split-1);
%             seizure_id = patient(split:end);
        
        for i=1:length(patient_ids)
            for k=1:length(seizure_ids)
                patient_id = patient_ids{i};
                seizure_id = seizure_ids{k};
                if strcmp(patient_id, '007')
                    included_channels = [];
                    ezone_labels = {'O7', 'E8', 'E7', 'I5', 'E9', 'I6', 'E3', 'E2',...
                        'O4', 'O5', 'I8', 'I7', 'E10', 'E1', 'O6', 'I1', 'I9', 'E6',...
                        'I4', 'O3', 'O2', 'I10', 'E4', 'Y1', 'O1', 'I3', 'I2'}; %pt1
                    earlyspread_labels = {};
                    latespread_labels = {};
                elseif strcmp(patient_id, '005')
                    included_channels = [];
                    ezone_labels = {'U4', 'U3', 'U5', 'U6', 'U8', 'U7'}; 
                    earlyspread_labels = {};
                     latespread_labels = {};
                elseif strcmp(patient_id, '019')
                    included_channels = [];
                    ezone_labels = {'I5', 'I6', 'B9', 'I9', 'T10', 'I10', 'B6', 'I4', ...
                        'T9', 'I7', 'B3', 'B5', 'B4', 'I8', 'T6', 'B10', 'T3', ...
                        'B1', 'T8', 'T7', 'B7', 'I3', 'B2', 'I2', 'T4', 'T2'}; 
                    earlyspread_labels = {};
                     latespread_labels = {}; 
                 elseif strcmp(patient_id, '045') % FAILURES 2 EZONE LABELS?
                    included_channels = [];
                    ezone_labels = {'X2', 'X1'}; %pt2
                    earlyspread_labels = {};
                     latespread_labels = {}; 
                  elseif strcmp(patient_id, '090') % FAILURES
                    included_channels = [];
                    ezone_labels = {'N2', 'N1', 'N3', 'N8', 'N9', 'N6', 'N7', 'N5'}; 
                    earlyspread_labels = {};
                     latespread_labels = {}; 
                elseif strcmp(patient_id, 'pt7')
                    included_channels = [1:17 19:35 37:38 41:62 67:109];
                    ezone_labels = {};
                    earlyspread_labels = {};
                    latespread_labels = {};
                elseif strcmp(patient_id, 'pt1')
                    included_channels = [1:36 42 43 46:69 72:95];
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
                    earlyspread_labels = {};
                     latespread_labels = {};
                end
%                 patient_id = strcat('EZT', patient_id);
%                 computeEZTPerturbations(patient_id, seizure_id, winSize, stepSize, ...
%                     included_channels, ezone_labels, earlyspread_labels, latespread_labels, ...
%                     w_space, radius, perturbationType)
                computePerturbations(patient_id, seizure_id, winSize, stepSize, ...
                    included_channels, ezone_labels, earlyspread_labels, latespread_labels, ...
                    w_space, radius, perturbationType)
            end
        end
    end
end


% for EZT
if PLOT
    % %% PLOT PERTURBATIONS
    threshold = 0.8;
    for j=1:length(perturbationTypes)
        perturbationType = perturbationTypes(j);
        for i=1:length(patients)
            patient = patients{i};
            patient_id = patient(1:strfind(patient, 'sz')-1);
            seizure_id = patient(strfind(patient, 'sz'):end);
            analyzePerturbations(patient_id, seizure_id, perturbationType, threshold, winSize, stepSize)
        end
    end

%     threshold = 0.8;
%     for j=1:length(perturbationTypes)
%         perturbationType = perturbationTypes(j);
%         for i=1:length(patient_ids)
%             for k=1:length(seizure_ids)
%                 patient_id = strcat('EZT',patient_ids{i});
%                 seizure_id = strcat('_', seizure_ids{k});
%                 analyzeEZTPerturbations(patient_id, seizure_id, perturbationType, threshold, winSize, stepSize)
%             end
%         end
%     end
end