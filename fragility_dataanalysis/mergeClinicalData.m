% script to run to merge all clinical data into 1 data structure.
% data directories to save data into - choose one
eegRootDirHD = '/Volumes/NIL Pass/';
eegRootDirHD = '/Volumes/ADAM LI/';
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
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

% Determine which data directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), dataDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHD)), dataDir = eegRootDirHD;
elseif ~isempty(dir(eegRootDirJhu)), dataDir = eegRootDirJhu;
elseif ~isempty(dir(eegRootDirMarcc)), dataDir = eegRootDirMarcc;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

dataDir = fullfile(dataDir, 'data');

nihFile = fullfile(dataDir, 'nihclinicalData.mat');
ummcFile = fullfile(dataDir, 'ummcclinicalData.mat');
jhuFile = fullfile(dataDir, 'jhuclinicalData.mat');
ccFile = fullfile(dataDir, 'ccclinicalData.mat');

patients = {};
nihdata = load(nihFile);
ummcdata = load(ummcFile);
jhudata = load(jhuFile);
ccdata = load(ccFile);
% patients = cell(length(fieldnames(nihdata.clinicaldata)) + length(fieldnames(ummcdata.clinicaldata)), 1);
patients = vertcat(fieldnames(nihdata.clinicaldata), fieldnames(ummcdata.clinicaldata),...
    fieldnames(jhudata.clinicaldata), fieldnames(ccdata.clinicaldata));

clinicaldata = struct();
% for each identifier
for id=1:length(patients)
    patient = patients{id};
    
    if strfind(patient, 'pt')
        clinicaldata.(patient) = nihdata.clinicaldata.(patient);
    elseif strfind(patient, 'UMMC')
        clinicaldata.(patient) = ummcdata.clinicaldata.(patient);
    elseif strfind(patient, 'JH')
        clinicaldata.(patient) = jhudata.clinicaldata.(patient);
    else 
        clinicaldata.(patient) = ccdata.clinicaldata.(patient);
    end
end

save(fullfile(dataDir, 'clinicalData.mat'), 'clinicaldata');