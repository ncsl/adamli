patients={     'pt1aw1', 'pt1aw2', ...
    'pt1aslp1', 'pt1aslp2', ...
    'pt2aw1', 'pt2aw2', ...
    'pt2aslp1', 'pt2aslp2', ...
    'pt3aw1', ...
    'pt3aslp1', 'pt3aslp2', ...
    'pt1sz2', 'pt1sz3', 'pt1sz4',...
    'pt2sz1' 'pt2sz3' 'pt2sz4', ...
    'pt3sz2' 'pt3sz4', ...
    'pt6sz3', 'pt6sz4', 'pt6sz5', ...
    'pt8sz1' 'pt8sz2','pt8sz3',...
    'pt10sz1', 'pt10sz2' 'pt10sz3', ...
    'pt7sz19', 'pt7sz21', 'pt7sz22',...
    'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
    'pt14sz1' 'pt14sz2' 'pt14sz3',...
    'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
    'pt16sz1' 'pt16sz2' 'pt16sz3',...
    'pt1sz4',...
    'pt6sz3', 'pt6sz4', 'pt6sz5', ...
    'pt8sz1' 'pt8sz2','pt8sz3',...
    'pt7sz21', 'pt13sz5',...
    'pt14sz1' 'pt14sz2' 'pt14sz3',...
    'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
    'pt16sz1' 'pt16sz2' 'pt16sz3',...
    };


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

% plotting parameters
FONTSIZE = 20;

% set figure directory to save plots
figDir = fullfile(rootDir, '/figures', 'fragilityStats', ...
    strcat(filterType), ...
    strcat('perturbation', perturbationType, '_win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)));

if ~exist(figDir, 'dir')
    mkdir(figDir);
end

for iPat=1:length(patients)
    patient = patients{iPat};
    
    %% 1. Extract Data
    % set patientID and seizureID and extract relevant clinical meta data
    [~, patient_id, seizure_id, seeg] = splitPatient(patient);
    [included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
        resection_labels, fs, center, success_or_failure] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
        
    % perturbation directory for this patient
    pertDir = fullfile(dataDir, 'serverdata', 'pertmats', ...
        strcat(filterType), ...
        strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)));

    % notch and updated spectral analysis directory
    spectDir = fullfile(dataDir, strcat('/serverdata/spectral_analysis/'), typeTransform, ...
        strcat(filterType, '_win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
        patient);

    % extract data - load computed results
    try
        final_data = load(fullfile(pertDir, ...
            patient,...
            strcat(patient, '_pertmats', '.mat')));
    catch e
        final_data = load(fullfile(pertDir, ...
            patient, ...
            strcat(patient, '_pertmats_leastsquares_radius', num2str(radius), '.mat')));
    end
    final_data = final_data.perturbation_struct;

    % load meta data
    info = final_data.info;
    included_labels = info.all_labels;
       
    features_struct = load(fullfile(figDir, 'interictal', strcat(patient, '_fragilitystats.mat')));
    features_struct.included_labels = included_labels;
    
%     % create feature vector struct
%     patient = features_struct.patient;
%     features_struct.cfvar_time = cfvar_time;
%     features_struct.cfvar_chan = cfvar_chan;
%     
% %     features_struct.precfvar_chan = precfvar_chan;
% %     features_struct.postcfvar_chan = postcfvar_chan;
% %     features_struct.post20cfvar_chan = post20cfvar_chan;
% %     features_struct.post30cfvar_chan = post30cfvar_chan;
% %     features_struct.post40cfvar_chan = post40cfvar_chan;
% %     features_struct.post50cfvar_chan = post50cfvar_chan;
%         
% 
%     features_struct.max_frag = max_frag;
%     features_struct.min_frag = min_frag;
%     features_struct.high_frag = high_frag;
%     features_struct.ez_asymmetry = ez_asymmetry;
%     features_struct.resected_asymmetry = resected_asymmetry;
%     features_struct.network_fragility = network_fragility;
    
    save(fullfile(figDir, strcat(patient, '_fragilitystats.mat')), 'features_struct');
end