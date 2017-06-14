patients = {...,
%      'pt1aw1','pt1aw2', ...
%     'pt2aw2', 'pt2aslp2',...
%     'pt1aslp1','pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', 'pt2aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
%     'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1' 'pt2sz3' , 'pt2sz4', ...
%     'pt3sz2' 'pt3sz4', ...
%     'pt6sz3', 'pt6sz4', 'pt6sz5',...
%     'pt7sz19', 'pt7sz21', 'pt7sz22',...
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1','pt10sz2' 'pt10sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt12sz1', 'pt12sz2', ...
%     'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
%     'pt14sz1' 'pt14sz2' 'pt14sz3'  'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2', 'pt17sz3', ...
    
%     'Pat2sz1p', 'Pat2sz2p', 'Pat2sz3p', ...
%     'Pat16sz1p', 'Pat16sz2p', 'Pat16sz3p', ...
    
    'UMMC001_sz1', 'UMMC001_sz2', 'UMMC001_sz3', ...
    'UMMC002_sz1', 'UMMC002_sz2','UMMC002_sz3', ...
    'UMMC003_sz1', 'UMMC003_sz2', 'UMMC003_sz3', ...
    'UMMC004_sz1', 'UMMC004_sz2', 'UMMC004_sz3', ...
    'UMMC005_sz1', 'UMMC005_sz2', 'UMMC005_sz3', ...
    'UMMC006_sz1', 'UMMC006_sz2', 'UMMC006_sz3', ...
    'UMMC007_sz1', 'UMMC007_sz2','UMMC007_sz3', ...
    'UMMC008_sz1', 'UMMC008_sz2', 'UMMC008_sz3', ...
    'UMMC009_sz1','UMMC009_sz2', 'UMMC009_sz3', ...
%     'JH103aslp1', 'JH103aw1', ...
%    'JH105aslp1', 'JH105aw1', ...
%     'JH101sz1' 'JH101sz2' 'JH101sz3' 'JH101sz4',...
% 	'JH102sz1' 'JH102sz2' 'JH102sz3' 'JH102sz4' 'JH102sz5' 'JH102sz6',...
% 	'JH103sz1' 'JH103sz2' 'JH103sz3',...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
% 	'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
% 	'JH106sz1' 'JH106sz2' 'JH106sz3' 'JH106sz4' 'JH106sz5' 'JH106sz6',...
% 	'JH107sz1' 'JH107sz2' 'JH107sz3' 'JH107sz4' 'JH107sz5' 
%     'JH107sz6' 'JH107sz7' 'JH107sz8' 'JH107sz9',...
%    'JH108sz1', 'JH108sz2', 'JH108sz3', 'JH108sz4', 'JH108sz5', 'JH108sz6', 'JH108sz7',...
%     'EZT004seiz001', 'EZT004seiz002', ...
%     'EZT006seiz001', 'EZT006seiz002', ...
%     'EZT008seiz001', 'EZT008seiz002', ...
%     'EZT009seiz001', 'EZT009seiz002', ...    
%     'EZT011seiz001', 'EZT011seiz002', ...
%     'EZT013seiz001', 'EZT013seiz002', ...
%      'EZT019seiz001', 'EZT019seiz002',...
%     'EZT020seiz001', 'EZT020seiz002', ...
%     'EZT025seiz001', 'EZT025seiz002', ...
%     'EZT026seiz001', 'EZT026seiz002', ...
%     'EZT028seiz001', 'EZT028seiz002', ...
%    'EZT037seiz001', 'EZT037seiz002',...
%    'EZT005seiz001', 'EZT005seiz002',...
%     'EZT007seiz001', 'EZT007seiz002', ...
%    	'EZT070seiz001', 'EZT070seiz002', ...
    };

close all;

perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);
% data parameters to find correct directory
radius = 1.5;             % spectral radius
winSize = 250;            % 500 milliseconds
stepSize = 125; 

%%- initialize plotting args
toPlot = {'fragility', 'rowsum'};
FONTSIZE = 20;
PLOTARGS = struct();
PLOTARGS.SAVEFIG = 1;
PLOTARGS.YAXFontSize = 9;
PLOTARGS.FONTSIZE = FONTSIZE;
PLOTARGS.xlabelStr = 'Time With Respect To Seizure (sec)';
PLOTARGS.xlabelStr = 'Time (sec)';

PLOTARGS.colorbarStr = 'Minimum 2-Induced Norm Perturbation';
PLOTARGS.colorbarStr = 'Fragility Metric';
PLOTARGS.ylabelStr = 'Electrode Channels';
PLOTARGS.xTickStep = 10*winSize/stepSize;
PLOTARGS.titleStr = {['Minimum Norm Perturbation (', patient, ')'], ...
    [perturbationType, ' perturbation: ', ' Time Locked to Seizure']};
PLOTARGS.stepSize = stepSize;

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

% directory with computed data and figure directory
serverDir = fullfile(rootDir, '/serverdata/');
figDir = fullfile(rootDir, '/figures/', typeFilter, ...
    strcat('win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)));

%%- Begin Loop Through Different Patients Here
for p=1:length(patients)
    patient = patients{p};

    % set patientID and seizureID
    patient_id = patient(1:strfind(patient, 'seiz')-1);
    seizure_id = strcat('_', patient(strfind(patient, 'seiz'):end));
    seeg = 1;
    INTERICTAL = 0;
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'sz')-1);
        seizure_id = patient(strfind(patient, 'sz'):end);
        seeg = 0;
    end
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'aslp')-1);
        seizure_id = patient(strfind(patient, 'aslp'):end);
        seeg = 0;
        INTERICTAL = 1;
    end
    if isempty(patient_id)        %%- initialize plotting args
        FONTSIZE = 20;
        PLOTARGS = struct();
        PLOTARGS.SAVEFIG = 1;
        PLOTARGS.YAXFontSize = 9;
        PLOTARGS.FONTSIZE = FONTSIZE;
        PLOTARGS.xlabelStr = 'Time With Respect To Seizure (sec)';
        if isnan(info.seizure_estart_ms)
            PLOTARGS.xlabelStr = 'Time (sec)';
        end
        PLOTARGS.colorbarStr = 'Minimum 2-Induced Norm Perturbation';
        PLOTARGS.ylabelStr = 'Electrode Channels';
        PLOTARGS.xTickStep = 10*winSize/stepSize;
        PLOTARGS.titleStr = {['Minimum Norm Perturbation (', patient, ')'], ...
            [perturbationType, ' perturbation: ', ' Time Locked to Seizure']};
        PLOTARGS.seizureMarkStart = seizureMarkStart;
        PLOTARGS.frequency_sampling = fs;
        PLOTARGS.stepSize = stepSize;
        patient_id = patient(1:strfind(patient, 'aw')-1);
        seizure_id = patient(strfind(patient, 'aw'):end);
        seeg = 0;
        INTERICTAL = 1;
    end

    buffpatid = patient_id;
    if strcmp(patient_id(end), '_')
        patient_id = patient_id(1:end-1);
    end
    [included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
        resection_labels, fs, center, success_or_failure] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
        
    
    % set the ltv model directory and the perturbation model directory
    adjMatDir = fullfile(rootDir, 'serverdata/adjmats/', typeFilter, strcat('win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
        
    finalDataDir = fullfile(rootDir, strcat('/serverdata/perturbationmats/', typeFilter, '/win', num2str(winSize), ...
                '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)), patient); % at lab

    %- initialize directories to save things and where to get
    %- perturbation structs
    toSaveFigDir = fullfile(figDir, perturbationType, strcat(patient, '_win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)))
    if ~exist(toSaveFigDir, 'dir')
        mkdir(toSaveFigDir);
    end
            
    %% Extract data
    final_data = load(fullfile(finalDataDir, strcat(patient, ...
            '_pertmats_', lower(TYPE_CONNECTIVITY), '_radius', num2str(radius), '.mat')));
    final_data = final_data.perturbation_struct;
    
    % set data to local variables
    info = final_data.info;
    
    %- extract clinical data
%     ezone_labels = info.ezone_labels;
%     earlyspread_labels = info.earlyspread_labels;
%     latespread_labels = info.latespread_labels;
%     resection_labels = info.resection_labels;
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
    seizureMarkEnd = seizure_eend_mark;
    
    %% Get Indices for All Clinical Annotations
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
     % find resection indices
%     y_resectionindices = findResectionIndices(included_labels, resection_labels);
    y_resectionindices = [];
    
    % create struct for clinical indices
    clinicalIndices.all_indices = y_indices;
    clinicalIndices.ezone_indices = y_ezoneindices;
    clinicalIndices.earlyspread_indices = y_earlyspreadindices;
    clinicalIndices.latespread_indices = y_latespreadindices;
    clinicalIndices.resection_indices = y_resectionindices;
    clinicalIndices.included_labels = included_labels;
    
    %% Extract Data And Prepare Plotting
    pertDataStruct = final_data.(perturbationType);
    % set data to local variables
    minPerturb_mat = pertDataStruct.minNormPertMat;
    fragility_mat = pertDataStruct.fragilityMat;
    timePoints = pertDataStruct.timePoints;
    del_table = pertDataStruct.del_table;

    % set win/step, and seizure marker variables 
    tempWinSize = winSize;
    tempStepSize = stepSize;
    if fs ~=1000
        tempWinSize = winSize*fs/1000;
        tempStepSize = stepSize*fs/1000;
    end
    if isnan(seizureStart)
        seizureStart = timePoints(end,1);
        seizureEnd = timePoints(end,1);
        seizureMarkStart = size(timePoints, 1);
    end
    if seeg
        seizureMarkStart = (seizureStart-1) / tempStepSize;
    end
    
    PLOTARGS.seizureMarkStart = seizureMarkStart;
    PLOTARGS.frequency_sampling = fs;
    if success_or_failure == 1
        PLOTARGS.titleStr = {['Success: Fragility Metric (', strcat(patient_id, seizure_id), ')'], ...
        [perturbationType, ' Perturbation: ', ' Time Locked to Seizure']};
    elseif success_or_failure == 0
        PLOTARGS.titleStr = {['Failure: Fragility Metric (', strcat(patient_id, seizure_id), ')'], ...
        [perturbationType, ' Perturbation: ', ' Time Locked to Seizure']};
    else % not set
        PLOTARGS.titleStr = {['Fragility Metric (', strcat(patient_id, seizure_id(2:end)), ')'], ...
        [perturbationType, ' Perturbation: ', ' Time Locked to Seizure']};
    end
    
    %% Plot just the fragility metric
    if strmatch('fragility', toPlot)
        frag_fig = figure;
        firstplot = 1:24;
        firstplot([6,12,18,24]) = []; hold on;
        firstfig = subplot(4,6, firstplot);
        imagesc(fragility_mat); hold on; axis tight;
        axes = gca; currfig = gcf;
        cbar = colorbar(); colormap('jet'); 
        axes.Box = 'off'; axes.YDir = 'normal';
        
        plot([seizureMarkStart seizureMarkStart], get(gca, 'ylim'), 'k', 'MarkerSize', 2)
        
        % create title string and label the axes of plot
        labelBasicAxes(axes, titleStr, ylabelStr, xlabelStr, FONTSIZE);
        ylab = axes.YLabel;
        labelColorbar(cbar, colorbarStr, FONTSIZE);
        set(cbar.Label, 'Rotation', 270);
        
        XLim = axes.XLim; XLowerLim = XLim(1); XUpperLim = XLim(2);
        XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);

        % set x/y ticks and increment xlim by 1
        xTickStep = round((XUpperLim - XLowerLim) / 10);
        xTicks = round(timeStart: (timeEnd-timeStart)/10 :timeEnd);
        yTicks = [1, 5:5:size(fragility_mat,1)];
        
        set(gca, 'XTick', (XLowerLim+0.5 : xTickStep : XUpperLim+0.5)); set(gca, 'XTickLabel', xTicks); % set xticks and their labels
        set(gca, 'YTick', yTicks);
        xlim([XLowerLim, XUpperLim+1]);

        % plot start star's for the different clinical annotations
        figIndices = {ezone_indices, earlyspread_indices, latespread_indices};
        colors = {[1 0 0], [1 .5 0], [0 0 1]};
        for i=1:length(figIndices)
            if sum(figIndices{i})>0
                xLocations = repmat(XUpperLim+1, length(figIndices{i}), 1);
                plotAnnotatedStars(fig, xLocations, figIndices{i}, colors{i});
            end
        end
    end
    if strmatch('rowsum', toPlot)
        xrange = 1:size(fragility_mat, 1);
        xrange(ezone_indices) = [];
        secfig = subplot(4,6, [6,12,18,24]);
        %- plot stem
        stem(xrange, rowsum_preseize(xrange), 'k'); hold on; axis tight;
        stem(ezone_indices, rowsum_preseize(ezone_indices), 'r');

        if seizureMarkStart < size(thresh_fragility,2) - 10
            try
                rowsum_postseize10 = sum(thresh_fragility(:, 1:seizureMarkStart+10*frequency_sampling/stepSize), 2);
                plot(1:size(fragility_mat, 1), rowsum_postseize10, 'g');
                rowsum_postseize20 = sum(thresh_fragility(:, 1:seizureMarkStart+20*frequency_sampling/stepSize), 2);
                plot(1:size(fragility_mat, 1), rowsum_postseize20, 'b');
            catch e
                disp(e)
            end
    %         fragility_mat = fragility_mat(:, 1:seizureMarkStart+20*frequency_sampling/stepSize);
    %         timePoints = timePoints(1:seizureMarkStart + 20*frequency_sampling/stepSize, :);
        end


    %     stem(xrange, rowsum(xrange), 'k'); hold on;
    %     stem(ezone_indices, rowsum(ezone_indices), 'r');
    %     plot([1 size(fragility_mat, 1)], [avge avge], 'k', 'MarkerSize', 1.5);

        % plot *'s for the resection indices
        if ~isempty(resection_indices)
            YLim = get(gca, 'YLim');
            YLowerLim = YLim(1);
            YUpperLim = YLim(2);
            ylim([YLowerLim-1, YUpperLim])

            xLocations = repmat(XLowerLim-1, length(resection_indices), 1);
            plot(resection_indices, xLocations, 'o', 'Color', [0 0.5 0], 'MarkerSize', 4); hold on;
        end
        pos = get(gca, 'Position');
        pos(1) = pos(1) + xoffset;
        xlim([1 size(fragility_mat,1)]);
        set(gca, 'Xdir', 'reverse');
        set(gca, 'Position', pos);
        set(gca, 'XTick', []); set(gca, 'XTickLabel', []);
        set(gca, 'yaxislocation', 'right');
        set(gca, 'XAxisLocation', 'bottom');
        xlabel('Row Sum of Fragility Metric', 'FontSize', FONTSIZE-3);
        view([90 90])
        ax = gca;
        ax.XLabel.Rotation = 270;
        ax.XLabel.Position = ax.XLabel.Position + [0 max(ax.YLim)*1.05 0];

        secleg = legend('Preseizure', 'EZone', 'Post+10', 'Post+20');
        secleg.Position = [0.8710    0.9529    0.0678    0.0316]; 
    end
end   