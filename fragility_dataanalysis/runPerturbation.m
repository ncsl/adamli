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

% clear all;
% close all;
% clc;
% 
% % settings to run
patients = {...
%      'pt1aw1', 'pt1aw2', ...
%     'pt1aslp1', 'pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', 'pt2aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
%     'pt1sz2', 'pt1sz3', 'pt1sz4',...
% %     'pt2sz1', 'pt2sz3', 'pt2sz4', ...
% %     'pt3sz2', 'pt3sz4', ...
% %     'pt6sz3', 'pt6sz4', 'pt6sz5',...
% %     'pt8sz1', 'pt8sz2', 'pt8sz3',...
% %     'pt10sz1' 'pt10sz2' 'pt10sz3', ...
% %     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
% %     'pt14sz1' 'pt14sz2' 'pt14sz3' 'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
% %     'pt16sz1' 'pt16sz2' 'pt16sz3',...
% %     'pt17sz1' 'pt17sz2',...
%   'JH101sz1' 'JH101sz2' 'JH101sz3' 'JH101sz4',...
% % 	'JH102sz1' 'JH102sz2' 'JH102sz3' 'JH102sz4' 'JH102sz5' 'JH102sz6',...
% 	'JH103sz1' 'JH103sz2' 'JH103sz3',...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
% % 	'JH105sz1' 'JH105sz2' 'JH105sz3'  'JH105sz4' 'JH105sz5',...
% % 	'JH106sz1' 'JH106sz2' 'JH106sz3' 'JH106sz4' 'JH106sz5' 'JH106sz6',...
% % 	'JH107sz1' 'JH107sz2' 'JH107sz3' 'JH107sz4' 'JH107sz5' 'JH107sz6' 'JH107sz7' 'JH107sz8' 'JH107sz8', 'JH107sz9'...
%   'JH108sz1', 'JH108sz2', 'JH108sz3', 
'JH108sz4', 'JH108sz5', 'JH108sz6', 'JH108sz7',...

% 'JH107sz7',...
};

% function runPerturbation(patients)
perturbationTypes = ['C', 'R'];
radius = 1.5;             % spectral radius
w_space = linspace(-radius, radius, 51);
winSize = 500;            % 500 milliseconds
stepSize = 500; 
frequency_sampling = 1000; % in Hz
IS_SERVER = 0;
TYPE_CONNECTIVITY = 'leastsquares';
TEST_DESCRIP = [];


% add libraries of functions
addpath(genpath('./fragility_library/'));
addpath(genpath('/Users/adam2392/Dropbox/eeg_toolbox'));
addpath(genpath('/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/eeg_toolbox/'));

% set directory to find adjacency matrix data
adjMatDir = './serverdata/fixed_adj_mats_win500_step500_freq1000/'; % at lab
% adjMatDir = '/Volumes/NIL_PASS/serverdata/fixed_adj_mats_win500_step500_freq1000/'; % on ext HD

%%- Begin Loop Through Different Patients Here
for p=1:length(patients)
    patient = patients{p};
    
    patDir = fullfile(adjMatDir, patient);
    
    if ~isempty(TEST_DESCRIP)
        patDir = fullfile(patDir, TEST_DESCRIP);
    end
    
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

    seizureMarkStart = seizure_start / winSize;
    
    adjMats = data.adjMats;
    [T, N, ~] = size(adjMats);
    
    % only get the time points before seizure -> slightly after seizure
    adjmats = adjMats(1:seizureMarkStart+2,:,:);
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
            
        toSavePertDir = fullfile(patDir, strcat(perturbationType, '_perturbations', ...
            '_radius', num2str(radius)));
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
% end