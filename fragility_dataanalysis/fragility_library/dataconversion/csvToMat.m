patients = {,...
%      'pt1aw1', 'pt1aw2', ...
%     'pt1aslp1', 'pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', 'pt2aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
%     'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1' 'pt2sz3' 'pt2sz4', ...
%     'pt3sz2' 'pt3sz4', ...
%     'pt6sz3', 'pt6sz4', 'pt6sz5', ...
%     'pt8sz1' 'pt8sz2','pt8sz3',...
%     'pt10sz1', 'pt10sz2' 'pt10sz3', ...
%     'pt7sz19', 'pt7sz21', 'pt7sz22',...
%     'pt11sz1', 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt12sz1', 'pt12sz2', ...
%     'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
%     'pt14sz1' 'pt14sz2' 'pt14sz3',...
%     'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2','pt17sz3'...
%   'JH101sz1' 'JH101sz2' 'JH101sz3' 'JH101sz4',...
% 	'JH102sz1' 'JH102sz2' 'JH102sz3' 'JH102sz4' 'JH102sz5' 'JH102sz6',...
% 	'JH103sz1' 'JH103sz2' 'JH103sz3',...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
% 	'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
% 	'JH106sz1' 'JH106sz2' 'JH106sz3' 'JH106sz4' 'JH106sz5' 'JH106sz6',...
% 	'JH107sz1' 'JH107sz2' 'JH107sz3' 'JH107sz4' 'JH107sz5' 'JH107sz6' 'JH107sz7' 'JH107sz8' 'JH107sz8', 'JH107sz9'...
%     'JH108sz1', 'JH108sz2', 'JH108sz3', 'JH108sz4', 'JH108sz5', 'JH108sz6', 'JH108sz7',...
%     'UMMC001_sz1', 'UMMC001_sz2', 'UMMC001_sz3', ...
%     'UMMC002_sz1', 'UMMC002_sz2', 'UMMC002_sz3', ...
%     'UMMC003_sz1', 'UMMC003_sz2', 'UMMC003_sz3', ...
%     'UMMC004_sz1', 'UMMC004_sz2', 'UMMC004_sz3', ...
%     'UMMC005_sz1', 'UMMC005_sz2', 'UMMC005_sz3', ...
%     'UMMC006_sz1', 'UMMC006_sz2', 'UMMC006_sz3', ...
%     'UMMC007_sz1', 'UMMC007_sz2','UMMC007_sz3', ...
%     'UMMC008_sz1', 'UMMC008_sz2', 'UMMC008_sz3', ...
%     'UMMC009_sz1', 'UMMC009_sz2', 'UMMC009_sz3', ...
%     'JH103aslp1', 'JH103aw1', ...
%     'JH105aslp1', 'JH105aw1',...
%     'LA01_ICTAL', 'LA01_Inter', ...
%     'LA02_ICTAL', 'LA02_Inter', ...
%     'LA03_ICTAL', 'LA03_Inter', ...
%     'LA04_ICTAL', 'LA04_Inter', ...
%     'LA05_ICTAL', 'LA05_Inter', ...
%     'LA06_ICTAL', 'LA06_Inter', ...
%     'LA08_ICTAL', 'LA08_Inter', ...
%     'LA09_ICTAL', 'LA09_Inter', ...
%     'LA10_ICTAL', 'LA10_Inter', ...
%     'LA11_ICTAL', 'LA11_Inter', ...
%     'LA15_ICTAL', 'LA15_Inter', ...
%     'LA16_ICTAL', 'LA16_Inter', ...
    'LA07_ICTAL_1', 'LA07_ICTAL_2', 'LA07_ICTAL_3', ...
    'LA07_Inter', 'LA07_Inter_1','LA07_Inter_2','LA07_Inter_3',...
    'LA13_ICTAL_1', 'LA13_ICTAL_2', 'LA13_ICTAL_3', 'LA13_ICTAL_4','LA13_Inter', ...
%     'LA14_ICTAL', 'LA14_Inter', ...
%     'LA17_ICTAL', 'LA17_Inter', ...
};

close all;
% data directories to save data into - choose one
eegRootDirHD = '/Volumes/NIL Pass/';
eegRootDirHD = '/Volumes/ADAM LI/';
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';    % at JHU workstation
eegRootDirMarcctest = '/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/'; % at MARCC server
eegRootDirMarcc = '/scratch/groups/ssarma2/adamli/fragility_dataanalysis/';

% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
% elseif ~isempty(dir(eegRootDirHD)), rootDir = eegRootDirHD;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
elseif ~isempty(dir(eegRootDirMarcc)), rootDir = eegRootDirMarcc;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

% Determine which data directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), dataDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHD)), dataDir = eegRootDirHD;
elseif ~isempty(dir(eegRootDirJhu)), dataDir = eegRootDirJhu;
elseif ~isempty(dir(eegRootDirMarcc)), dataDir = eegRootDirMarcc;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

% load in clinical annotations mat struct file
clinicalFile = fullfile(dataDir, 'data/clinicalData.mat');
load(clinicalFile);

for iPat=1:length(patients)
    patient = patients{iPat};
    
    [~, patient_id, seizure_id, seeg] = splitPatient(patient);
    
    [included_channels, ezone_labels, earlyspread_labels, latespread_labels, resection_labels, frequency_sampling, center] ...
        = determineClinicalAnnotations(patient_id, seizure_id);
    
    dataDir = fullfile(dataDir, '/data/', center);

    %% NIH, JHU PATIENTS
    %- set file path for the patient file 
    patient_eeg_path = fullfile(dataDir, patient);
    patient_file_path = fullfile(dataDir, patient, strcat(patient, '.csv'));

    %- load in the clinical data for this patient
    patientmeta = clinicaldata.(patient);
    fs = patientmeta.frequency;
    seizure_eonset_ms = patientmeta.seizure_eonset_ms;
    seizure_eoffset_ms = patientmeta.seizure_eoffset_ms;
    seizure_conset_ms = patientmeta.seizure_conset_ms;
    seizure_coffset_ms = patientmeta.seizure_coffset_ms;
    number_of_samples = patientmeta.recording_duration_sec * fs;
    outcome = patientmeta.outcome;
    engelscore = patientmeta.engelscore;
    num_channels = patientmeta.numChans;

    % READ EEG FILE
    % files to process
    f = dir([patient_eeg_path '/*eeg.csv']);
    patient_file_names = cell(1, length(f));
    for iChan=1:length(f)
        patient_file_names{iChan} = f(iChan).name;
    end
    patient_files = containers.Map(patient_file_names, number_of_samples)

    % extract labels
    patient_label_path = fullfile(dataDir, patient, strcat(patient, '_labels.csv'));
    fid = fopen(patient_label_path); % open up labels to get all the channels
    labels = textscan(fid, '%s', 'Delimiter', ',');
    labels = labels{:}; 
    fclose(fid);
    elec_labels = upper(strtrim(labels)); 
    
    %- Extract EEG and Perform Analysis
    filename = patient_file_names{1};
    num_values = patient_files(patient_file_names{1});
    % extract eeg 
    eeg = csv2eeg(patient_eeg_path, filename, num_values, num_channels);
    data = eeg;

    varinfo = whos('data', 'elec_labels', 'fs', 'seizure_eonset_ms', 'seizure_eoffset_ms', ...
            'seizure_conset_ms', 'seizure_coffset_ms', 'outcome', 'engelscore');
    if sum([varinfo.bytes]) < 2^31
        save(fullfile(patient_eeg_path, patient), ...
            'data', 'elec_labels', 'fs', 'seizure_eonset_ms', 'seizure_eoffset_ms', ...
            'seizure_conset_ms', 'seizure_coffset_ms', 'outcome', 'engelscore');
    else
        save(fullfile(patient_eeg_path, patient), ...
            'data', 'elec_labels', 'fs', 'seizure_eonset_ms', 'seizure_eoffset_ms', ...
            'seizure_conset_ms', 'seizure_coffset_ms', 'outcome', 'engelscore', '-v7.3');
    end

    % check if the eeg and labels are correct sizes 
    % given the included channels
    if length(labels(included_channels)) ~= size(eeg(included_channels,:),1)
        disp('Something wrong here...!!!!');
    end
end