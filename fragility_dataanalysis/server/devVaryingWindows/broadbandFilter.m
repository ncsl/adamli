%
% Description
% 1. Take spectral power computed before and load in per channel
% 2. For each channel, compute a power distribution for each frequency
% 3. For each channel, go across time and look if there are frequencies in
% tails of the power distribution
% 4. apply thresholding
% 5. Return time points that are broadband noise affected

    % Initialization
    %- 0 == no filtering
    %- 1 == notch filtering
    %- 2 == adaptive filtering
    FILTER_RAW = 2; 
    winSize = 500;
    stepSize = 250;
    
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
    patient_id = buffpatid;
    
    % set directory to save computed data
    if FILTER_RAW == 1
        spectDir = fullfile(strcat('./serverdata/spectral_analysis/', typeTransform, '/notchharmonics_win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
    elseif FILTER_RAW == 2
        spectDir = fullfile(strcat('./serverdata/spectral_analysis/', typeTransform, '/adaptivefilter_win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
    else 
        spectDir = fullfile(strcat('./serverdata/spectral_analysis/', typeTransform, '/nofilter_', 'win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
    end
    
    % get all the spectral power files for this patient
    elecFiles = dir(fullfile(spectDir, '*.mat'));
    elecFiles = natsortfiles({elecFiles.name});
    
    %% Loop Through Channels and Apply Broadband Filter
    for iChan=1:length(elecFiles)
        
        
    end