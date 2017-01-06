clear all;
close all;
clc;

% settings to run
patients = {,...
%      'pt1sz2', 'pt1sz3',...
%     'JH101sz2', 'JH103sz1',...
%     'JH105sz5','JH106sz1', 'JH106sz2', 'JH106sz3', 'JH106sz4', 'JH106sz5', 'JH106sz6',...
%     'JH107sz6', 'JH107sz7', 'JH107sz8',
%     'pt1aw1', 'pt1aw2', ...
%     'pt1aslp1', 'pt1aslp2', ...
%     'pt8sz1',...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', 
%     'pt2aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
    'EZT019seiz001',...
};
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
addpath(genpath('./fragility_library/'));
addpath(genpath('/Users/adam2392/Dropbox/eeg_toolbox'));
addpath(genpath('/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/eeg_toolbox/'));
fixed_adj_mats_win500_step500_freq1000
%%- Begin Loop Through Different Patients Here
for p=1:length(patients)
    patient = patients{p};
   
    setupScripts;

    % apply included channels to eeg and labels
    if ~isempty(included_channels)
        eeg = eeg(included_channels, :);
        labels = labels(included_channels);
    end
    
    % define args for computing the functional connectivity
    adj_args = struct();
    adj_args.BP_FILTER_RAW = 1;                         % apply notch filter or not?
    adj_args.frequency_sampling = frequency_sampling;   % frequency that this eeg data was sampled at
    adj_args.winSize = winSize;                         % window size
    adj_args.stepSize = stepSize;                       % step size
    adj_args.timeRange = timeRange; 
    adj_args.toSaveAdjDir = toSaveAdjDir;
    adj_args.included_channels = included_channels;     % the included channels
    adj_args.seizureStart = seizureStart;               % the second relative to start of seizure
    adj_args.seizureEnd = seizureEnd;                   % the second relative to end of seizure
    adj_args.labels = labels;                           % all the electrode labels
    adj_args.l2regularization = l2regularization; 
%     adj_args.connectivity = connectivity;
    adj_args.TYPE_CONNECTIVITY = TYPE_CONNECTIVITY;
    adj_args.num_channels = size(eeg,1);
    
    % compute connectivity
    computeConnectivity(patient_id, seizure_id, eeg, clinicalLabels, adj_args);
    
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
