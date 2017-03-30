% function that writes to a text file the number of windows for 
% a specific patient/seizure recording dataset
function serverSetupComputation(patient, winSize, stepSize)
    if nargin == 0 % testing purposes
        patient='EZT007seiz001';
        patient ='pt1sz2';

        % window paramters
        radius = 1.5;
        winSize = 500; % 500 milliseconds
        stepSize = 500; 
        frequency_sampling = 1000; % in Hz
    end
    
    if nargin == 1
        winSize = 500;
        stepSize = 500;
    end
    
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

    addpath(genpath(fullfile(rootDir, '/fragility_library/')));
    addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
    addpath(rootDir);

    % set patientID and seizureID
    patient_id = [];
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
    %% DEFINE CHANNELS AND CLINICAL ANNOTATIONS
    %- Edit this file if new patients are added.
    [included_channels, ezone_labels, earlyspread_labels,...
        latespread_labels, resection_labels, frequency_sampling, ...
        center] ...
                = determineClinicalAnnotations(patient_id, seizure_id);
    patient_id = buffpatid;

    % set directory to find dataset
    dataDir = fullfile(rootDir, 'data', center);
        
    % to save temp text file data dir
    toSaveDir = fullfile(rootDir, 'server/devFragility/patientMeta/');
    fileName = fullfile(toSaveDir, strcat(patient, '.txt'));
    if ~exist(toSaveDir, 'dir')
        mkdir(toSaveDir);
    end
    
    %% EZT/SEEG PATIENTS
    if seeg
        patient_eeg_path = fullfile(dataDir, patient_id);
        patient = strcat(patient_id, seizure_id);
    else
        patient_eeg_path = fullfile(dataDir, patient);
    end
    patient_eeg_path
    patient

    % READ EEG FILE Mat File
    % files to process
    data = load(fullfile(patient_eeg_path, patient));
    eeg = data.data;
    
    %- compute number of windows there are based on length of eeg,
    %- winSize and stepSize
%     if winSize == stepSize
%         numWins = size(eeg,2) / stepSize;
%     else
%         numWins = size(eeg,2) / stepSize - 1;
%     end
    numWins = floor(size(eeg, 2) / stepSize - winSize/stepSize + 1);
    
    fid = fopen(fileName, 'w');
    fprintf(fid, '%i\n', numWins);
    fclose(fid);
end