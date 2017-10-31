function mergeConn(patient, winSize, stepSize, reference, numToRemove)
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
if nargin==0
    patient='LA15_ICTAL';
    winSize=250;
    stepSize=125;
    reference = 'avgref';
end
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

%% Parameters HARD CODED
%- 0 == no filtering
%- 1 == notch filtering
%- 2 == adaptive filtering
filterType = 'notchfilter';

%% DEFINE CHANNELS AND CLINICAL ANNOTATIONS
% set patientID and seizureID
[~, patient_id, seizure_id, seeg] = splitPatient(patient);

%- Edit this file if new patients are added.
[included_channels, ezone_labels, earlyspread_labels,...
    latespread_labels, resection_labels, fs, ...
    center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);

%- get the temporary directory to look at
tempDir = fullfile(rootDir, 'server/marccDev/matlab_lib/tempData/', ...
        'virtualresection', 'connectivity', filterType, ...
        strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)));
patTempDir = fullfile(rootDir, 'server/marccDev/matlab_lib/tempData/', ...
                'virtualresection', 'connectivity', filterType, ...
                strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
                patient, reference, strcat('removed', num2str(numToRemove)));

%- set directory to save merged computed data
toSaveDir = fullfile(rootDir, 'serverdata/virtualresection/adjmats', strcat(filterType), ...
                strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)),...
                patient, reference, strcat('removed', num2str(numToRemove)));

% create directory if it does not exist
if ~exist(toSaveDir, 'dir')
    mkdir(toSaveDir);
end

%- load info file
load(fullfile(patTempDir, 'info', 'infoAdjMat.mat'));

% all the temp lti models per window
matFiles = dir(fullfile(patTempDir, '*.mat'));
matFileNames = natsort({matFiles.name});

% construct the adjMats from the windows computed of adjMat
for iMat=1:length(matFileNames)
    matFile = fullfile(patTempDir, matFileNames{iMat});
    data = load(matFile);

     % extract the computed theta adjacency
     theta_adj = data.theta_adj;
    
    % initialize matrix if first loop and then store results
    if iMat==1
        N = size(theta_adj, 1);
        adjMats = zeros(length(matFileNames), N, N); 
        fprintf('There are %f number of mat files\n', length(matFileNames));
    end
    
    try
        adjMats(iMat, :, :) = theta_adj;
    catch e
        disp(iMat);
        parallelComputeConnectivity(patient, winSize, stepSize, iMat);
        disp(size(theta_adj));
        fprintf('\n');
%         disp(size(adjMats));
    end
end

%%- Create the structure for the adjacency matrices for this patient/seizure
adjmat_struct = struct();
adjmat_struct.type_connectivity = info.type_connectivity;
adjmat_struct.ezone_labels = info.ezone_labels;
adjmat_struct.earlyspread_labels = info.earlyspread_labels;
adjmat_struct.latespread_labels = info.latespread_labels;
adjmat_struct.resection_labels = info.resection_labels;
adjmat_struct.all_labels = info.all_labels;
adjmat_struct.included_labels = info.included_labels;
adjmat_struct.chans_removed = info.chans_removed;
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
fileName = strcat(patient, '_adjmats', reference, '_', 'removed', num2str(numToRemove), '.mat');

varinfo = whos('adjmat_struct');
if varinfo.bytes < 2^31
    save(fullfile(toSaveDir, fileName), 'adjmat_struct');
else 
    save(fullfile(toSaveDir, fileName), 'adjmat_struct', '-v7.3');
end

fprintf('Successful merging of connectivity!\n');

% Remove directories if successful
delete(fullfile(patTempDir, 'info', '*.mat'));
rmdir(fullfile(patTempDir, 'info'));
delete(fullfile(patTempDir, '*.mat'));
rmdir(fullfile(tempDir, patient));

fprintf('Removed everything!\n');
end