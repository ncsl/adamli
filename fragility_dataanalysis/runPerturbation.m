%% set up and test adjmat
% adjMats = adjmat_struct.adjMats;
% pertMats = perturbation_struct.del_table;
% 
% iTime = 1;
% iNode = 1;
% N = size(adjMats,3);
% 
% for iNode=1:N
%     ek = [zeros(iNode-1, 1); 1; zeros(N-iNode,1)]; % unit column vector at this node
%     adjMat = squeeze(adjMats(iTime,:,:));
%     pertMat = pertMats{iNode,iTime};
% 
%     pert = pertMat*ek';
%     test = adjMat + pert;
%     figure;
%     plot(real(eig(test)), imag(eig(test)), 'ko')
%     
%     close all
% end

clear all;
close all;
clc;

% settings to run
patients = {,...
     'pt1sz2',...
%      'pt1sz3',...
};

perturbationTypes = ['R'];
radius = 1.5;             % spectral radius
w_space = linspace(-radius, radius, 101);
winSize = 500;            % 500 milliseconds
stepSize = 500; 
frequency_sampling = 1000; % in Hz
IS_SERVER = 0;
TYPE_CONNECTIVITY = 'leastsquares';

% add libraries of functions
addpath(genpath('./fragility_library/'));
addpath(genpath('/Users/adam2392/Dropbox/eeg_toolbox'));
addpath(genpath('/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/eeg_toolbox/'));

% set directory to find adjacency matrix data
adjMatDir = './serverdata/fixed_adj_mats_win500_step500_freq1000/'; % at lab
adjMatDir = '/Volumes/NIL_PASS/serverdata/fixed_adj_mats_win500_step500_freq1000/'; % on ext HD

%%- Begin Loop Through Different Patients Here
for p=1:length(patients)
    patient = patients{p};
    
    patDir = fullfile(adjMatDir, patient);
    fileName = strcat(patient, '_adjmats_leastsquares.mat');
    data = load(fullfile(patDir, fileName));
    data = data.adjmat_struct;
    
    % extract meta data
    ezone_labels = data.ezone_labels;
    earlyspread_labels = data.earlyspread_labels;
    latespread_labels = data.latespread_labels;
    resection_labels = data.resection_labels;
    all_labels = data.all_labels;
    seizure_start = data.seizure_start;
    seizure_end = data.seizure_end;
    winSize = data.winSize;
    stepSize = data.stepSize;
    frequency_sampling = data.frequency_sampling;
    included_channels = data.included_channels;
    timePoints = data.timePoints;
    
    %- set meta data struct
    info.ezone_labels = ezone_labels;
    info.earlyspread_labels = earlyspread_labels;
    info.latespread_labels = latespread_labels;
    info.resection_labels = resection_labels;
    info.all_labels = all_labels;
    info.seizure_start = seizure_start;
    info.seizure_end = seizure_end;
    info.winSize = winSize;
    info.stepSize = stepSize;
    info.frequency_sampling = frequency_sampling;
    info.included_channels = included_channels;

    adjMats = data.adjMats;
    [T, N, ~] = size(adjMats);
    %% 02: RUN PERTURBATION ANALYSIS For Column or Row
    for j=1:length(perturbationTypes)
        % initialize matrices to store
        minNormPerturbMat = zeros(N,T);
        fragilityMat = zeros(N,T);
        del_table = cell(N, T);
        
        perturbationType = perturbationTypes(j);
        
        % save the perturbation results
        filename = strcat(patient, '_', perturbationType, 'perturbation_', ...
                lower(TYPE_CONNECTIVITY), '_radius', num2str(radius), '.mat');
            
        toSavePertDir = fullfile(adjMatDir, strcat(perturbationType, '_perturbations', ...
            '_radius', num2str(radius)), '_newfixedalg');
        if ~exist(toSavePertDir, 'dir')
            mkdir(toSavePertDir);
        end

        perturb_args = struct();
        perturb_args.perturbationType = perturbationType;
        perturb_args.w_space = w_space;
        perturb_args.radius = radius;
        
        parfor iTime=1:T % loop through each window of adjacency mats
            adjMat = squeeze(adjMats(iTime,:,:));
            
            [minNormPert, del_vecs, ERRORS] = minNormPerturbation(patient, adjMat, perturb_args);
        
            % store results
            minNormPerturbMat(:, iTime) = minNormPert;
            del_table(:, iTime) = del_vecs;
            
            % test on adjMat
%             iNode = 86;
%             ek = [zeros(iNode-1, 1); 1; zeros(N-iNode,1)];
%             if strcmp(perturbationType, 'C')
%                 pertMat = del_table{iNode, iTime} * ek';
%             end
%             test = adjMat+pertMat;
%             plot(real(eig(test)), imag(eig(test)), 'ko')
                
            disp(['Finished time: ', num2str(iTime)]);
        end
        
        % Compute fragility rankings per column by normalization
        for i=1:N      % loop through each channel
            for t=1:T % loop through each time point
                fragilityMat(i,t) = (max(minNormPerturbMat(:,t)) - minNormPerturbMat(i,t)) ...
                                            / max(minNormPerturbMat(:,t));
            end
        end
        
        % initialize struct to save
        perturbation_struct = struct();
        perturbation_struct.info = info; % meta data info
        perturbation_struct.minNormPertMat = minNormPerturbMat;
        perturbation_struct.timePoints = timePoints;
        perturbation_struct.fragilityMat = fragilityMat;
        perturbation_struct.del_table = del_table;
        
        % save the perturbation struct result
        save(fullfile(toSavePertDir, filename), 'perturbation_struct');
        disp(['Saved file: ', filename]);
    end
    
    
end
