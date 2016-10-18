function computeDOAStatistic(patient_id, seizure_id, stats_args, clinicalLabels)
close all;
    
%% 0: Initialize Variables, EZONE, EarlySpread and LateSpread Indices
if nargin == 0
    patient_id = 'pt1';
    seizure_id = 'sz2';
    radius = 1.1;
    w_space = linspace(-1, 1, 101);
    perturbationType = 'R';
    winSize = 500;
    stepSize = 500;
    frequency_sampling = 500;
    included_channels = 0;
    patient = strcat(patient_id, seizure_id);

    toSaveWeightsDir = fullfile('./figures/', strcat(perturbationType, '_electrode_weights'), strcat(patient, num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)));
    if ~exist(toSaveWeightsDir, 'dir')
        mkdir(toSaveWeightsDir);
    end
end
patient = strcat(patient_id, seizure_id);


%% 0: Extract Vars and Initialize Parameters
% perturbationType = stats_args.perturbationType;
% w_space = stats_args.w_space;
% radius = stats_args.radius;
% adjDir = stats_args.adjDir;
% toSaveFinalDataDir = stats_args.toSaveFinalDataDir;
% included_channels = stats_args.included_channels;
% num_channels = stats_args.num_channels
% frequency_sampling = stats_args.frequency_sampling;

%- grab clinical annotations
% ezone_labels = clinicalLabels.ezone_labels;
% earlyspread_labels = clinicalLabels.earlyspread_labels;
% latespread_labels = clinicalLabels.latespread_labels;

% read in weights file
weightfiles = dir([toSaveWeightsDir '/*.csv']);
weightfiles = {weightfiles.name};
      
formatSpec = '%s%f%[^\n\r]';
delimiter = ',';
%% Open the text file.
fileID = fopen(fullfile(toSaveWeightsDir, weightfiles{1}),'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Allocate imported array to column variable names
electrodes = dataArray{:, 1};
weights = dataArray{:, 2};

num_CROI = length(ezone_labels);
num_EROI = length(weights);

% find intersection of ezone_labels and weights

% find intersection of commplement(ezone_labels) and weights

% detection_stat = 
   