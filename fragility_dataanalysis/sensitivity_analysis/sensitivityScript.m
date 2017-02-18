% script to perform sensitivity analysis for different electrodes removed
%- add libraries to path
addpath(genpath('../fragility_library/'));
addpath(genpath('../eeg_toolbox/'));
addpath('../');

%%- 0. Load in data for a wellperforming patient
patient = 'pt1sz2';

% set working directory
% data directories to save data into - choose one
eegRootDirWork = '/Users/liaj/Documents/MATLAB/paremap';     % work
% eegRootDirHome = '/Users/adam2392/Documents/MATLAB/Johns Hopkins/NINDS_Rotation';  % home
eegRootDirHome = '/Volumes/NIL_PASS/';
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/data';
% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirWork)), rootDir = eegRootDirWork;
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
dataDir = fullfile(rootDir, '/data/', center, patient);
% data = load(fullfile(dataDir, patient));

% strip the data of electrode(s)

%- location to save data
toSaveAdjDir = fullfile(rootDir, '/serverdata/adjmats', patient, strcat(patient, '_numelecs', N));


%%- 1. Run adjmat computation with data



%%- 2. then Run perturbation algorithm