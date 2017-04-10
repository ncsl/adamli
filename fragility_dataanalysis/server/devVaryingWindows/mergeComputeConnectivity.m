function mergeComputeConnectivity(patient, winSize, stepSize)
%% INITIALIZATION
% data directories to save data into - choose one
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';     % work
% eegRootDirHome = '/Users/adam2392/Documents/MATLAB/Johns Hopkins/NINDS_Rotation';  % home
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';
% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

patient_id = [];
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
 buffpatid = patient_id;
if strcmp(patient_id(end), '_')
    patient_id = patient_id(1:end-1);
end
%% DEFINE CHANNELS AND CLINICAL ANNOTATIONS
%- Edit this file if new patients are added.
[included_channels, ezone_labels, earlyspread_labels,...
    latespread_labels, resection_labels, frequency_sampling, ...
    center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
patient_id = buffpatid;

% set dir to find temp data files
tempDir = fullfile('./tempData/', 'connectivity', strcat('win', num2str(winSize), ...
    '_step', num2str(stepSize)), patient);
if ~exist(tempDir, 'dir')
    mkdir(tempDir);
end

if seeg
    patient = strcat(patient_id, seizure_id);
    eegDir = fullfile(rootDir, 'data', center);
    data_struct = load(fullfile(eegDir, patient_id, patient));
else
    eegDir = fullfile(rootDir, 'data', center);
    data_struct = load(fullfile(eegDir, patient, patient));
end

data = data_struct.data;
[N, T] = size(data);
clear data

% all the temp lti models per window
matFiles = dir(fullfile(tempDir, '*.mat'));
matFileNames = natsort({matFiles.name});

%- load info file
load(fullfile(tempDir,'info', 'infoAdjMat.mat'));
FILTERTYPE = info.FILTER_TYPE;

% set directory to save merged computed data
if FILTERTYPE == 1
    toSaveDir = fullfile(rootDir, strcat('/serverdata/adjmats/', typeTransform, '/notchharmonics/win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
elseif FILTERTYPE == 2
    toSaveDir = fullfile(rootDir, strcat('/serverdata/adjmats/', typeTransform, '/adaptivefilter/win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
else 
    toSaveDir = fullfile(rootDir, strcat('/serverdata/adjmats/', typeTransform, '/nofilter/', 'win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
end
% create directory if it does not exist
if ~exist(toSaveDir, 'dir')
    mkdir(toSaveDir);
end


winsComputed = zeros(N, 1);  

% construct the adjMats from the windows computed of adjMat
for iMat=1:length(matFileNames)
    matFile = fullfile(tempDir, matFileNames{iMat});
    data = load(matFile);

    % check window numbers and make sure they are being stored in order
    currentFile = matFileNames{iMat};
    index = strfind(currentFile, '_');
    index = currentFile(1:index-1);

    if str2num(index) ~= iMat
        disp(['There is an error at ', num2str(iMat)]);
    end
    winsComputed(str2num(index)) = 1;

     % extract the computed tehta adjacency
    theta_adj = data.theta_adj;
    
    % initialize matrix if first loop and then store results
    if iMat==1
        N = size(theta_adj, 1);
        adjMats = zeros(length(matFileNames), N, N); 
    end
    adjMats(iMat, :, :) = theta_adj;
end

%%- Create the structure for the adjacency matrices for this patient/seizure
adjmat_struct = struct();
adjmat_struct.type_connectivity = info.TYPE_CONNECTIVITY;
adjmat_struct.ezone_labels = info.ezone_labels;
adjmat_struct.earlyspread_labels = info.earlyspread_labels;
adjmat_struct.latespread_labels = info.latespread_labels;
adjmat_struct.resection_labels = info.resection_labels;
adjmat_struct.all_labels = info.all_labels;
adjmat_struct.seizure_estart_ms = info.seizure_eonset_ms;       % store in ms
adjmat_struct.seizure_eend_ms = info.seizure_eoffset_ms;
adjmat_struct.seizure_cstart_ms = info.seizure_conset_ms;
adjmat_struct.seizure_coffset_ms = info.seizure_coffset_ms;
adjmat_struct.seizure_estart_mark = info.seizure_estart_mark;
adjmat_struct.seizure_eend_mark = info.seizure_eend_mark;
adjmat_struct.engelscore = info.engelscore;
adjmat_struct.outcome = info.outcome;
adjmat_struct.winSize = info.winSize;
adjmat_struct.stepSize = info.stepSize;
adjmat_struct.timePoints = info.timePoints;
adjmat_struct.adjMats = adjMats;
adjmat_struct.included_channels = info.included_channels;
adjmat_struct.frequency_sampling = info.frequency_sampling;
adjmat_struct.FILTER = FILTERTYPE;

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

    rmdir(fullfile(tempDir));
else
    fprintf('Make sure to fix the windows not computed!');
end
end