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

ezone_labels = clinicalLabels.ezone_labels;
earlyspread_labels = clinicalLabels.earlyspread_labels;
latespread_labels = clinicalLabels.latespread_labels;

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

% initialize metadata describing the seizure and the recording
if ~isempty(included_channels)
    num_channels = length(included_channels);
else
    num_channels = size(eeg, 1);
end

% paramters describing the data to be saved
% window parameters - overlap, #samples, stepsize, window pointer
preseizureTime = timeRange(1); % e.g. 60 seconds 
postseizureTime = timeRange(2); % e.g. 10 seconds
dataStart = seizureStart - preseizureTime*frequency_sampling;  % current data window                      % where to grab data (milliseconds)
limit = seizureStart + postseizureTime*frequency_sampling; % go to seizure start, or + 10 seconds
currentWindow = dataStart;
dataRange = limit-currentWindow;


disp(['The range locked to seizure to look over is ', num2str(-timeRange(1)), ...
    ' until ', num2str(timeRange(2))]); 
disp(['Total number of channels ', num2str(num_channels)]);
disp(['Length of to be included channels ', num2str(length(included_channels))]);
disp(['Seizure starts at ', num2str(limit), ' milliseconds']);
disp(['Running analysis for ', num2str(dataRange), ' milliseconds']);

% set stepsize and window size to reflect sampling rate (milliseconds)
stepSize = stepSize * frequency_sampling/1000; 
winSize = winSize * frequency_sampling/1000;

for i=1:dataRange/stepSize  
    dataWindow = dataStart + (i-1)*stepSize; % get step size as function of current step
    
    % initialize the file name to save the adjacency matrix as
    fileName = strcat(patient, '_', num2str(i), '_before', num2str(seizureStart-dataWindow), '.mat');
    
    
    % step 1: extract the data and apply the notch filter. Note that column
    %         #i in the extracted matrix is filled by data samples from the
    %         recording channel #i.
    tmpdata = eeg(:, dataWindow + 1:dataWindow + winSize);

    % step 2: compute some functional connectivity 
    % linear model: Ax = b; A\b -> x
    b = tmpdata(:); % define b as vectorized by stacking columns on top of another
    b = b(num_channels+1:end); % only get the time points after the first one
    
    tmpdata = tmpdata';

    % build up A matrix with a loop modifying #time_samples points and #chans at a time
    A = zeros(length(b), num_channels^2);               % initialize A for speed
    N = 1:num_channels:size(A,1);                       % set the indices through rows
    A(N, 1:num_channels) = tmpdata(1:end-1,:);          % set the first loop
    
    for iChan=2 : num_channels % loop through columns #channels per loop
        rowInds = N+(iChan-1);
        colInds = (iChan-1)*num_channels+1:iChan*num_channels;
        A(rowInds, colInds) = tmpdata(1:end-1,:);
    end

    % A is a sparse matrix, so store it as such
    A = sparse(A);
    b = double(b);

    % create the reshaped adjacency matrix
    tic;
    theta = A\b;                                                % solve for x, connectivity
    theta_adj = reshape(theta, num_channels, num_channels)';    % reshape fills in columns first, so must transpose
    toc;
    
    %% save the theta_adj made

    %- save the data into a struct into a mat file milliseconds
    data = struct();
    data.theta_adj = theta_adj;
    data.seizureStart = seizureStart;
    data.seizureEnd = seizureEnd;
    data.winSize = winSize;
    data.stepSize = stepSize;
    data.timewrtSz = dataWindow - seizureStart;
    data.timeStart = seizureStart - preseizureTime*frequency_sampling;
    data.timeEnd = seizureStart + postseizureTime*frequency_sampling;
    data.index = i;
    data.included_channels = included_channels;
    data.ezone_labels = ezone_labels;
    data.earlyspread_labels = earlyspread_labels;
    data.latespread_labels = latespread_labels;
    data.labels = labels;
    
    save(fullfile(toSaveAdjDir, fileName), 'data');
    
    disp(['Saved file: ', fileName]);
end

end