% function that writes to a text file the number of windows for 
% a specific patient/seizure recording dataset
function serverSetupComputation(patient, winSize, stepSize)
    addpath(genpath('../../fragility_library/'));
    addpath(genpath('../../eeg_toolbox/'));
    addpath('../../');
    IS_SERVER = 1;
    
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
    
%     IS_INTERICTAL = 1; % need to change per run of diff data
    TYPE_CONNECTIVITY = 'leastsquares';
    l2regularization = 0;

    % to save temp text file data dir
    toSaveDir = './patientMeta/';
    fileName = fullfile(toSaveDir, strcat(patient, '.txt'));
    if ~exist(toSaveDir, 'dir')
        mkdir(toSaveDir);
    end
    
    % set directory to find dataset
    dataDir = '../../data/';
    patient
    
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
        dataDir= './data/interictal_data/';
        if IS_SERVER
            dataDir = '../../data/interictal_data/';
        end
    end
   
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'aw')-1);
        seizure_id = patient(strfind(patient, 'aw'):end);
        
        dataDir= './data/interictal_data/';
        if IS_SERVER
            dataDir = '../../data/interictal_data/';
        end
    end
    
%     dataDir = '/Volumes/NIL_PASS/data/interictal_data/';
    %% DEFINE CHANNELS AND CLINICAL ANNOTATIONS
    %- Edit this file if new patients are added.
    [included_channels, ezone_labels, earlyspread_labels, latespread_labels, resection_labels, frequency_sampling] ...
                = determineClinicalAnnotations(patient_id, seizure_id);

    % put clinical annotations into a struct
    clinicalLabels = struct();
    clinicalLabels.ezone_labels = ezone_labels;
    clinicalLabels.earlyspread_labels = earlyspread_labels;
    clinicalLabels.latespread_labels = latespread_labels;
    clinicalLabels.resection_labels = resection_labels;

    %% EZT/SEEG PATIENTS
    if seeg
        patient_eeg_path = strcat(dataDir, 'Seiz_Data/', patient_id);
    else
        patient_eeg_path = strcat(dataDir, patient);
    end
    
    % READ EEG FILE Mat File
    % files to process
    data = load(fullfile(patient_eeg_path, patient));
    eeg = data.data;
    labels = data.elec_labels;
    onset_time = data.seiz_start_mark;
    offset_time = data.seiz_end_mark;
    recording_start = 0; % since they dont' give absolute time of starting the recording
    seizureStart = (onset_time - recording_start); % time seizure starts
    seizureEnd = (offset_time - recording_start); % time seizure ends
    recording_duration = size(data.data, 2);
    num_channels = size(data.data, 1);
    
    
    % check included channels length and how big eeg is
    if length(labels(included_channels)) ~= size(eeg(included_channels,:),1)
            disp('Something wrong here...!!!!');
    end

    if frequency_sampling ~=1000
        eeg = eeg(:, 1:(frequency_sampling/1000):end);
        seizureStart = seizureStart * frequency_sampling/1000;
        seizureEnd = seizureEnd * frequency_sampling/1000;
        winSize = winSize*frequency_sampling/1000;
        stepSize = stepSize*frequency_sampling/1000;
    end
    
    % apply included channels to eeg and labels
    if ~isempty(included_channels)
        eeg = eeg(included_channels, :);
        labels = labels(included_channels);
    end
    
    %- compute number of windows there are based on length of eeg,
    %- winSize and stepSize
    numWins = size(eeg,2) / stepSize - 1;
    
    fid = fopen(fileName, 'w');
    fprintf(fid, '%i\n', numWins);
    fclose(fid);
end