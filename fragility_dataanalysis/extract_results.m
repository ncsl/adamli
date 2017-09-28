function [final_data, info] = extract_results(patient, winSize, stepSize, filterType, radius, reference)
if nargin == 0
    % data parameters to find correct directory
    patient = 'pt1sz2';
%     patient='JH103aw1';
%     patient = 'pt1aw1';
    radius = 1.5;             % spectral radius
    winSize = 250;            % 500 milliseconds
    stepSize = 125; 
    filterType = 'adaptivefilter';
    filterType = 'notchfilter';
    fs = 1000; % in Hz
    typeConnectivity = 'leastsquares';
    typeTransform = 'fourier';
    rejectThreshold = 0.3;
    reference = 'avgref';
end
    
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

% set patientID and seizureID
[~, patient_id, seizure_id, seeg] = splitPatient(patient);

[included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
    resection_labels, fs, center, success_or_failure] ...
        = determineClinicalAnnotations(patient_id, seizure_id);

% set directories
serverDir = fullfile(dataDir, '/serverdata/');

adjMatDir = fullfile(dataDir, 'serverdata/adjmats/', filterType, strcat('win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs)), patient, reference); % at lab
        
finalDataDir = fullfile(dataDir, strcat('/serverdata/pertmats/', filterType, '/win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)), patient, reference); % at lab

try
    final_data = load(fullfile(finalDataDir, ...
        strcat(patient, '_pertmats', reference, '.mat')));
catch e
    final_data = load(fullfile(finalDataDir, ...
        strcat(patient, '_pertmats_leastsquares_radius', num2str(radius), '.mat')));
end
final_data = final_data.perturbation_struct;

%% Extract metadata info
info = final_data.info;

end