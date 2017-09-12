function mergeConnectivity(patient, winSize, stepSize)
% function: mergeConnectivity
% By: Adam Li
% Date: 6/12/17
% Description: For a patient's computed connectivity matrix windows, merge
% them into 1 big mat file.
% 
% Input: 
% - patient: cell array of all the patients is example: {'pt1sz2',
% 'pt10sz3'}
% - computedDir: the directory to check for all the computed patients
% Output:
% - vector of patients needed to compute
fprintf('Inside merging connectivity...\n');

%% INITIALIZATION
% data directories to save data into - choose one
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';    % at JHU workstation
% eegRootDirMarcc = '/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/'; % at MARCC server
eegRootDirMarcc = '/scratch/groups/ssarma2/adamli/fragility_dataanalysis/';
% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
elseif ~isempty(dir(eegRootDirMarcc)), rootDir = eegRootDirMarcc;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

% rootDir = '/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/'; % at MARCC server

%- 0 == no filtering
%- 1 == notch filtering
%- 2 == adaptive filtering
filterType = 'notchfilter';

% set patientID and seizureID
[~, patient_id, seizure_id, seeg] = splitPatient(patient);

%% DEFINE CHANNELS AND CLINICAL ANNOTATIONS
%- Edit this file if new patients are added.
[included_channels, ezone_labels, earlyspread_labels,...
    latespread_labels, resection_labels, fs, ...
    center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);

%- get the temporary directory to look at
tempDir = fullfile('./tempData/', strcat(filterType, '/win', num2str(winSize), ...
        '_step', num2str(stepSize)), 'connectivity', patient);

%- set directory to save merged computed data
toSaveDir = fullfile(rootDir, strcat('/serverdata/adjmats/', filterType, '/win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
    
% create directory if it does not exist
if ~exist(toSaveDir, 'dir')
    mkdir(toSaveDir);
end

%- load info file
load(fullfile(tempDir, 'info', 'infoAdjMat.mat'));

% all the temp lti models per window
matFiles = dir(fullfile(tempDir, '*.mat'));
matFileNames = natsort({matFiles.name});

% get numWins needed
numWins = getNumWins(patient, winSize, stepSize);

% construct the adjMats from the windows computed of adjMat
for iMat=1:length(matFileNames)
    matFile = fullfile(tempDir, matFileNames{iMat});
    data = load(matFile);

     % extract the computed theta adjacency
    theta_adj = data.theta_adj;
    
    % initialize matrix if first loop and then store results
    if iMat==1
        N = size(theta_adj, 1);
        adjMats = zeros(numWins, N, N); 
    end
    adjMats(iMat, :, :) = theta_adj;
end

%%- Create the structure for the adjacency matrices for this patient/seizure
adjmat_struct = struct();
adjmat_struct.type_connectivity = info.type_connectivity;
adjmat_struct.ezone_labels = info.ezone_labels;
adjmat_struct.earlyspread_labels = info.earlyspread_labels;
adjmat_struct.latespread_labels = info.latespread_labels;
adjmat_struct.resection_labels = info.resection_labels;
adjmat_struct.all_labels = info.all_labels;
adjmat_struct.seizure_estart_ms = info.seizure_estart_ms;       % store in ms
adjmat_struct.seizure_eend_ms = info.seizure_eend_ms;
adjmat_struct.seizure_cstart_ms = info.seizure_cstart_ms;
adjmat_struct.seizure_cend_ms = info.seizure_coffset_ms;
adjmat_struct.seizure_estart_mark = info.seizure_estart_mark;
adjmat_struct.seizure_eend_mark = info.seizure_eend_mark;
adjmat_struct.engelscore = info.engelscore;
adjmat_struct.outcome = info.outcome;
adjmat_struct.winSize = info.winSize;
adjmat_struct.stepSize = info.stepSize;
adjmat_struct.numSamplesInWin = info.numSamplesInWin;
adjmat_struct.numSamplesInStep = info.numSamplesInStep;
adjmat_struct.rawtimePoints = info.rawtimePoints;
adjmat_struct.timePoints = info.timePoints;
adjmat_struct.adjMats = adjMats;
adjmat_struct.included_channels = info.included_channels;
adjmat_struct.frequency_sampling = info.frequency_sampling;
adjmat_struct.FILTER = info.FILTER_TYPE;

% save the merged adjMatDir
fileName = strcat(patient, '_adjmats_', lower(info.type_connectivity), '.mat');

varinfo = whos('adjmat_struct');
if varinfo.bytes < 2^31
    save(fullfile(toSaveDir, fileName), 'adjmat_struct');
else 
    save(fullfile(toSaveDir, fileName), 'adjmat_struct', '-v7.3');
end

fprintf('Successful merging!\n');

% Remove directories if successful
delete(fullfile(tempDir, 'info', '*.mat'));
rmdir(fullfile(tempDir, 'info'));
delete(fullfile(tempDir, '*.mat'));
rmdir(fullfile(tempDir));

fprintf('Removed everything!\n');
end