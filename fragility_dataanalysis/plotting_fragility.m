function plotting_fragility(patient, winSize, stepSize, filterType, radius, typeConnectivity, typeTransform, rejectThreshold)
if nargin == 0
    % data parameters to find correct directory
    patient = 'pt1sz2';
    patient='JH103aw1';
%     patient = 'pt1aw1';
    radius = 1.5;             % spectral radius
    winSize = 250;            % 500 milliseconds
    stepSize = 125; 
    filterType = 'adaptivefilter';
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
[~, patient_id, seizure_id, seeg] = splitPatient(patient);

[included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
    resection_labels, fs, center, success_or_failure] ...
        = determineClinicalAnnotations(patient_id, seizure_id);

% set directories
serverDir = fullfile(dataDir, '/serverdata/');

adjMatDir = fullfile(dataDir, 'serverdata/adjmats/', filterType, strcat('win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
        
finalDataDir = fullfile(dataDir, strcat('/serverdata/perturbationmats/', filterType, '/win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)), patient); % at lab

% notch and updated directory
spectDir = fullfile(dataDir, strcat('/serverdata/spectral_analysis/'), typeTransform, ...
    strcat(filterType, '_win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
    patient);
    
% set directory to save figure
figDir = fullfile(rootDir, '/figures/', filterType, ...
    strcat('win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)), ...
    'preictal');

figDir = fullfile(rootDir, '/figures/', filterType, ...
    strcat('win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)));
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

final_data = load(fullfile(finalDataDir, strcat(patient, ...
    '_pertmats_', lower(typeConnectivity), '_radius', num2str(radius), '.mat')));
final_data = final_data.perturbation_struct;

%% Extract metadata info
info = final_data.info;

% extract clinical data
% ezone_labels = info.ezone_labels;
% earlyspread_labels = info.earlyspread_labels;
% latespread_labels = info.latespread_labels;
% resection_labels = info.resection_labels;
included_labels = info.all_labels;
seizure_estart_ms = info.seizure_estart_ms;
seizure_estart_mark = info.seizure_estart_mark;
seizure_eend_ms = info.seizure_eend_ms;
seizure_eend_mark = info.seizure_eend_mark;
num_channels = length(info.all_labels);

%- set global variable for plotting
seizureStart = seizure_estart_ms;
seizureEnd = seizure_eend_ms;
seizureMarkStart = seizure_estart_mark;

% remove POL from labels
included_labels = upper(included_labels);
included_labels = strrep(included_labels, 'POL', '');
ezone_labels = strrep(ezone_labels, 'POL', '');
earlyspread_labels = strrep(earlyspread_labels, 'POL', '');
latespread_labels = strrep(latespread_labels, 'POL', '');
resection_labels = strrep(resection_labels, 'POL', '');

%%- Get Indices for All Clinical Annotations
ezone_indices = findElectrodeIndices(ezone_labels, included_labels);
earlyspread_indices = findElectrodeIndices(earlyspread_labels, included_labels);
latespread_indices = findElectrodeIndices(latespread_labels, included_labels);

allYTicks = 1:num_channels; 
y_indices = setdiff(allYTicks, [ezone_indices; earlyspread_indices]);
if sum(latespread_indices > 0)
    latespread_indices(latespread_indices ==0) = [];
    y_indices = setdiff(allYTicks, [ezone_indices; earlyspread_indices; latespread_indices]);
end
y_ezoneindices = sort(ezone_indices);
y_earlyspreadindices = sort(earlyspread_indices);
y_latespreadindices = sort(latespread_indices);
y_resectionindices = [];

% create struct for clinical indices
clinicalIndices.all_indices = y_indices;
clinicalIndices.ezone_indices = y_ezoneindices;
clinicalIndices.earlyspread_indices = y_earlyspreadindices;
clinicalIndices.latespread_indices = y_latespreadindices;
clinicalIndices.resection_indices = y_resectionindices;
clinicalIndices.included_labels = included_labels;

% if no arguments, and called as a function, then run some testing output
% if nargin==0
    pertDataStruct = final_data.(perturbationType);
    tempWinSize = winSize;
    tempStepSize = stepSize;
    if fs ~=1000
        tempWinSize = winSize*fs/1000;
        tempStepSize = stepSize*fs/1000;
    end

    % set data to local variables
    minPerturb_time_chan = pertDataStruct.minNormPertMat;
    fragilityMat = pertDataStruct.fragilityMat;
    timePoints = pertDataStruct.timePoints;
    del_table = pertDataStruct.del_table;

    if isnan(seizureStart)
        seizureStart = timePoints(end,1);
        seizureEnd = timePoints(end,1);
        seizureMarkStart = size(timePoints, 1);
    end

    if seeg
        seizureMarkStart = (seizureStart-1) / tempStepSize;
    end
    
    timeIndex = find(seizureStart<timePoints(:,2),1) - 1;
    seizureIndex = timeIndex;
    seizureEndIndex = find(seizureEnd < timePoints(:,2),1) + 1;

    % plotting from beginning of recording -> some time
    % specified up there
    timeStart = -seizureStart / fs;
    timeEnd = (timePoints(size(minPerturb_time_chan, 2), 2) - seizureStart)/fs;
    timeEnd = (timePoints(size(minPerturb_time_chan, 2), 2) - seizureStart + 1)/fs;
    
    % get the metric for rejecting cells in heatmap
    timeWinsToReject = broadbandfilter(patient, typeTransform, winSize, stepSize, filterType, spectDir);
    timeWinsToReject(timeWinsToReject > rejectThreshold) = 1;
    timeWinsToReject(timeWinsToReject <= rejectThreshold) = 0;

    % OPTIONAL: apply broadband filter and get rid of time windows
    % store original clim
    clim = [min(fragilityMat(:)), max(fragilityMat(:))];
    % set time windows to nan
%     fragilityMat(logical(timeWinsToReject)) = -1;
%     minmaxFragility(timeWinsToReject) = nan;
    tempMat = fragilityMat;
    tempMat(logical(timeWinsToReject)) = -1;
    
    % OPTIONAL: only plot the preictal states
%     if seizureMarkStart ~= size(fragilityMat, 2)
%         tempMat = tempMat(:, 1:seizureMarkStart);
%         timePoints = timePoints(1:seizureMarkStart, :);
%         timeStart = (timePoints(1,1)-1 - seizureStart) / fs;
%         timeEnd = (timePoints(end,1)-1 - seizureStart) / fs;
%     end
    
    % 1. plot the heatmap
    fig_heatmap = plotHeatmap(tempMat); % get the current figure
    ax = fig_heatmap.CurrentAxes; % get the current axes

    newmap = jet;
    ncol = size(newmap, 1);
    zpos = 1;
    newmap(zpos, :) = [1 1 1];
    colormap(newmap);
    caxis(clim);
    
    hold on;
    set(fig_heatmap, 'Units', 'inches');
    fig_heatmap.Position = [17.3438         0   15.9896   11.6771];
    
    % 2. label axes
    FONTSIZE = 20;
    PLOTARGS = struct();
    PLOTARGS.YAXFontSize = 9;
    PLOTARGS.FONTSIZE = FONTSIZE;
    PLOTARGS.xlabelStr = 'Time With Respect To Seizure (sec)';
    if isnan(info.seizure_estart_ms)
        PLOTARGS.xlabelStr = 'Time (sec)';
    end
    PLOTARGS.ylabelStr = 'Electrode Channels';
    PLOTARGS.timeStart = timeStart;
    PLOTARGS.timeEnd = timeEnd;
    PLOTARGS.xTickStep = 10*winSize/stepSize;
    PLOTARGS.frequency_sampling = fs;
    PLOTARGS.seizureMarkStart = seizureMarkStart;
    PLOTARGS.stepSize = stepSize;
    PLOTARGS.titleStr = {['Success: Fragility Metric (', strcat(patient_id, seizure_id), ')'], ...
            [perturbationType, ' Perturbation: ', ' Time Locked to Seizure']};
    labelHeatmap(ax, fig_heatmap,clinicalIndices, PLOTARGS);
    
    XLim = ax.XLim; XLowerLim = XLim(1); XUpperLim = XLim(2);
    xTickStep = (XUpperLim - XLowerLim) / 10;
    
    % used for preictal plotting
    xTicks = round(timeStart:abs(timeEnd-timeStart)/10:timeEnd);
    
    % comment out if plotting preictal
    hold on
    xTicks = round(timeStart: (timeEnd-timeStart)/10 :timeEnd);
    plot([seizureMarkStart seizureMarkStart], ax.YLim, 'k', 'MarkerSize', 4)
    
    ax.XTick = (XLowerLim+0.5 : xTickStep : XUpperLim+0.5);
    ax.XTickLabel = xTicks; % set xticks and their labels
    xlim([XLowerLim, XUpperLim+1]);
    
    ylab = ax.YLabel;
    ylab.Position = ylab.Position + [-55 0 0]; % move ylabel to the left
    
    colorArgs = struct();
    colorArgs.colorbarStr = 'Fragility Metric';
    colorArgs.FontSize = FONTSIZE;
    labelColorbar(ax, colorArgs)
    
    % 3. save figure
    toSaveFigFile = fullfile(figDir, strcat(patient, '_broadbandfilter'));
    print(toSaveFigFile, '-dpng', '-r0')
end
