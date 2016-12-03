% FUNCTION: computeConnectivity
%
% Inputs:
% 
% Outputs:
function computeConnectivity(patient_id, seizure_id, eeg, clinicalLabels, adj_args)
   
% add libraries of functions
addpath(genpath('/Users/adam2392/Dropbox/eeg_toolbox'));
addpath(genpath('/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/eeg_toolbox/'));

% extract arguments and clinical annotations
BP_FILTER_RAW = adj_args.BP_FILTER_RAW; % apply notch filter or not?
frequency_sampling = adj_args.frequency_sampling; % frequency that this eeg data was sampled at
winSize = adj_args.winSize;
stepSize = adj_args.stepSize;
timeRange = adj_args.timeRange;
toSaveAdjDir = adj_args.toSaveAdjDir;
seizureStart = adj_args.seizureStart; % time seizure starts
seizureEnd = adj_args.seizureEnd; % time seizure ends
included_channels = adj_args.included_channels;
labels = adj_args.labels;
l2regularization = adj_args.l2regularization;
num_channels = adj_args.num_channels;

TYPE_CONNECTIVITY = adj_args.TYPE_CONNECTIVITY;
LEASTSQUARES = adj_args.connectivity.LEASTSQUARES;
CORRELATION = adj_args.connectivity.CORRELATION;
SPEARMAN = adj_args.connectivity.SPEARMAN;
PEARSON = adj_args.connectivity.PEARSON;

% set options for connectivity measurements
OPTIONS.l2regularization = l2regularization;
OPTIONS.SPEARMAN = SPEARMAN;
OPTIONS.PEARSON = PEARSON;

ezone_labels = clinicalLabels.ezone_labels;
earlyspread_labels = clinicalLabels.earlyspread_labels;
latespread_labels = clinicalLabels.latespread_labels;
resection_labels = clinicalLabels.resection_labels;

% patient identification
patient = strcat(patient_id, seizure_id); 

%- apply a bandpass filter raw data? (i.e. pre-filter the wave?)
if BP_FILTER_RAW==1,
    preFiltFreq      = [1 499];   %[1 499] [2 250]; first bandpass filter data from 1-499 Hz
    preFiltType      = 'bandpass';
    preFiltOrder     = 2;
    preFiltStr       = sprintf('%s filter raw; %.1f - %.1f Hz',preFiltType,preFiltFreq);
    preFiltStrShort  = '_BPfilt';
else
    preFiltFreq      = []; %keep this empty to avoid any filtering of the raw data
    preFiltType      = 'stop';
    preFiltOrder     = 1;
    preFiltStr       = 'Unfiltered raw traces';
    preFiltStrShort  = '_noFilt';
end

% apply band notch filter to eeg data
eeg = buttfilt(eeg,[59.5 60.5], frequency_sampling,'stop',1);

% set stepsize and window size to reflect sampling rate (milliseconds)
stepSize = stepSize * frequency_sampling/1000; 
winSize = winSize * frequency_sampling/1000;

% paramters describing the data to be saved
% window parameters - overlap, #samples, stepsize, window pointer
dataRange = 60000;
startWindow = seizureStart-dataRange;
currentWindow = startWindow;

lenData = dataRange;
lenData = size(eeg,2); % length of data in seconds
numWindows = lenData/stepSize;
fileName = strcat(patient, '_adjmats_', lower(TYPE_CONNECTIVITY), '.mat');

% initialize timePoints vector and adjacency matrices
timePoints = [1:stepSize:lenData-winSize+1; winSize:stepSize:lenData]';
adjMats = zeros(size(timePoints,1), num_channels, num_channels);

% display data 
disp(['Total number of channels ', num2str(num_channels)]);
disp(['Length of to be included channels ', num2str(length(included_channels))]);
disp(['Seizure starts at ', num2str(seizureStart), ' milliseconds']);
disp(['Running analysis for ', num2str(lenData), ' windows']);

for i=1:numWindows
    % step 1: extract the data and apply the notch filter. Note that column
    %         #i in the extracted matrix is filled by data samples from the
    %         recording channel #i.
    tmpdata = eeg(:, timePoints(i,1):timePoints(i,2));
    
    % step 2: compute some functional connectivity 
    if LEASTSQUARES
        % linear model: Ax = b; A\b -> x
        b = tmpdata(:); % define b as vectorized by stacking columns on top of another
        b = b(num_channels+1:end); % only get the time points after the first one

        % - use least square computation
        theta = computeLeastSquares(tmpdata, b, OPTIONS);
        theta_adj = reshape(theta, num_channels, num_channels)';    % reshape fills in columns first, so must transpose
    elseif CORRELATION
        theta_adj = computePairwiseCorrelation(tmpdata, OPTIONS);
    elseif PDC
        A = theta_adj; 
        p_opt = 1;
        Nf = 250;
        [~, PDC] = computeDTFandPDC(A, p_opt, frequency_sampling, Nf);
    elseif DTF
        [DTF, ~] = computeDTFandPDC(A, p_opt, frequency_sampling, Nf);
    end
    
    % step 3: store the computed adjacency matrix
    adjMats(i, :, :) = theta_adj;

    % display a message for the user
    disp(['Finished: ', num2str(i), ' out of ', num2str(dataRange/stepSize)]);
end

%%- Create the structure for the adjacency matrices for this patient/seizure
adjmat_struct = struct();
adjmat_struct.ezone_labels = ezone_labels;
adjmat_struct.earlyspread_labels = earlyspread_labels;
adjmat_struct.latespread_labels = latespread_labels;
adjmat_struct.resection_labels = resection_labels;
adjmat_struct.all_labels = labels;
adjmat_struct.seizure_start = seizureStart;
adjmat_struct.seizure_end = seizureEnd;
adjmat_struct.winSize = winSize;
adjmat_struct.stepSize = stepSize;
adjmat_struct.timePoints = timePoints;
adjmat_struct.adjMats = adjMats;
adjmat_struct.included_channels = included_channels;

save('test', 'adjmat_struct')
save(fullfile(toSaveAdjDir, fileName), 'adjmat_struct', '-v7.3');
end