patients = {,...
%     'LA01_ICTAL', 'LA01_Inter', ...
%     'LA02_ICTAL', 'LA02_Inter', ...
%     'LA03_ICTAL', 'LA03_Inter', ...
%     'LA04_ICTAL', 'LA04_Inter', ...
%     'LA05_ICTAL', 'LA05_Inter', ...
    'LA09_ICTAL', 'LA09_Inter', ...
    'LA10_ICTAL', 'LA10_Inter', ...
    'LA11_ICTAL', 'LA11_Inter', ...
    'LA15_ICTAL', 'LA15_Inter', ...
    'LA16_ICTAL', 'LA16_Inter', ...
%     'LA07_ICTAL', 'LA07_Inter', ...
%     'LA12_ICTAL', 'LA12_Inter', ...
%     'LA13_ICTAL', 'LA13_Inter', ...
%     'LA14_ICTAL', 'LA14_Inter', ...
%     'LA17_ICTAL', 'LA17_Inter', ...
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
% data parameters to find correct directory
radius = 1.5;             % spectral radius of perturbation
winSize = 250;            % window size in milliseconds
stepSize = 125; 
filterType = 'notchfilter';  % adaptive, notch, or no
%     typeConnectivity = 'leastsquares'; 

% broadband filter parameters
typeTransform = 'fourier'; % morlet, or fourier
JOBTYPE = 1;

for iPat=1:length(patients)
    patient = patients{iPat};
    % run a computation on checking patients if there is missing data
    [toCompute, patWinsToCompute] = checkPatient(patient, rootDir, winSize, stepSize, filterType, radius, JOBTYPE);
     
    if toCompute
        for iWin=1:length(patWinsToCompute)
            winToCompute = patWinsToCompute(iWin);
            parallelComputeConnectivity(patient, winSize, stepSize, winToCompute);
        end
    end
end