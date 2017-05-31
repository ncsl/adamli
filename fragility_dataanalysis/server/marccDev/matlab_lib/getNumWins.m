function numWins = getNumWins(patient, winSize, stepSize)
    %% set working directory
    eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
    eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
    eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';    % at JHU workstation
    eegRootDirMarcc = '/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/'; % at MARCC server
    % eegRootDirMarcc = '/scratch/groups/ssarma2/adamli/fragility_dataanalysis/';
    % Determine which directory we're working with automatically
    if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
    elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
    elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
    elseif ~isempty(dir(eegRootDirMarcc)), rootDir = eegRootDirMarcc;
    else   error('Neither Work nor Home EEG directories exist! Exiting'); end

    addpath(genpath(fullfile(rootDir, '/fragility_library/')));
    addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
    addpath(rootDir);
    
    %- get patient and seizure id and determine if it is a seeg patient or not
    [patient_id, seizure_id, is_seeg] = getPatAndSeizId(patient);
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

    % set directory to find dataset
    dataDir = fullfile(rootDir, 'data', center);
            
    %% EZT/SEEG PATIENTS
    if is_seeg
        patient_eeg_path = fullfile(dataDir, patient_id);
        patient = strcat(patient_id, seizure_id);
    else
        patient_eeg_path = fullfile(dataDir, patient);
    end
    
    % READ EEG FILE Mat File
    % files to process
    data = load(fullfile(patient_eeg_path, patient));
    eeg = data.data;
    numSampsInWin = winSize * fs / 1000;
    numSampsInStep = stepSize * fs / 1000;
    
    numWins = floor(size(eeg, 2) / numSampsInStep - numSampsInWin/numSampsInStep + 1);
end