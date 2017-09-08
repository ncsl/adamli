function [included_indices, excluded_indices] = splitChanIndices(all_labels, excluded_labels)
    if nargin == 0
        %% Set Root Directories
        % data directories to save data into - choose one
        eegRootDirHD = '/Volumes/NIL Pass/';
        eegRootDirHD = '/Volumes/ADAM LI/';
        eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
        eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
        % eegRootDirHome = 'test';
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

        % Determine which directory we're working with automatically
        if     ~isempty(dir(eegRootDirServer)), dataDir = eegRootDirServer;
        elseif ~isempty(dir(eegRootDirHD)), dataDir = eegRootDirHD;
        elseif ~isempty(dir(eegRootDirJhu)), dataDir = eegRootDirJhu;
        elseif ~isempty(dir(eegRootDirMarcc)), dataDir = eegRootDirMarcc;
        else   error('Neither Work nor Home EEG directories exist! Exiting'); end

        addpath(genpath(fullfile(rootDir, '/fragility_library/')));
        addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
        addpath(rootDir);
        
        patient = 'pt1sz2';
        % set patientID and seizureID
        [~, patient_id, seizure_id, seeg] = splitPatient(patient);

        %% DEFINE CHANNELS AND CLINICAL ANNOTATIONS
        %- Edit this file if new patients are added.
        [included_channels, ezone_labels, earlyspread_labels,...
            latespread_labels, resection_labels, frequency_sampling, ...
            center] ...
                    = determineClinicalAnnotations(patient_id, seizure_id);

        % set dir to find raw data files
        dataDir = fullfile(dataDir, '/data/', center);
        
        patient_eeg_path = fullfile(dataDir, patient);

        fprintf('Loading data...');
        % READ EEG FILE Mat File
        % files to process
        data = load(fullfile(patient_eeg_path, strcat(patient, '.mat')));
        eeg = data.data;
        labels = data.elec_labels;
        engelscore = data.engelscore;
        frequency_sampling = data.fs;
        outcome = data.outcome;
        seizure_eonset_ms = data.seizure_eonset_ms;
        seizure_eoffset_ms = data.seizure_eoffset_ms;
        seizure_conset_ms = data.seizure_conset_ms;
        seizure_coffset_ms = data.seizure_coffset_ms;
        fprintf('Loaded data...');
    end

    excluded_labels = {'P10', 'P8'
    
end