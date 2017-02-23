patients = {,...
%      'pt1aw1', 'pt1aw2', ...
%     'pt1aslp1', 'pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', 
%     'pt2aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
    'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1' 'pt2sz3' 'pt2sz4', ...
%     'pt3sz2' 'pt3sz4', ...
%       'pt6sz3', 'pt6sz4', 'pt6sz5','JH108sz1', 'JH108sz2', 'JH108sz3', 'JH108sz4', 'JH108sz5', 'JH108sz6', 'JH108sz7',...
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1' 'pt10sz2' 'pt10sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt14sz1' 'pt14sz2' 'pt14sz3' 'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2',...
%     'JH101sz1' 'JH101sz2' 'JH101sz3' 'JH101sz4',...
% 	'JH102sz1' 'JH102sz2' 'JH102sz3' 'JH102sz4' 'JH102sz5' 'JH102sz6',...
% 	'JH103sz1' 'JH103sz2' 'JH103sz3',...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
% 	'JH105sz1' 'JH105sz2' 'JH105sz3'  
%     'JH105sz4' 'JH105sz5',...
% 	'JH106sz1' 'JH106sz2' 'JH106sz3' 'JH106sz4' 'JH106sz5' 'JH106sz6',...
% 	'JH107sz1' 'JH107sz2' 'JH107sz3' 'JH107sz4' 'JH107sz5' 'JH107sz6' 'JH107sz7' 'JH107sz8' 'JH107sz8', 'JH107sz9'...
%     'JH108sz1', 'JH108sz2', 'JH108sz3', 'JH108sz4', 'JH108sz5', 'JH108sz6', 'JH108sz7',...
};

%% Set Working Directories
% set working directory
% data directories to save data into - choose one
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';     % work
% eegRootDirHome = '/Users/adam2392/Documents/MATLAB/Johns Hopkins/NINDS_Rotation';  % home
eegRootDirHome = '/Volumes/NIL_PASS/';
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';
% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

%% Parameters for Analysis
winSize = 500;
stepSize = 500;
frequency_sampling = 1000;
radius = 1.5;

TYPE_CONNECTIVITY = 'leastsquares';
perturbations = ['C', 'R'];
TEST_DESCRIP = 'after_first_removal';
TEST_DESCRIP = [];

for iPat=1:length(patients)
    patient = patients{iPat};
    
     % set patientID and seizureID
    patient_id = patient(1:strfind(patient, 'seiz')-1);
    seizure_id = strcat('_', patient(strfind(patient, 'seiz'):end));
    seeg = 1;
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'sz')-1);
        seizure_id = patient(strfind(patient, 'sz'):end);
        seeg = 0;
    end
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'aslp')-1);
        seizure_id = patient(strfind(patient, 'aslp'):end);
        seeg = 0;
    end
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'aw')-1);
        seizure_id = patient(strfind(patient, 'aw'):end);
        seeg = 0;
    end
    
    %% DEFINE CHANNELS AND CLINICAL ANNOTATIONS
    %- Edit this file if new patients are added.
    %- Edit this file if new patients are added.
    [included_channels, ezone_labels, earlyspread_labels,...
        latespread_labels, resection_labels, frequency_sampling, ...
        center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
    
    % set directory to find adjacency matrix data
    serverDir = fullfile(rootDir, 'serverdata');
    adjMatDir = fullfile(serverDir, 'adjmats/', strcat('win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling))); % at lab
    tempDir = fullfile(rootDir, 'server/devFragility/tempData/', patient);
    
    connDir = fullfile(tempDir, 'connectivity');

    if ~exist(adjMatDir, 'dir')
        mkdir(adjMatDir);
    end
    patient
    tempDir
    adjMatDir
    
%     % set directory to find dataset
%     dataDir = fullfile(rootDir, 'data', center);    
%     %% EZT/SEEG PATIENTS
%     if seeg
%         patient_eeg_path = fullfile(dataDir, patient_id);
%         patient = strcat(patient_id, seizure_id);
%     else
%         patient_eeg_path = fullfile(dataDir, patient);
%     end
%     % READ EEG FILE Mat File
%     % files to process
%     data = load(fullfile(patient_eeg_path, patient));
%     eeg = data.data;
%     %- compute number of windows there are based on length of eeg,
%     %- winSize and stepSize
%     numWins = size(eeg,2) / stepSize - 1;
    
    % extract info mat file from tempDir
    load(fullfile(tempDir, 'infoAdjMat.mat'));
    TYPE_CONNECTIVITY = info.type_connectivity;
    ezone_labels = info.ezone_labels;
    earlyspread_labels = info.earlyspread_labels;
    latespread_labels = info.latespread_labels;
    resection_labels = info.resection_labels;
    labels = info.all_labels;
    seizureStart = info.seizure_start;
    seizureEnd = info.seizure_end;
    winSize = info.winSize;
    stepSize = info.stepSize;
    timePoints = info.timePoints;
    included_channels = info.included_channels;
    frequency_sampling = info.frequency_sampling;

    [N,~] = size(timePoints);
    
    % load in adjMats file
    matFiles = dir(fullfile(connDir, '*.mat'));
    matFileNames = natsort({matFiles.name});
    
%     matFileNames = matFileNames(2:end);
    
    winsComputed = zeros(N, 1);    
    % construct the adjMats from the windows computed of adjMat
    for iMat=1:length(matFileNames)
        matFile = fullfile(connDir, matFileNames{iMat});
        load(matFile);
        
        % check window numbers and make sure they are being stored in order
        currentFile = matFileNames{iMat};
        index =strfind(currentFile, '_');
        currentWin = currentFile(index(2)+1:end-4);
        if str2num(currentWin) ~= iMat
            disp(['There is an error at ', num2str(iMat)]);
        end
         winsComputed(str2num(currentWin)) = 1;
        
        % initialize matrix if first loop and then store results
        if iMat==1
            N = size(theta_adj, 1);
            adjMats = zeros(length(matFileNames), N, N); 
        end
        adjMats(iMat, :, :) = theta_adj;
    end
    test = find(winsComputed == 0)
    if isempty(test)
       SUCCESS = 1;
    else
       SUCCESS = 0;
    end
    
    %%- Create the structure for the adjacency matrices for this patient/seizure
    adjmat_struct = struct();
    adjmat_struct.type_connectivity = TYPE_CONNECTIVITY;
    adjmat_struct.ezone_labels = ezone_labels;
    adjmat_struct.earlyspread_labels = earlyspread_labels;
    adjmat_struct.latespread_labels = latespread_labels;
    adjmat_struct.resection_labels = resection_labels;
    adjmat_struct.all_labels = labels;
    adjmat_struct.seizure_start = seizureStart;
    adjmat_struct.seizure_end = seizureEnd;
    adjmat_struct.winSize = winSize;
    adjmat_struct.stepSize = stepSize;
    adjmat_struct.timePoints = timePoints;
    adjmat_struct.adjMats = adjMats;
    adjmat_struct.included_channels = included_channels;
    adjmat_struct.frequency_sampling = frequency_sampling;
    
    % save the merged adjMatDir
    fileName = strcat(patient, '_adjmats_', lower(TYPE_CONNECTIVITY), '.mat');
    
    % Check if it was successful full computation
    if SUCCESS
        try
            save(fullfile(adjMatDir, fileName), 'adjmat_struct');
        catch e
            disp(e);
            save(fullfile(adjMatDir, fileName), 'adjmat_struct', '-v7.3');
        end
        
        delete((fullfile(connDir, '*.mat')));
    else
        fprintf('Make sure to fix the windows not computed!');
    end
end