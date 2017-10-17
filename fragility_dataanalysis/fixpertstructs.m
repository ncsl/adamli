% script to fix the seizureonset times and such

load('/Volumes/ADAM LI/data/clinicalData.mat');
patients = {, ...
%     'LA02_ICTAL', ... 'LA02_Inter', ...
%     'LA04_ICTAL', ...'LA04_Inter', ...
%     'LA06_ICTAL', ...'LA06_Inter', ...
%     'LA08_ICTAL', ...'LA08_Inter', ...
%     'LA10_ICTAL', ...'LA10_Inter', ...
    'LA15_ICTAL', ...'LA15_Inter', ...
%     'LA16_ICTAL', ...'LA16_Inter', ...
};

% parameters for the computed data
perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);

% parameters
winSize = 250;
stepSize = 125;
filterType = 'notchfilter';
% filterType = 'adaptivefilter';
radius = 1.5;
typeConnectivity = 'leastsquares';
typeTransform = 'fourier';
rejectThreshold = 0.3;
reference = '';

for ipat=1:length(patients)
    close all;
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

    % get the current patient
    patient = patients{ipat};
    
    % set patientID and seizureID
    [~, patient_id, seizure_id, seeg] = splitPatient(patient);

    [included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
        resection_labels, fs, center, success_or_failure] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
    
    % where the perturbation results are saved
    resultsDir = fullfile(dataDir, strcat('/serverdata/pertmats/', filterType, '/win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)), patient, reference); % at lab
    
    [final_data, info] = extract_results(patient, resultsDir, reference, radius);

    % extract actual data structures
%     pertDataStruct = final_data.(perturbationType);
    info = final_data.info;
    
    % get the new meta data for this patient
    patmeta = clinicaldata.(patient);
    timePoints = info.rawtimePoints;
    
    % get the updated seiuzre onset/offsets
    seizure_eonset_ms = patmeta.seizure_eonset_ms;
    seizure_eoffset_ms = patmeta.seizure_eoffset_ms;
    
    %- compute seizureStart/End Mark in time windows
    seizureStartMark = find(timePoints(:,2) - seizure_eonset_ms * fs / 1000 == 0);
    seizureEndMark = find(timePoints(:,2) - seizure_eoffset_ms * fs / 1000 == 0);
    
    final_data.info.seizure_estart_ms = seizure_eonset_ms;
    final_data.info.seizure_eend_ms = seizure_eoffset_ms;
    final_data.info.seizure_estart_mark = seizureStartMark;
    final_data.info.seizure_eend_mark = seizureEndMark;
    perturbation_struct = final_data;
    
    varinfo = whos('perturbation_struct');
    if varinfo.bytes < 2^31
        save(fullfile(resultsDir, strcat(patient, '_pertmats', reference, '.mat')), 'perturbation_struct');
    else 
        save(fullfile(resultsDir, strcat(patient, '_pertmats', reference, '.mat')), 'perturbation_struct', '-v7.3');
    end    
end