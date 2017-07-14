function mergePerturbation(patient, winSize, stepSize, radius)
% function: mergePerturbation
% By: Adam Li
% Date: 7/8/17
% Description: For a patient's computed perturbation model, merge
% them into 1 big mat file.
% 
% Input: 
% - patient: cell array of all the patients is example: {'pt1sz2',
% 'pt10sz3'}
% - winSize:
% - stepSize:
% - radius:
% Output:
% - saves the perturbation model into 1 mat file
if nargin==0
    patient = 'Pat2sz1p';
    winSize=250;
    stepSize=125;
    radius=1.1;
end

fprintf('Inside merging perturbations...\n');

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
FILTERTYPE = 2; 
filterType = 'adaptive';
TYPE_CONNECTIVITY = 'leastsquares';

perturbationTypes = ['C', 'R'];

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
    latespread_labels, resection_labels, fs, ...
    center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
patient_id = buffpatid;

%- get the temporary directory to look at
tempDir = fullfile('./tempData/', strcat(filterType, 'filter'), strcat('win', num2str(winSize), ...
    '_step', num2str(stepSize)), 'perturbation', patient);
% tempDir = fullfile('./tempData', patient);

%- set directory to save merged computed data
toSaveDir = fullfile(rootDir, strcat('/serverdata/pertmats/', filterType, 'filter'), ...
    strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)),...
    patient);

% create directory if it does not exist
if ~exist(toSaveDir, 'dir')
    mkdir(toSaveDir);
end

%- load info file
info = load(fullfile(tempDir, 'info', 'infoPertMat.mat'), 'info');
info = info.info;

% all the temp lti models per window
matFiles = dir(fullfile(tempDir, '*.mat'));
matFileNames = natsort({matFiles.name});

perturbation_struct = struct();

% construct the adjMats from the windows computed of adjMat
for iMat=1:length(matFileNames)
    matFile = fullfile(tempDir, matFileNames{iMat});
    data = load(matFile);
    % extract the computed theta adjacency
    perturbation = data.perturbation_struct;
    
    for iPert=1:length(perturbationTypes)
        perturbationType = perturbationTypes(iPert);
        
        % initialize matrix if first loop and then store results
        if iMat==1
            N = size(perturbation.(perturbationType).fragilityMat, 1);

            %- initialize
            perturbation_struct.(perturbationType).minNormPertMat = zeros(N, length(matFileNames));
            perturbation_struct.(perturbationType).fragilityMat = zeros(N, length(matFileNames));
            perturbation_struct.(perturbationType).del_table = cell(N, length(matFileNames));
        end
        
        % extract the perturbation model and fragility matrix
        perturbation_struct.(perturbationType).del_table(:, iMat) = perturbation.(perturbationType).del_table;
        perturbation_struct.(perturbationType).minNormPertMat(:, iMat) = perturbation.(perturbationType).minNormPertMat;
        perturbation_struct.(perturbationType).fragilityMat(:, iMat) = perturbation.(perturbationType).fragilityMat; 
    end
end

%%- Create the structure for the pert model for this patient/seizure
perturbation_struct.info = info;

% save the merged adjMatDir
fileName = strcat(patient, '_pertmats', '.mat');

varinfo = whos('perturbation_struct');
if varinfo.bytes < 2^31
    save(fullfile(toSaveDir, fileName), 'perturbation_struct');
else 
    save(fullfile(toSaveDir, fileName), 'perturbation_struct', '-v7.3');
end

fprintf('Successful merging of perturbation!\n');

% Remove directories if successful
delete(fullfile(tempDir, 'info', '*.mat'));
rmdir(fullfile(tempDir, 'info'));
delete(fullfile(tempDir, '*.mat'));
rmdir(fullfile(tempDir));

fprintf('Removed everything!\n');
end