function plot_network_fragility(patient, resultsDir)
if nargin==0
    patient = 'pt1sz2';
    resultsDir = fullfile('/Volumes/ADAM LI/serverdata/', ...
        'pertmats/notchfilter/win250_step125_freq1000_radius1.5/pt1sz2/');
    
    spectDir = fullfile('/Volumes/ADAM LI/serverdata/spectral_analysis/fourier/', ...
        'notchfilter_win250_step125_freq1000', 'pt1sz2');
end
%% Set Root Directories To Run Functions
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
addpath(genpath(fullfile(rootDir, '/fragility_library/')));

%% Parameters Of Computed Analysis
radius = 1.5;             % spectral radius
winSize = 250;            % 500 milliseconds
stepSize = 125; 
filterType = 'adaptivefilter';
filterType = 'notchfilter';
fs = 1000; % in Hz
typeConnectivity = 'leastsquares';
typeTransform = 'fourier';
rejectThreshold = 0.3;
reference = '';
perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);

% set patientID and seizureID
[~, patient_id, seizure_id, seeg] = splitPatient(patient);

[included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
    resection_labels, fs, center, success_or_failure] ...
        = determineClinicalAnnotations(patient_id, seizure_id);
if success_or_failure
    outcome = 'SUCCESS';
elseif success_or_failure == 0
    outcome = 'FAILURE';
else
    outcome = 'N/A';
end

% set directory to save figure
figDir = fullfile(rootDir, '/figures/', 'networkfragility', strcat(filterType, reference), ...
    strcat('win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)), ...
    '');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

% extract results to plot
[final_data, info] = extract_results(patient, resultsDir, reference);

% extract actual data structures
pertDataStruct = final_data.(perturbationType);
info = final_data.info;

% set windows/steps sizes
tempWinSize = winSize;
tempStepSize = stepSize;
if fs ~=1000
    tempWinSize = winSize*fs/1000;
    tempStepSize = stepSize*fs/1000;
end

% set data to local variables
minPerturb_time_chan = pertDataStruct.minNormPertMat;
fragilityMat = pertDataStruct.fragilityMat;

% extract time points of each window of model
try
    timePoints = pertDataStruct.timePoints;
    rawTimePoints = info.rawtimePoints;
catch e
    timePoints = info.timePoints;
end
del_table = pertDataStruct.del_table;

% get meta data about where the seizures occur
seizure_estart_ms = info.seizure_estart_ms;
seizure_estart_mark = info.seizure_estart_mark;
seizure_eend_ms = info.seizure_eend_ms;
seizure_eend_mark = info.seizure_eend_mark;

%- set global variable for plotting
seizureStart = seizure_estart_ms;
seizureEnd = seizure_eend_ms;
seizureMarkStart = seizure_estart_mark;
seizureMarkEnd = seizure_eend_mark;
%     seizureIndex = find(seizureStart<timePoints(:,2),1) - 1;
%     seizureEndIndex = find(seizureEnd < timePoints(:,2),1) + 1;    
% set markers for the start/end of seizure if seizure recording
if isnan(seizureStart)
    seizureStart = timePoints(end,1);
    seizureEnd = timePoints(end,1);
    seizureMarkStart = size(timePoints, 1);
    seizureMarkStart = size(minPerturb_time_chan, 2);
    seizureMarkEnd = size(minPerturb_time_chan, 2);
end
if seeg
    seizureMarkStart = (seizureStart-1) / tempStepSize;
end

% set the start time and end time to put on plot in (seconds)
timeStart_plot = -seizureStart / fs;
timeEnd_plot = round((timePoints(size(minPerturb_time_chan, 2), 2) - seizureStart)/fs);
timeEnd_plot = round(timePoints(size(minPerturb_time_chan, 2), 2) - timePoints(seizureMarkStart,2));

% get the metric for rejecting cells in heatmap
timeWinsToReject = broadbandfilter(patient, typeTransform, winSize, stepSize, filterType, spectDir);
timeWinsToReject(timeWinsToReject > rejectThreshold) = 1;
timeWinsToReject(timeWinsToReject <= rejectThreshold) = 0;

% OPTIONAL: apply broadband filter and get rid of time windows
% store original clim
clim = [min(fragilityMat(:)), max(fragilityMat(:))];

% set time windows to -1
tempMat = fragilityMat;
tempMat(logical(timeWinsToReject)) = nan;

%% Extract metadata info
% extract clinical data about the channels and perform some clean up
% ezone_labels = info.ezone_labels;
% earlyspread_labels = info.earlyspread_labels;
% latespread_labels = info.latespread_labels;
% resection_labels = info.resection_labels;
included_labels = info.all_labels;
try
    included_labels = included_labels(info.included_channels);
catch e
    disp(e);
end

%% Compute Network Total Fragility
network_fragility = compute_network_fragility(tempMat);

%% Plot
% 1. plot network fragility over time
figure;
subplot(211);
plot(1:length(network_fragility), network_fragility, 'k-');

subplot(212);
plot(1:length(network_fragility), log(network_fragility), 'k-');

ax = gca;
% create a plotted line to delinate where seizure instances occur
hold on
plot([seizureMarkStart seizureMarkStart], ax.YLim, 'k', 'LineWidth', 3, 'LineStyle', '-')
plot([seizureMarkEnd seizureMarkEnd], ax.YLim, 'k', 'LineWidth', 3, 'LineStyle', '--')

%% Set X - Axis
XLim = ax.XLim; XLowerLim = XLim(1); XUpperLim = XLim(2);

% plot entire series of data
xTickStep = (XUpperLim - XLowerLim) / 10;
xTicks = round(timeStart_plot:abs(timeEnd_plot-timeStart_plot)/10:timeEnd_plot);
ax.XTick = (XLowerLim+0.5 : xTickStep : XUpperLim+0.5);
ax.XTickLabel = xTicks; % set xticks and their labels
xlim([XLowerLim, XUpperLim+1]);

% 3. save figure
toSaveFigFile = fullfile(figDir, strcat(patient, '_networkfragility'));
print(toSaveFigFile, '-dpng', '-r0')


end