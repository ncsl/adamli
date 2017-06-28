patients = {...,
     'pt1aw1','pt1aw2', ...
%     'pt2aw2', 'pt2aslp2',...
%     'pt1aslp1','pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', 'pt2aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
%     'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1' 'pt2sz3' , 'pt2sz4', ...
%     'pt3sz2' 'pt3sz4', ...
%     'pt6sz3', 'pt6sz4', 'pt6sz5',...
%     'pt7sz19', 'pt7sz21', 'pt7sz22',...
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1','pt10sz2' 'pt10sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt12sz1', 'pt12sz2', ...
%     'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
%     'pt14sz1' 'pt14sz2' 'pt14sz3'  'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2', 'pt17sz3', ...
    
%     'Pat2sz1p', 'Pat2sz2p', 'Pat2sz3p', ...
%     'Pat16sz1p', 'Pat16sz2p', 'Pat16sz3p', ...
    
%     'UMMC001_sz1', 'UMMC001_sz2', 'UMMC001_sz3', ...
%     'UMMC002_sz1', 'UMMC002_sz2','UMMC002_sz3', ...
%     'UMMC003_sz1', 'UMMC003_sz2', 'UMMC003_sz3', ...
%     'UMMC004_sz1', 'UMMC004_sz2', 'UMMC004_sz3', ...
%     'UMMC005_sz1', 'UMMC005_sz2', 'UMMC005_sz3', ...
%     'UMMC006_sz1', 'UMMC006_sz2', 'UMMC006_sz3', ...
%     'UMMC007_sz1', 'UMMC007_sz2','UMMC007_sz3', ...
%     'UMMC008_sz1', 'UMMC008_sz2', 'UMMC008_sz3', ...
%     'UMMC009_sz1','UMMC009_sz2', 'UMMC009_sz3', ...

%     'JH103aw1', 'JH103aslp1', 'JH105aw1', 'JH105aslp1', ...
%     'JH101sz1' 'JH101sz2' 'JH101sz3' 'JH101sz4',...
% 	'JH102sz1' 'JH102sz2' 'JH102sz3' 'JH102sz4' 'JH102sz5' 'JH102sz6',...
% 	'JH103sz1' 'JH103sz2' 'JH103sz3',...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
% 	'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
% 	'JH106sz1' 'JH106sz2' 'JH106sz3' 'JH106sz4' 'JH106sz5' 'JH106sz6',...
% 	'JH107sz1' 'JH107sz2' 'JH107sz3' 'JH107sz4' 'JH107sz5' 'JH107sz6' 'JH107sz7' 'JH107sz8' 'JH107sz9',...
%    'JH108sz1', 'JH108sz2', 'JH108sz3', 'JH108sz4', 'JH108sz5', 'JH108sz6', 'JH108sz7',...
    };

close all;

%% Set Root Directories
% data directories to save data into - choose one
eegRootDirHD = '/Volumes/NIL Pass/';
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';    % at JHU workstation
eegRootDirMarcctest = '/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/'; % at MARCC server
eegRootDirMarcc = '/scratch/groups/ssarma2/adamli/fragility_dataanalysis/';

% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
elseif ~isempty(dir(eegRootDirMarcc)), rootDir = eegRootDirMarcc;
elseif ~isempty(dir(eegRootDirHD)), rootDir = eegRootDirHD;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

%% Set Parameters
% set perturbation type to plot
perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);

% data parameters to find correct directory
radius = 1.5;             % spectral radius of perturbation
winSize = 250;            % window size in milliseconds
stepSize = 125; 
filterType = 'notch';  % adaptive, notch, or no
typeConnectivity = 'leastsquares'; 

% broadband filter parameters
typeTransform = 'fourier'; % morlet, or fourier

% set figure directory to save plots
figDir = fullfile(rootDir, '/figures', 'degreeOfAgreement', ...
    strcat(filterType, 'filter'), ...
    strcat('perturbation', perturbationType, '_win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)));

pertDir = fullfile(rootDir, 'serverdata', 'perturbationmats', ...
        strcat(filterType, 'filter'));

%% Run Through And Plot
for iPat=1:length(patients)
    patient = patients{iPat};
        
    % set patientID and seizureID
    patient_id = patient(1:strfind(patient, 'seiz')-1);
    seizure_id = strcat('_', patient(strfind(patient, 'seiz'):end));
    seeg = 1;
    INTERICTAL = 0;
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'sz')-1);
        seizure_id = patient(strfind(patient, 'sz'):end);
        seeg = 0;
    end
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'aslp')-1);
        seizure_id = patient(strfind(patient, 'aslp'):end);
        seeg = 0;
        INTERICTAL = 1;
    end
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'aw')-1);
        seizure_id = patient(strfind(patient, 'aw'):end);
        seeg = 0;
        INTERICTAL = 1;
    end

    buffpatid = patient_id;
    if strcmp(patient_id(end), '_')
        patient_id = patient_id(1:end-1);
    end
    
    [included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
        resection_labels, fs, center, success_or_failure] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
    
    % set where this patient's computed data is
    patResultsDir = fullfile(pertDir, ...
        strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)), ...
        patient);
    
    spectDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/'), typeTransform, ...
        strcat(filterType, 'filter'), strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
        patient);
    
    % notch and updated directory
    spectDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/'), typeTransform, ...
        strcat(filterType, '_win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
        patient);
    
    % load computed results
    final_data = load(fullfile(patResultsDir, ...
        strcat(patient, '_pertmats_', lower(typeConnectivity), '_radius', num2str(radius), '.mat')));
    final_data = final_data.perturbation_struct;
    
    % load meta data
    info = final_data.info;
    
    % load perturbation data
    pertDataStruct = final_data.(perturbationType);
     
    %- extract clinical data
    ezone_labels = info.ezone_labels;
    earlyspread_labels = info.earlyspread_labels;
    latespread_labels = info.latespread_labels;
    resection_labels = info.resection_labels;
    included_labels = info.all_labels;
    seizure_estart_ms = info.seizure_estart_ms;
    seizure_estart_mark = info.seizure_estart_mark;
    seizure_eend_ms = info.seizure_eend_ms;
    seizure_eend_mark = info.seizure_eend_mark;
    num_channels = length(info.all_labels);
    
    %- set global variable for plotting
    seizureStart = seizure_estart_ms;
    seizureEnd = seizure_eend_ms;
    seizureMarkStart = seizure_estart_mark;
    
    clinicalIndices = getClinicalIndices(included_labels, ezone_labels,...
                    earlyspread_labels, latespread_labels, resection_labels);
    
    % min norm perturbation, fragility matrix, minmax fragility matrix
    minNormPertMat = pertDataStruct.minNormPertMat;
    fragilityMat = pertDataStruct.fragilityMat;
    minmaxFragility = min_max_scale(minNormPertMat); % perform min max scaling
    
    % broadband filter for this patient
    timeWinsToReject = broadbandfilter(patient, typeTransform, winSize, stepSize, filterType, spectDir);
    
    
    
end
