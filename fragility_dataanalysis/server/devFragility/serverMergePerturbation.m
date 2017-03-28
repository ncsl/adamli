function serverMergePerturbation(patient, winSize, stepSize, radius)
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

perturbationTypes = ['C', 'R'];
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
    %%- notch filtering harmonics
    toSavePertDir = fullfile(serverDir, ...
        'harmonics', strcat(perturbationType, '_perturbations', '_radius', num2str(radius)),...
        strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), ...
        patient);
elseif FILTERTYPE == 2
    %%- adaptive filtering harmonics
    toSavePertDir = fullfile(serverDir, ...
            'perturbationmats/adaptivefilter', strcat(perturbationType, '_perturbations', '_radius', num2str(radius)),...
            strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), ...
            patient)
else 
    %%- w/o filtering harmonics
    toSavePertDir = fullfile(serverDir, ...
            strcat(perturbationType, '_perturbations', '_radius', num2str(radius)),...
            strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), ...
            patient);
end

tempDir = fullfile('./tempData/', 'perturbation', strcat('win', num2str(winSize), ...
    '_step', num2str(stepSize), '_radius', num2str(radius)), patient);

% create directory if it does not exist
if ~exist(toSaveAdjDir, 'dir')
    mkdir(toSaveAdjDir);
end

% extract info mat file from tempDir
load(fullfile(tempDir, 'info', 'infoAdjMat.mat'));
%- set meta data struct
ezone_labels =  info.ezone_labels;
earlyspread_labels = info.earlyspread_labels;
latespread_labels = info.latespread_labels;
resection_labels =    info.resection_labels;
all_labels =    info.all_labels;
seizure_start =   info.seizure_start ;
seizure_end =  info.seizure_end;
FILTER = info.FILTER;
timePoints = info.timePoints;
TYPE_CONNECTIVITY = info.TYPE_CONNECTIVITY;

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
    data = load(matFile);
    data = data.perturbation_struct;

    % check window numbers and make sure they are being stored in order
    currentFile = matFileNames{iMat};
    index = strfind(currentFile, '_');
    currentWin = currentFile(index(2)+1:end-4);
    
    if str2num(currentWin) ~= iMat
        disp(['There is an error at ', num2str(iMat)]);
    end
    winsComputed(str2num(currentWin)) = 1;

    for j=1:length(perturbationTypes)
        perturbationType = perturbationTypes(j);
        
        minNormPertMat = data.(perturbationType).minNormPertMat;
        fragilityMat = data.(perturbationType).fragilityMat;
        del_table = data.(perturbationType).del_table;
        
        % initialize matrix if first loop and then store results
        if iMat==1
            %- initialize matrices for storing each row/col 
            rowPertMats = zeros(length(matFileNames), N, N); 
            colPertmats = zeros(length(matFileNames), N, N);
            rowfragMats = zeros(length(matFileNames), N, N); 
            colfragmats = zeros(length(matFileNames), N, N);
            
            rowdel_table = cell(N, length(matFileNames));
            coldel_table = cell(N, length(matFileNames));
        end
        rowPertMats(iMat, :, :) = theta_adj;
    end
end

test = find(winsComputed == 0)
if isempty(test)
   SUCCESS = 1;
else
   SUCCESS = 0;
end

% initialize struct to save
perturbation_struct = struct();
perturbation_struct.info = info; % meta data info
perturbation_struct.C.minNormPertMat = colPertmats;
perturbation_struct.C.fragilityMat = colfragMats;
perturbation_struct.C.del_table = coldel_table;
perturbation_struct.R.minNormPertMat = rowPertmats;
perturbation_struct.R.fragilityMat = rowfragMats;
perturbation_struct.R.del_table = rowdel_table;

% save the merged adjMatDir
filename = strcat(patient, '_', 'perturbation_', ...
                lower(TYPE_CONNECTIVITY), '_radius', num2str(radius), '.mat');
% Check if it was successful full computation
if SUCCESS
    try
        % save the perturbation struct result
        save(fullfile(toSavePertDir, filename), 'perturbation_struct');
    catch e
        disp(e);
                % save the perturbation struct result
        save(fullfile(toSavePertDir, filename), 'perturbation_struct', '-v7.3');
    end

    rmdir(fullfile(tempDir));
else
    fprintf('Make sure to fix the windows not computed!');
end
end