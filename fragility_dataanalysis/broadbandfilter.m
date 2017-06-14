function timeWinsToReject = broadbandfilter(patient, typeTransform, winSize, stepSize, filterType)
% function: checkWindows
% By: Adam Li
% Date: 6/12/17
% Description: Checks the file list of computed windows and compares with
% the correct number of windows needed for this patient.
% 
% Input: 
% - fileList: cell array of all the files in this respective directory.
% Assuming each file name is <patient>_<meta>_<window>.mat
% - numWins: the total number of windows from 1:N that should be inside
% this directory
% Output:
% - vector of windows needed to compute

if nargin==0
    % Initialization
    %- 0 == no filtering
    %- 1 == notch filtering
    %- 2 == adaptive filtering
    patient='pt1sz2';
    filterType = 'notch';
    winSize = 250;
    stepSize = 125;
    typeTransform = 'fourier'; 
end

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

%- directory with the spectral data
spectDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/'), typeTransform, ...
        strcat(filterType, '_win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
        strcat(patient));
chanFiles = dir(fullfile(spectDir, '*.mat')); % get all the channel mat files
chanFiles = {chanFiles(:).name};
chanFiles = natsort(chanFiles);


%- if we are only looking at included channels
chanFiles = chanFiles(included_channels);
    

% loop over every channel to create a mask on time windows for every
% channel
for iChan=1:length(chanFiles)
    fileToLoad = fullfile(spectDir, chanFiles{iChan});
    data = load(fileToLoad);
    data = data.data;

    chanStr = data.chanStr;
    winSizeMS = data.winSizeMS;
    stepSizeMS = data.stepSizeMS;
    seizureStart = data.seizure_start;
    seizureEnd = data.seizure_end;
    timePoints = data.waveT;
    freqs = data.freqs;
    powerMatZ = data.powerMatZ;

    % get seizure marks in window
    seizureStartMark = seizureStart / stepSizeMS - (winSizeMS/stepSizeMS - 1);
    seizureEndMark = seizureEnd / stepSizeMS - (winSizeMS/stepSizeMS - 1);

    [numFreqs, numTimes] = size(powerMatZ);

    if iChan==1 % initialize return matrix
        timeWinsToReject = zeros(length(chanFiles), numTimes);
    end
    
    % define percentiles of rejection 
    lowperctile = 1;
    highperctile = 99;
    perctiles = zeros(numFreqs, 2);

    % time points to reject
    timeWinsToReject(iChan, :) = maskFilter(powerMatZ, freqs, highperctile, lowperctile);
end % end of loop through channels
end