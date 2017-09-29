function [toCompute, patWinsToCompute] = checkPatient(patient, patTempDir, resultsDir, winSize, stepSize)
% function: checkPatient
% By: Adam Li
% Date: 6/12/17
% Description: Checks the patient and checks if there
% are correctly computed windows in each patient directory
% 
% Input: 
% - patientList: cell array of all the patients is example: {'pt1sz2',
% 'pt10sz3'}
% - computedDir: the directory to check for all the computed patients
% Output:
% - toCompute: either 0, or 1 if the patient still needs to be computed
% - patWinsToCompute: a vector of windows still needed to be computed by
% the server
if nargin == 0
    patient = 'pt1sz2';
    rootDir = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/server/marccDev/matlab_lib/tempData/adaptivefilter/win250_step125/connectivity/';
    winSize = 250;
    stepSize = 125;
    filterType = 'adaptivefilter';
    reference = 'avgref';
    numToRemove = 2;
end

%% Set Directories
% data directories to save data into - choose one
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';    % at JHU workstation
eegRootDirMarcc = '/scratch/groups/ssarma2/adamli/fragility_dataanalysis/';

% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), eegrootDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHome)), eegrootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), eegrootDir = eegRootDirJhu;
elseif ~isempty(dir(eegRootDirMarcc)), eegrootDir = eegRootDirMarcc;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end
addpath(eegrootDir);

%% Check This Patient's Temporary and Results Directories 
% get numWins needed
numWins = getNumWins(patient, winSize, stepSize);
        
% check if temporary data directory exists
tempDirExists = exist(patTempDir, 'dir');

% check if results has data and if the temp results dir has data
dataDirFiles = dir(fullfile(resultsDir, '*.mat'));
dataDirExists = ~isempty(dataDirFiles);
 
% initialize return variables
toCompute = 0;
patWinsToCompute = [];

if 7==tempDirExists && ~dataDirExists  % temp dir exists, but merged data dir doensn't exist
    % check if each directory has the right windows computed
    fileList = dir(fullfile(patTempDir, '*.mat'));
    fileList = {fileList(:).name};
   
    fileList = natsortfiles(fileList);
    
    % get the windows still needed to compute, if any
    winsToCompute = checkWindows(fileList, numWins);

    if ~isempty(winsToCompute)
        toCompute = 1;
        fprintf('The directory is: %s\n', patTempDir);
        fprintf('Need to compute certain windows for %s still!\n', patient);
        fprintf('Number of wins needed are %s vs %s\n', num2str(numWins), num2str(length(fileList)));
        patWinsToCompute = winsToCompute;
    end
elseif 7~=tempDirExists && ~dataDirExists % temp and merged dir don't exist
    fprintf('Need to compute for %s still!\n', patient);
    toCompute = 1;
else % tempDirExists ~=7 and dataDirFiles is not empty
    toCompute = -1;
    fprintf('%s directory already exists!\n', patient);
end