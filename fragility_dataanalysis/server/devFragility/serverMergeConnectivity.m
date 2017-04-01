function serverMergeConnectivity(patient, winSize, stepSize)
%% INITIALIZATION
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

%- 0 == no filtering
%- 1 == notch filtering
%- 2 == adaptive filtering
FILTERTYPE = 1; 

%% Parameters for Analysis
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

%- Edit this file if new patients are added.
[included_channels, ezone_labels, earlyspread_labels,...
    latespread_labels, resection_labels, frequency_sampling, ...
    center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
patient_id = buffpatid;

% set directory to save merged computed data
if FILTERTYPE == 1
    toSaveAdjDir = fullfile(rootDir, 'serverdata/adjmats/notchfilter_adjmats/', strcat('win', num2str(winSize), ...
    '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient); % at lab
elseif FILTERTYPE == 2
    toSaveAdjDir = fullfile(rootDir, 'serverdata/adjmats/adaptivefilter_adjmats/', strcat('win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient); % at lab
else 
    toSaveAdjDir = fullfile(rootDir, 'serverdata/adjmats/nofilter_adjmats/', strcat('win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient); % at lab
end

if ~isempty(TEST_DESCRIP)
    toSaveAdjDir = fullfile(toSaveAdjDir, TEST_DESCRIP);
end

% create directory if it does not exist
if ~exist(toSaveAdjDir, 'dir')
    mkdir(toSaveAdjDir);
end

%- location of the temporarily saved data for each window before merge
tempDir = fullfile('./tempData/', 'connectivity', strcat('win', num2str(winSize), ...
'_step', numstr(stepSize)), patient);
    
% extract info mat file from tempDir
load(fullfile(tempDir, 'info', 'infoAdjMat.mat'));
TYPE_CONNECTIVITY = info.type_connectivity;
ezone_labels = info.ezone_labels;
earlyspread_labels = info.earlyspread_labels;
latespread_labels = info.latespread_labels;
resection_labels = info.resection_labels;
labels = info.all_labels;
winSize = info.winSize;
stepSize = info.stepSize;
timePoints = info.timePoints;
included_channels = info.included_channels;
frequency_sampling = info.frequency_sampling;
FILTER = info.FILTER_TYPE;
seizure_eonset_ms =   info.seizure_estart_ms;       % store in ms
seizure_eoffset_ms =  info.seizure_eend_ms;
seizure_conset_ms =  info.seizure_cstart_ms;
seizure_coffset_ms = info.seizure_coffset_ms;
seizureStartMark =  info.seizure_estart_mark;
seizureEndMark = info.seizure_eend_mark;

if FILTER ~= FILTERTYPE
    disp('error in filters!');
end

[N,~] = size(timePoints);

% load in adjMats file
matFiles = dir(fullfile(tempDir, '*.mat'));
matFileNames = natsort({matFiles.name});
        
winsComputed = zeros(N, 1);    
% construct the adjMats from the windows computed of adjMat
for iMat=1:length(matFileNames)
    matFile = fullfile(tempDir, matFileNames{iMat});
    load(matFile);

    % check window numbers and make sure they are being stored in order
    currentFile = matFileNames{iMat};
    index = strfind(currentFile, '_');
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
adjmat_struct.seizure_estart_ms = seizure_eonset_ms;       % store in ms
adjmat_struct.seizure_eend_ms = seizure_eoffset_ms;
adjmat_struct.seizure_cstart_ms = seizure_conset_ms;
adjmat_struct.seizure_coffset_ms = seizure_coffset_ms;
adjmat_struct.seizure_estart_mark = seizureStartMark;
adjmat_struct.seizure_eend_mark = seizureEndMark;
adjmat_struct.winSize = winSize;
adjmat_struct.stepSize = stepSize;
adjmat_struct.timePoints = timePoints;
adjmat_struct.adjMats = adjMats;
adjmat_struct.included_channels = included_channels;
adjmat_struct.frequency_sampling = frequency_sampling;
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