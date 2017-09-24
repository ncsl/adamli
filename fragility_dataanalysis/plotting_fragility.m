function plotting_fragility(patients, winSize, stepSize, filterType, radius, typeConnectivity, typeTransform, rejectThreshold)
if nargin == 0
    % data parameters to find correct directory
    patient = 'pt1sz2';
    patients = {,... 
%                 'pt6sz3', 'pt6sz4', 'pt6sz5',...
%                 'pt1aslp1', ...
%                 'pt1aslp2', ...
%                 'pt1aw1', 'pt1aw2', ...
%                 'JH103aslp1', ...
%                 'JH103aw1', ...
%                 'JH105aslp1', ...
%                 'JH105aw1', ...
%             'UMMC002_sz1', 'UMMC002_sz2', 'UMMC002_sz3', ...
%             'UMMC007_sz1', 'UMMC007_sz2','UMMC007_sz3', ...
            'Pat2sz1p', 'Pat2sz2p', 'Pat2sz3p', ...
%             'Pat16sz1p', 'Pat16sz2p', 'Pat16sz3p', ...
        };
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
end
    
close all;
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

% parameters for the computed data
perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);

% set patientID and seizureID
[~, patient_id, seizure_id, seeg] = splitPatient(patients{1});

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
figDir = fullfile(rootDir, '/figures/', filterType, ...
    strcat('win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)), ...
    'preictal');

figDir = fullfile(rootDir, '/figures/', filterType, ...
    strcat('win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)));
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

% loop through patients if there are more then 1
% generally done for multiple datasets of the same patient
matToPlot = [];
seizureBeginIndices = [];
seizureEndIndices = [];
timePlotStarts = [];
timePlotEnds = [];
for iPat=1:length(patients)
    % get the current patient
    patient = patients{iPat};
    
    % spectral analysis directory for this patient
    spectDir = fullfile(dataDir, strcat('/serverdata/spectral_analysis/'), typeTransform, ...
        strcat(filterType, '_win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
        patient);
    
    [final_data, info] = extract_results(patient, winSize, stepSize, filterType, radius)

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
    timeEnd_plot = round((timePoints(size(minPerturb_time_chan, 2), 2) - seizureStart + 1)/fs);
    
    % get the metric for rejecting cells in heatmap
    timeWinsToReject = broadbandfilter(patient, typeTransform, winSize, stepSize, filterType, spectDir);
    timeWinsToReject(timeWinsToReject > rejectThreshold) = 1;
    timeWinsToReject(timeWinsToReject <= rejectThreshold) = 0;

    % OPTIONAL: apply broadband filter and get rid of time windows
    % store original clim
    clim = [min(fragilityMat(:)), max(fragilityMat(:))];
    
    % set time windows to -1
    tempMat = fragilityMat;
    tempMat(logical(timeWinsToReject)) = -1;
    
    % OPTIONAL: only plot the preictal states
%     if seizureMarkStart ~= size(fragilityMat, 2)
%         tempMat = tempMat(:, 1:seizureMarkStart);
%         timePoints = timePoints(1:seizureMarkStart, :);
%         timeStart = (timePoints(1,1)-1 - seizureStart) / fs;
%         timeEnd = (timePoints(end,1)-1 - seizureStart) / fs;
%     end
    % ONLY plot until ictal off
    if seizureMarkStart ~= size(fragilityMat, 2)
        tempMat = tempMat(:, 1:seizureMarkEnd);
        timePoints = timePoints(1:seizureMarkEnd, :);
        timeStart = (timePoints(1,1)-1 - seizureEnd) / fs;
        timeEnd = (timePoints(end,1)-1 - seizureEnd) / fs;
    end
    
    % create heatmap to plot
    if isempty(matToPlot)
        matToPlot = tempMat;
        seizureBeginIndices = seizureMarkStart;
        seizureEndIndices = seizureMarkEnd;
        timePlotStarts = timeStart;
        timePlotEnds = timeEnd;
    else
        matToPlot = [matToPlot, tempMat];
%         seizureBeginIndices = [seizureBeginIndices; seizureMarkStart + seizureBeginIndices(iPat-1)];
        seizureBeginIndices = [seizureBeginIndices; seizureMarkStart + seizureEndIndices(iPat-1)];

        seizureEndIndices = [seizureEndIndices; seizureMarkEnd + seizureEndIndices(iPat-1)];
        timePlotStarts = [timePlotStarts; timeStart];
        timePlotEnds = [timePlotEnds; timeEnd];
    end
end

%% Extract metadata info
% extract clinical data about the channels and perform some clean up
% ezone_labels = info.ezone_labels;
% earlyspread_labels = info.earlyspread_labels;
% latespread_labels = info.latespread_labels;
% resection_labels = info.resection_labels;
included_labels = info.all_labels;
num_channels = length(info.all_labels);
% remove POL from labels
included_labels = upper(included_labels);
included_labels = strrep(included_labels, 'POL', '');
included_labels = strtrim(included_labels);
ezone_labels = strrep(ezone_labels, 'POL', '');
earlyspread_labels = strrep(earlyspread_labels, 'POL', '');
latespread_labels = strrep(latespread_labels, 'POL', '');
resection_labels = strrep(resection_labels, 'POL', '');

% Get Indices for All Clinical Annotations on electrodes
ezone_indices = findElectrodeIndices(ezone_labels, included_labels);
earlyspread_indices = findElectrodeIndices(earlyspread_labels, included_labels);
latespread_indices = findElectrodeIndices(latespread_labels, included_labels);
resection_indices = findElectrodeIndices(resection_labels, included_labels);

allYTicks = 1:num_channels; 
y_indices = setdiff(allYTicks, [ezone_indices; earlyspread_indices]);
if sum(latespread_indices > 0)
    latespread_indices(latespread_indices ==0) = [];
    y_indices = setdiff(allYTicks, [ezone_indices; earlyspread_indices; latespread_indices]);
end
y_ezoneindices = sort(ezone_indices);
y_earlyspreadindices = sort(earlyspread_indices);
y_latespreadindices = sort(latespread_indices);
y_resectionindices = resection_indices;

% create struct for clinical indices
clinicalIndices.all_indices = y_indices;
clinicalIndices.ezone_indices = y_ezoneindices;
clinicalIndices.earlyspread_indices = y_earlyspreadindices;
clinicalIndices.latespread_indices = y_latespreadindices;
clinicalIndices.resection_indices = y_resectionindices;
clinicalIndices.included_labels = included_labels;

%% Plot
% 1. plot the heatmap
fig_heatmap = plotHeatmap(matToPlot); % get the current figure
ax = fig_heatmap.CurrentAxes; % get the current axes

% set colormap axes to configure for the -1 value from broadband filter
newmap = jet;
ncol = size(newmap, 1);
zpos = 1;
newmap(zpos, :) = [1 1 1];
colormap(newmap);
caxis(clim);

hold on;
set(fig_heatmap, 'Units', 'inches');
% fig_heatmap.Position = [17.3438         0   15.9896   11.6771];
fig_heatmap.Position = [0.0417 0.6667 21.0694 13.0139];

% 2. label axes
FONTSIZE = 20;
PLOTARGS = struct();
PLOTARGS.YAXFontSize = 9;
PLOTARGS.FONTSIZE = FONTSIZE;
PLOTARGS.xlabelStr = 'Time With Respect To Seizure (sec)';
if isnan(info.seizure_estart_ms)
    PLOTARGS.xlabelStr = 'Time (sec)';
end
PLOTARGS.xlabelStr = 'Time (1 col = 1 window)';
PLOTARGS.ylabelStr = 'Electrode Channels';
PLOTARGS.timeStart = timeStart_plot;
PLOTARGS.timeEnd = timeEnd_plot;
PLOTARGS.xTickStep = 10*winSize/stepSize;
PLOTARGS.frequency_sampling = fs;
PLOTARGS.seizureMarkStart = seizureMarkStart;
PLOTARGS.stepSize = stepSize;
PLOTARGS.titleStr = {[outcome, ': Fragility Metric (', strcat(patient_id, seizure_id), ')'], ...
        [perturbationType, ' Perturbation: ', ' Time Locked to Seizure']};
% PLOTARGS.titleStr = {[outcome, ': Fragility Metric (', patient_id, ')'], ...
%     [perturbationType, ' Perturbation: ']};
labelHeatmap(ax, fig_heatmap,clinicalIndices, PLOTARGS);

% move ylabel to the left a bit
ylab = ax.YLabel;
ylab.Position = ylab.Position + [-105 0 0]; % move ylabel to the left

% label the colorbar
colorArgs = struct();
colorArgs.colorbarStr = 'Fragility Metric';
colorArgs.FontSize = FONTSIZE;
labelColorbar(ax, colorArgs)

% create a plotted line to delinate where seizure instances occur
% comment out if plotting preictal
%     xTicks = round(timeStart: (timeEnd-timeStart)/10 :timeEnd);
hold on
for i=1:length(seizureBeginIndices)
    seizureMarkStart = seizureBeginIndices(i);
    plot([seizureMarkStart seizureMarkStart], ax.YLim, 'k', 'LineWidth', 3, 'LineStyle', '-')
end
for i=1:length(seizureEndIndices)-1
    seizureMarkEnd = seizureEndIndices(i);
    plot([seizureMarkEnd seizureMarkEnd], ax.YLim, 'k', 'LineWidth', 3, 'LineStyle', '--')
end


%% Set X - Axis
XLim = ax.XLim; XLowerLim = XLim(1); XUpperLim = XLim(2);
% % Preictal: set the x axis in seconds and correct times
% % create a text for each preictal event and set it on the x-axis
% xTickStep = zeros(length(seizureBeginIndices), 1);
% xTickStep(1) = seizureBeginIndices(1) / 2;
% xTicks = {};
% xTicks{1} = '1st Preictal Event';
% for iEv = 2:length(seizureBeginIndices)
%     xTickStep(iEv) = (seizureBeginIndices(iEv) - (seizureBeginIndices(iEv)- seizureBeginIndices(iEv-1))/2);
%     xTicks{iEv} = strcat(num2str(iEv), 'th Preictal Event');
% end
% ax.XTick = xTickStep;
% ax.XTickLabel = xTicks; % set xticks and their labels

% Interictal: set the x axis in seconds and correct times
% xTickStep = (XUpperLim - XLowerLim) / 10;
% 
% % create a text for each preictal event and set it on the x-axis
% xTickStep = zeros(length(seizureBeginIndices), 1);
% xTickStep(1) = seizureBeginIndices(1) / 2;
% xTicks = {};
% xTicks{1} = '1st Interictal Event';
% for iEv = 2:length(seizureBeginIndices)
%     xTickStep(iEv) = (seizureBeginIndices(iEv) - (seizureBeginIndices(iEv)- seizureBeginIndices(iEv-1))/2);
%     xTicks{iEv} = strcat(num2str(iEv), 'th Interictal Event');
% end
% ax.XTick = xTickStep;
% ax.XTickLabel = xTicks; % set xticks and their labels

% Ictal: set the x axis in seconds and correct times
% create a text for each preictal event and set it on the x-axis
xTickStep = zeros(length(seizureBeginIndices), 1);
xTickStep(1) = seizureEndIndices(1) / 2;
xTicks = {};
xTicks{1} = '1st Ictal Event';
for iEv = 2:length(seizureBeginIndices)
    xTickStep(iEv) = (seizureEndIndices(iEv) - (seizureEndIndices(iEv)- seizureEndIndices(iEv-1))/2);
    xTicks{iEv} = strcat(num2str(iEv), 'th Ictal Event');
end
ax.XTick = xTickStep;
ax.XTickLabel = xTicks; % set xticks and their labels

% plot entire series of data
% xTickStep = (XUpperLim - XLowerLim) / 10;
% xTicks = round(timeStart_plot:abs(timeEnd_plot-timeStart_plot)/10:timeEnd_plot);
% ax.XTick = (XLowerLim+0.5 : xTickStep : XUpperLim+0.5);
% ax.XTickLabel = xTicks; % set xticks and their labels
% xlim([XLowerLim, XUpperLim+1]);

% 3. save figure
toSaveFigFile = fullfile(figDir, strcat(patient, '_broadbandfilter', ...
    '_concatictal'));
print(toSaveFigFile, '-dpng', '-r0')
end
