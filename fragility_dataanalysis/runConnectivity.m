clear all;
close all;
clc;

% settings to run
patients = {...
    'JH106sz3', ...
%     'pt1aslp1', 'pt1aslp2',...
%     'pt10sz1', 'pt10sz2', 'pt10sz3',...
%      'pt15sz2', 'pt15sz3', 'pt15sz1',...
%     'pt16sz1', 'pt16sz2', 'pt16sz3',...
%     'pt17sz1', 
%     'pt17sz2',...
%     'pt11sz1', 'pt11sz2', 'pt11sz3','pt11sz4',...
%     'pt3sz2' 'pt3sz4' 'pt8sz1' 'pt8sz2' 'pt8sz3'...
% 		'pt10sz1' 'pt10sz2' 'pt10sz3'  'pt11sz2' 'pt11sz3' 'pt11sz4'...
%     'JH102sz1',
%     'JH102sz2', 'JH102sz3', 'JH102sz4', 'JH102sz5', 'JH102sz6',...
    %'EZT030seiz001' ...
%     'EZT030seiz002' 'EZT037seiz001' 'EZT037seiz002',...
% 	'EZT070seiz001' 'EZT070seiz002', ...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
%     'pt1sz2', 'pt1sz3', 'pt2sz1', 'pt2sz3', 'JH105sz1', 'pt7sz19', 'pt7sz21', 'pt7sz22',  ...
%     'EZT005_seiz001', 'EZT005_seiz002', 'EZT007_seiz001', 'EZT007_seiz002', ...
%     'EZT019_seiz001', 'EZT019_seiz002', 'EZT090_seiz002', 'EZT090_seiz003', ...
    };
% patients = { 'EZT108_seiz002', 'EZT120_seiz001', 'EZT120_seiz002'}; %,
% patients = {'Pat2sz1p', 'Pat2sz2p', 'Pat2sz3p'};%, 'Pat16sz1p', 'Pat16sz2p', 'Pat16sz3p'};
perturbationTypes = ['R', 'C'];
w_space = linspace(-1, 1, 101);
radius = 1.5;             % spectral radius
threshold = 0.8;          % threshold on fragility metric
winSize = 500;            % 500 milliseconds
stepSize = 500; 
frequency_sampling = 1000; % in Hz
timeRange = [60 0];
IS_SERVER = 0;
IS_INTERICTAL = 1;

% add libraries of functions
addpath('./fragility_library/');
addpath(genpath('/Users/adam2392/Dropbox/eeg_toolbox'));
addpath(genpath('/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/eeg_toolbox/'));

%%- Begin Loop Through Different Patients Here
for p=1:length(patients)
    patient = patients{p};
   
    setupScripts;

    % define args for computing the functional connectivity
    adj_args = struct();
    adj_args.BP_FILTER_RAW = 1; % apply notch filter or not?
    adj_args.frequency_sampling = frequency_sampling; % frequency that this eeg data was sampled at
    adj_args.winSize = winSize;
    adj_args.stepSize = stepSize;
    adj_args.timeRange = timeRange;
    adj_args.toSaveAdjDir = toSaveAdjDir;
    adj_args.included_channels = included_channels;
    adj_args.seizureStart = seizureStart;
    adj_args.seizureEnd = seizureEnd;
    adj_args.labels = labels;
    adj_args.l2regularization = l2regularization;
    
    % compute connectivity
%     computeConnectivity(patient_id, seizure_id, eeg, clinicalLabels, adj_args);
    
    %% 02: RUN PERTURBATION ANALYSIS
    for j=1:length(perturbationTypes)
        perturbationType = perturbationTypes(j);
        
        toSaveFinalDataDir = fullfile(strcat('./adj_mats_win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), strcat(perturbationType, '_finaldata', ...
            '_radius', num2str(radius)));
        if ~exist(toSaveFinalDataDir, 'dir')
            mkdir(toSaveFinalDataDir);
        end
        
        perturb_args = struct();
        perturb_args.perturbationType = perturbationType;
        perturb_args.w_space = w_space;
        perturb_args.radius = radius;
        perturb_args.frequency_sampling = frequency_sampling;
        perturb_args.adjDir = toSaveAdjDir;
        perturb_args.toSaveFinalDataDir = toSaveFinalDataDir;
        perturb_args.labels = labels;
        perturb_args.included_channels = included_channels;
        perturb_args.num_channels = size(eeg, 1);
        
        computePerturbations(patient_id, seizure_id, perturb_args);
    end
end
