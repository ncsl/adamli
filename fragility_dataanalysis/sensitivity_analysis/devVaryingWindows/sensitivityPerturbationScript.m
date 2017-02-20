function sensitivityPerturbationScript(patient, numRemove)
% script to perform sensitivity analysis for different electrodes removed
%- add libraries to path
addpath(genpath('../../fragility_library/'));
addpath(genpath('../../eeg_toolbox/'));
addpath('../../');

if nargin==0
    patient = 'pt1sz2';
    numRemove = 2;
end
% fprintf(patient);
% fprintf(numRemove);

%%- 0. Load in data for a wellperforming patient
% patient = 'pt1sz2';
TYPE_CONNECTIVITY = 'leastsquares';
winSize = 500;
stepSize = 500;
APPLY_FILTER = 0;
BP_FILTER_RAW = 1;
l2regularization = 0;
% perturbation analysis parameters
perturbationTypes = ['C', 'R'];
radius = 1.5;
w_space = linspace(-radius, radius, 51);


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

[included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
    resection_labels, frequency_sampling, center] ...
        = determineClinicalAnnotations(patient_id, seizure_id);
        
%- load in data dir of patient
adjMatDir = fullfile(rootDir, 'serverdata/', 'adjmats', patient, strcat(patient, '_numelecs', num2str(numRemove)));

%- location to save data
toSavePertDir = fullfile(rootDir, '/serverdata/adjmats', patient, strcat(patient, '_numelecs', num2str(numRemove)));
if ~exist(toSavePertDir, 'dir')
    mkdir(toSavePertDir);
end

fileName = strcat(patient_id, seizure_id, '_adjmats_leastsquares.mat');
data = load(fullfile(adjMatDir, fileName));
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

adjMats = data.adjMats;
[T, N, ~] = size(adjMats);

seizureMarkStart = seizure_start / winSize;
if seeg
    seizureMarkStart = (seizure_start-1)/winSize;
end
    
 [T, N, ~] = size(adjMats);
    
for j=1:length(perturbationTypes)
    % initialize matrices to store
    minNormPerturbMat = zeros(N,T);
    fragilityMat = zeros(N,T);
    del_table = cell(N, T);

    perturbationType = perturbationTypes(j);
    % save the perturbation results
    filename = strcat(patient, '_', perturbationType, 'perturbation_', ...
            lower(TYPE_CONNECTIVITY), '_radius', num2str(radius), '.mat');

    perturb_args = struct();
    perturb_args.perturbationType = perturbationType;
    perturb_args.w_space = w_space;
    perturb_args.radius = radius;

    parfor iTime=1:T
        adjMat = squeeze(adjMats(iTime,:,:));

        [minNormPert, del_vecs, ERRORS] = minNormPerturbation(patient, adjMat, perturb_args);

        % store results
        minNormPerturbMat(:, iTime) = minNormPert;
        del_table(:, iTime) = del_vecs;

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

