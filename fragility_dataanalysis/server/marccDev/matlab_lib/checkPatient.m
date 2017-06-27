function [toCompute, patWinsToCompute] = checkPatient(patient, rootDir, winSize, stepSize, filterType);
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
    filterType = 'adaptive';
end

%- directory for the data stored
tempDir = fullfile(rootDir, 'server/marccDev/matlab_lib/tempData/', ...
    filterType, strcat('win', num2str(winSize), '_step', num2str(stepSize)), 'connectivity');

% mkdir(fullfile(tempDir, patient));

patDirExists = exist(fullfile(tempDir, patient), 'dir');

% initialize return variables
toCompute = 0;
patWinsToCompute = [];

if patDirExists
    % check if each directory has the right windows computed
    fileList = dir(fullfile(tempDir, patient, '*.mat'));
    fileList = {fileList(:).name};

    % get numWins needed
    numWins = getNumWins(patient, winSize, stepSize);

    % get the windows still needed to compute, if any
    winsToCompute = checkWindows(fileList, numWins);

    if ~isempty(winsToCompute)
        fprintf('Need to compute certain windows for %s still!\n', patient);
        patWinsToCompute = winsToCompute;
    end
else
    fprintf('Need to compute for %s still!\n', patient);
    toCompute = 1;
end