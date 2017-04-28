% patients = {,...,
% %      'pt1aw2', ...
% %     'pt1aslp1', 'pt1aslp2', ...
% %     'pt2aw1', 
%     'pt2aw2', ...
%     'pt2aslp1', 'pt2aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
%     'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1' 'pt2sz3' ,'pt2sz4', ...
%     'pt3sz2' 'pt3sz4', ...
%     'pt6sz3', 'pt6sz4', 'pt6sz5',...
%     'pt7sz19', 'pt7sz21', 'pt7sz22',... 
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1', 'pt10sz2' 'pt10sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt12sz1', 'pt12sz2', ...
%     'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
%     'pt14sz1' 'pt14sz2' 'pt14sz3',...
%     'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2', 'pt17sz3', ...
%     };
% radius=1.5;
% winSize=250;
% stepSize=125;
% for i=1:length(patients)
%     patient=patients{i};
%     mergeComputePerturbation(patient, radius, winSize, stepSize);
% end

function mergeComputePerturbation(patient, radius, winSize, stepSize)
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
    latespread_labels, resection_labels, frequency_sampling, ...
    center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
patient_id = buffpatid;

% set dir to find temp data files
%- temp directory
tempDir = fullfile('./tempData/', 'perturbation', strcat('win', num2str(winSize), ...
    '_step', num2str(stepSize)), patient);

% all the temp lti models per window
matFiles = dir(fullfile(tempDir, '*.mat'));
matFileNames = natsort({matFiles.name});

%- load info file
load(fullfile(tempDir,'info', 'infoPertMat.mat'));
FILTERTYPE = info.FILTER;
fs = info.frequency_sampling;

% set directory to save merged computed data
if FILTERTYPE == 1
    toSaveDir = fullfile(rootDir, strcat('/serverdata/perturbationmats/notchfilter', '/win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)), patient); % at lab
elseif FILTERTYPE == 2
    toSaveDir = fullfile(rootDir, strcat('/serverdata/perturbationmats/adaptivefilter', '/win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)), patient); % at lab
else 
    toSaveDir = fullfile(rootDir, strcat('/serverdata/perturbationmats/nofilter', 'win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)), patient); % at lab
end
% create directory if it does not exist
if ~exist(toSaveDir, 'dir')
    mkdir(toSaveDir);
end
toSaveDir

perturbation_struct = struct();

% construct the adjMats from the windows computed of adjMat
for iMat=1:length(matFileNames)
    matFile = fullfile(tempDir, matFileNames{iMat});
    data = load(matFile);
    perturbation = data.perturbation_struct;

    % check window numbers and make sure they are being stored in order
    currentFile = matFileNames{iMat};
    index = strfind(currentFile, '_');
    index = currentFile(index(2)+1:end-4);

    if str2double(index) ~= iMat
        disp(['There is an error at ', num2str(iMat)]);
    end

    for iPert=1:length(perturbationTypes)
        perturbationType = perturbationTypes(iPert);
        
        % initialize matrix if first loop and then store results
        if iMat==1
            N = size(perturbation.(perturbationType).fragilityMat, 1);
            winsComputed = zeros(N, 1);  

            %- initialize
            perturbation_struct.(perturbationType).minNormPertMat = zeros(N, length(matFileNames));
            perturbation_struct.(perturbationType).fragilityMat = zeros(N, length(matFileNames));
            perturbation_struct.(perturbationType).del_table = cell(N, length(matFileNames));
        end

         % extract the computed tehta adjacency
        perturbation_struct.(perturbationType).del_table(:, iMat) = perturbation.(perturbationType).del_table;
        perturbation_struct.(perturbationType).minNormPertMat(:, iMat) = perturbation.(perturbationType).minNormPertMat;
        perturbation_struct.(perturbationType).fragilityMat(:, iMat) = perturbation.(perturbationType).fragilityMat;
    end
    
%     winsComputed(str2double(index)) = 1;
end

%%- Create the structure for the adjacency matrices for this patient/seizure
perturbation_struct.info = info;

% save the merged adjMatDir
fileName = strcat(patient, '_pertmats_', lower(info.TYPE_CONNECTIVITY), '_radius', num2str(radius), '.mat');

% test = find(winsComputed == 0);
% if isempty(test)
%    SUCCESS = 1;
% else
%    SUCCESS = 0;
% end
SUCCESS = 1;

% Check if it was successful full computation
if SUCCESS
    try
        save(fullfile(toSaveDir, fileName), 'perturbation_struct');
    catch e
        disp(e);
        save(fullfile(toSaveDir, fileName), 'perturbation_struct', '-v7.3');
    end
    delete(fullfile(tempDir, '*.mat'));
    delete(fullfile(tempDir, 'info', '*.mat'));
    rmdir(fullfile(tempDir, 'info'));
    rmdir(fullfile(tempDir));
else
    fprintf('Make sure to fix the windows not computed!');
end
end