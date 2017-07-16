function [toCompute, patWinsToCompute] = checkPatient(patient, rootDir, winSize, stepSize, filterType, JOBTYPE)
% function: checkPatient
% By: Adam Li
% Date: 6/12/17
% Description: Checks the patient and checks if there
% are correctly computed windows in each patient directory
% 
% Input: 
% - patientList: cell array of all the patients is example: {'pt1sz2',
% 'pt10sz3'}
% - computedDir: the directory to check for all the computed patients
% Output:
% - toCompute: either 0, or 1 if the patient still needs to be computed
% - patWinsToCompute: a vector of windows still needed to be computed by
% the server
if nargin == 0
    patient = 'pt1sz2';
    rootDir = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/server/marccDev/matlab_lib/tempData/adaptivefilter/win250_step125/connectivity/';
    winSize = 250;
    stepSize = 125;
    filterType = 'adaptivefilter';
end

 % data directories to save data into - choose one
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';    % at JHU workstation
eegRootDirMarcc = '/scratch/groups/ssarma2/adamli/fragility_dataanalysis/';

% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), eegrootDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHome)), eegrootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), eegrootDir = eegRootDirJhu;
elseif ~isempty(dir(eegRootDirMarcc)), eegrootDir = eegRootDirMarcc;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end
addpath(eegrootDir);

%- directory for the data stored
if JOBTYPE==1
    tempDir = fullfile(rootDir, 'server/marccDev/matlab_lib/tempData/', ...
        filterType, strcat('win', num2str(winSize), '_step', num2str(stepSize)), 'connectivity');
elseif JOBTYPE==2
    tempDir = fullfile(rootDir, 'server/marccDev/matlab_lib/tempData/', ...
        filterType, strcat('win', num2str(winSize), ...
        '_step', num2str(stepSize), '_radius', num2str(radius)), 'perturbation');
end

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
buffpatid = patient_id;
if strcmp(patient_id(end), '_')
    patient_id = patient_id(1:end-1);
end

%% DEFINE OUTPUT DIRS AND CLINICAL ANNOTATIONS
%- Edit this file if new patients are added.
[included_channels, ezone_labels, earlyspread_labels,...
    latespread_labels, resection_labels, fs, ...
    center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
        
patDirExists = exist(fullfile(tempDir, patient), 'dir');

if JOBTYPE==1
    dataDirExists = dir(fullfile(eegrootDir, 'serverdata/adjmats', strcat(filterType), ...
            strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)),...
            patient, '*.mat'));
elseif JOBTYPE==2
    dataDirExists = dir(fullfile(eegrootDir, 'serverdata/pertmats', strcat(filterType), ...
            strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)),...
            patient, '*.mat'));
end

% initialize return variables
toCompute = 0;
patWinsToCompute = [];

if 7==patDirExists && isempty(dataDirExists)  % temp dir exists, but merged data dir doensn't exist
    % check if each directory has the right windows computed
    fileList = dir(fullfile(tempDir, patient, '*.mat'));
    fileList = {fileList(:).name};

    % get numWins needed
    numWins = getNumWins(patient, winSize, stepSize);

    % get the windows still needed to compute, if any
    winsToCompute = checkWindows(fileList, numWins);

    toCompute = 1;
    if ~isempty(winsToCompute)
        fprintf('Need to compute certain windows for %s still!\n', patient);
        patWinsToCompute = winsToCompute;
    end
elseif 7~=patDirExists && isempty(dataDirExists) % temp and merged dir don't exist
    fprintf('Need to compute for %s still!\n', patient);
    toCompute = 1;
else
    fprintf('%s directory already exists!\n', patient);
end