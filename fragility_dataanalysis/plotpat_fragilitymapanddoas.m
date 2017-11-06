clear all
clc
close all

%% Success LA
% patients = {,...
%     {'LA01_ICTAL', 'LA01_Inter'},...
%     {'LA02_ICTAL', 'LA02_Inter'}, ...
% };
% 
% times = {,...
%     [[20],[]],... % LA01
%     [16, []], ... % LA02
% };

%% Failure LA
patients = {,...
%     'LA02_ICTAL', 'LA02_Inter',...
    {'LA04_ICTAL','LA04_Inter'}, ...
    {'LA06_ICTAL', 'LA06_Inter'}, ...
    {'LA08_ICTAL', 'LA08_Inter'}, ...
    {'LA11_ICTAL', 'LA11_Inter'}, ...
    {'LA15_ICTAL', 'LA15_Inter'}, ...
    {'LA16_ICTAL', 'LA16_Inter'}, ...
};
times = {,...
%     [16, []], ... % LA02 % <- include the previous annotation. ask zach
    [10, []],... % LA04
    [10,[]], ... % LA06
    [15,[]],... % LA08
    [[],[]],... % LA11
    [20,[]], ... % LA15
    [10,[]],... % LA16
};

%% Success Ictal
% patients = {...,
%     {'pt1sz2', 'pt1sz3', 'pt1sz4'}, ...},...
%     {'pt2sz1' 'pt2sz3' , 'pt2sz4'}, ...}, ...
%     {'pt3sz2' 'pt3sz4'}, ...}, ...
%     {'pt8sz1' 'pt8sz2' 'pt8sz3'},...
%     {'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5'},...
%     {'pt15sz1', 'pt15sz4'},...
% };
% times = {,...
%     [15, 12, 9], ... % pt1
%     [40, 40, 55],... % pt2
%     [15, 15],... % pt3
%     [8 8 8],... % pt 8
%     [7 7 7 7],... % pt13
%     [20 30],... % pt 15
% };

%% Interictal
% patients={, ...
% {'pt1aw1','pt1aw2', 'pt1aslp1','pt1aslp2'}, ...
% {'pt2aw1', 'pt2aw2', 'pt2aslp1', 'pt2aslp2'},...
% {'pt3aw1', 'pt3aslp1', 'pt3aslp2'}, ...
% };
% times = {,...
%     [15, 12, 10, [], [], [], []], ... % pt1
%     [60, 60, 75, [], [], [], []],... % pt2
%     [17, 17, [], [], []],... % pt3
%     [12 12 12],... % pt 8
%     [7 7 7 7],... % pt13
%     [20 30 10 30],... % pt 15
% };

%% Failures
% patients = {,...
%     {'pt6sz3', 'pt6sz4', 'pt6sz5'},...
%     {'pt7sz19', 'pt7sz21', 'pt7sz22'},...
%     {'pt10sz1','pt10sz2' 'pt10sz3'}, ...
%     {'pt12sz1', 'pt12sz2'},...
%     {'pt14sz1' 'pt14sz2' 'pt14sz3'}, ...
% };
% times = {,...
%     [10, 10 10],... % pt 6
% 	[10 30 10],... % pt 7
% 	[50 50 50],... % pt 10
%     [170, 170], ...% pt 12
% 	[60 55 55],... % pt 14
% };
%% Set Root Directories
% data directories to save data into - choose one
eegRootDirHD = '/Volumes/NIL Pass/';
eegRootDirHD = '/Volumes/ADAM LI/';
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
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

%% Parameters
winSize = 250;
stepSize = 125;
filterType = 'notchfilter';
radius = 1.5;
typeConnectivity = 'leastsquares';
typeTransform = 'fourier';
rejectThreshold = 0.3;
reference = '';
% set which pertrubation model to analyze
perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);

FONTSIZE = 16;
metric = 'jaccard';

figDir = fullfile(rootDir, '/figures', 'fragilityStats', ...
    strcat(filterType), ...
    strcat('perturbation', perturbationType, '_win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)));

if ~exist(figDir, 'dir')
    mkdir(figDir);
end

% store frag mats
allfragmats = cell(length([patients{:}]), 1);
allezlabels = cell(length([patients{:}]), 1);
allincludedlabels = cell(length([patients{:}]), 1);
allresectionlabels = cell(length([patients{:}]), 1);
allspreadlabels = cell(length([patients{:}]), 1);

% params to include the plot for doa also
epsilon = 0.8;
a1 = 0.8;
a2 = 0.2;
a3=0;
threshold=0.4;
NORMALIZE=1;
doas = zeros(length([patients{:}]), 1);
%% LOAD ALL DATA LOCALLY
ind = 1;
inds = 1:length([patients{:}]);
% loop through each separate cell array
for iGroup=1:length(patients)
    group = patients{iGroup};
    coded_times = times{iGroup};
    for iPat=1:length(group)
        patient = group{iPat}
        if contains(lower(patient), 'inter') || contains(lower(patient), 'aw') || contains(lower(patient), 'aslp')
            interictal = 1;
        else
            interictal = 0;
        end
        %% 1. Extract Data
        % set patientID and seizureID and extract relevant clinical meta data
        [~, patient_id, seizure_id, seeg] = splitPatient(patient);
        [included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
            resection_labels, fs, center, success_or_failure] ...
                = determineClinicalAnnotations(patient_id, seizure_id);
        if success_or_failure
            outcome = 'Success';
        else
            outcome = 'Failure';
        end
            
        % perturbation directory for this patient
        pertDir = fullfile(dataDir, 'serverdata', 'pertmats', ...
            strcat(filterType), ...
            strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)));
%         pertDir = fullfile(dataDir, 'pertmats');
        % notch and updated spectral analysis directory
        spectDir = fullfile(dataDir, strcat('/serverdata/spectral_analysis/'), typeTransform, ...
            strcat(filterType, '_win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
            patient);
        
        try
            final_data = load(fullfile(pertDir, ...
                patient,...
                strcat(patient, '_pertmats', '.mat')));
        catch e
            final_data = load(fullfile(pertDir, ...
                patient, ...
                strcat(patient, '_pertmats_leastsquares_radius', num2str(radius), '.mat')));
        end
        final_data = final_data.perturbation_struct;

        % load meta data
        info = final_data.info;

        % load perturbation data
        pertDataStruct = final_data.(perturbationType);

        %- extract clinical data
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
        
        % min norm perturbation, fragility matrix, minmax fragility matrix
        minNormPertMat = pertDataStruct.minNormPertMat;
        fragilityMat = pertDataStruct.fragilityMat;
        
        %% 2. Perform any Preprocessing
        try
            % broadband filter for this patient
            timeWinsToReject = broadbandfilter(patient, typeTransform, winSize, stepSize, filterType, spectDir);
            rejectThreshold = 0.3;
            timeWinsToReject(timeWinsToReject > rejectThreshold) = 1;
            timeWinsToReject(timeWinsToReject <= rejectThreshold) = 0;

            % OPTIONAL: apply broadband filter and get rid of time windows
            % set time windows to nan
            fragilityMat(logical(timeWinsToReject)) = nan;
        catch e
            disp(e);
        end
        
        % vector of hard coded time windows to go to for each patient
        if ~interictal
            try
                time = coded_times(iPat);
            catch e
                disp('interictal probably... still need to fix this');
            end
            try
                timesz = info.rawtimePoints(seizureMarkStart, 2)/fs;
                post_index = find(info.rawtimePoints(:, 2)/fs == (timesz + time));
            catch e
                timesz = info.timePoints(seizureMarkStart, 2)/fs;
                post_index = find(info.timePoints(:, 2)/fs == (timesz + time));
            end
            seizureMarkStart
            post_index
            if isempty(post_index)
                patient
            end
        end
        
        %% Store Results Locally to Speed Processing
        if ~interictal
            allfragmats{inds(ind)} = fragilityMat(:, seizureMarkStart:post_index);
        else
            allfragmats{inds(ind)} = fragilityMat;
            seizureMarkStart = size(fragilityMat, 2);
            seizureMarkEnd = size(fragilityMat, 2);
        end

        analstart = seizureMarkStart;
        if contains(patient, 'pt3')
            analstart = seizureMarkStart;
            allfragmats{inds(ind)} = fragilityMat(:, analstart:post_index);
        end

        % for pt8
        if contains(patient, 'pt8')
            analstart = seizureMarkStart;
            allfragmats{inds(ind)} = fragilityMat(:, analstart:post_index);
        end
        % for pt13
        if contains(patient, 'pt13')
            analstart = seizureMarkStart;
            post_index = seizureMarkEnd;
            allfragmats{inds(ind)} = fragilityMat(:, analstart:post_index);
        end
        
        % remove POL from labels
        included_labels = upper(included_labels);
        included_labels = strrep(included_labels, 'POL', '');
        included_labels = strtrim(included_labels);
        ezone_labels = strrep(ezone_labels, 'POL', '');
        ezone_labels = strtrim(ezone_labels);
        earlyspread_labels = strrep(earlyspread_labels, 'POL', '');
        latespread_labels = strrep(latespread_labels, 'POL', '');
        resection_labels = strrep(resection_labels, 'POL', '');
        
        % store the labels
        spread_labels = cat(2, earlyspread_labels, latespread_labels);
        allezlabels{inds(ind)} = ezone_labels;
        allspreadlabels{inds(ind)} = spread_labels;
        allresectionlabels{inds(ind)} = resection_labels;
        allincludedlabels{inds(ind)} = included_labels;
        allstartstop{inds(ind)} = [analstart, post_index];
        allseizuremarks{inds(ind)} = seizureMarkStart;
        
        %% plotting full fragility map
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
        
        % 1. plot the heatmap
        fig_heatmap = plotHeatmap(fragilityMat); % get the current figure
        ax = fig_heatmap.CurrentAxes; % get the current axes
        hold on;
        set(fig_heatmap, 'Units', 'inches');
        fig_heatmap.Position = [0.0417 0.6667 21.0694 13.0139];

        pause(0.005);
        % 2. label axes
        FONTSIZE = 13;
        PLOTARGS = struct();
        PLOTARGS.YAXFontSize = 9;
        PLOTARGS.FONTSIZE = FONTSIZE;
        PLOTARGS.xlabelStr = 'Time With Respect To Seizure (sec)';
        if isnan(info.seizure_estart_ms)
            PLOTARGS.xlabelStr = 'Time (sec)';
        end
        PLOTARGS.xlabelStr = 'Time (1 col = 1 window)';
        PLOTARGS.ylabelStr = 'Electrode Channels';
        PLOTARGS.titleStr = {[outcome, ': Fragility Metric (', strcat(patient_id, seizure_id), ')'], ...
                [perturbationType, ' Perturbation: ', ' Time Locked to Seizure']};
        labelHeatmap(ax, fig_heatmap,clinicalIndices, PLOTARGS);

        % move ylabel to the left a bit
        ylab = ax.YLabel;
        ylab.Position = ylab.Position + [-110 0 0]; % move ylabel to the left

        % label the colorbar
        colorArgs = struct();
        colorArgs.colorbarStr = 'Fragility Metric';
        colorArgs.FontSize = FONTSIZE;
        labelColorbar(ax, colorArgs)
        hold on;
        plot([seizureMarkStart seizureMarkStart], ax.YLim, 'k', 'LineWidth', 3, 'LineStyle', '-');
        hold on;
        plot([seizureMarkEnd seizureMarkEnd], ax.YLim, 'k', 'LineWidth', 3, 'LineStyle', '-')
        pause(0.005);
        
        %% Set X - Axis
        XLim = ax.XLim; XLowerLim = XLim(1); XUpperLim = XLim(2);
        xticks = ax.XTick - 1;
        if isnan(info.seizure_estart_ms)
            seizure_estart_mark = 1;
        end
        try
            if rem(info.rawtimePoints(1, 2), 1) ~= 0 || rem(info.rawtimePoints(2, 2), 1) ~= 0
                seizTime = info.rawtimePoints(seizure_estart_mark, 2);
                xticklabel = info.rawtimePoints(xticks, 2) - seizTime;
            else
                seizTime = info.rawtimePoints(seizure_estart_mark, 2)/fs;
                xticklabel = info.rawtimePoints(xticks, 2)/fs - seizTime;
            end
        catch e
            disp(e)
            if rem(info.timePoints(1, 2), 1) ~= 0 || rem(info.timePoints(2, 2), 1) ~= 0
                seizTime = info.timePoints(seizure_estart_mark, 2);
                xticklabel = info.timePoints(xticks, 2) - seizTime;
            else
                seizTime = info.timePoints(seizure_estart_mark, 2)/fs;
                xticklabel = info.timePoints(xticks, 2)/fs - seizTime;
            end
        end
        ax.XTick = xticks;
        ax.XTickLabel = xticklabel;
        xlim([XLowerLim, XUpperLim+1]);
        plot([analstart, analstart], ax.YLim, 'dr-', 'LineWidth', 3, 'LineStyle', '--');
        plot([post_index, post_index], ax.YLim, 'dr-', 'LineWidth', 3, 'LineStyle', '--');

        %% Second Plot
        xrange = 1:size(fragilityMat, 1);
        xrange(ezone_indices) = [];
        secfig = subplot(4,6, [6,12,18,24]);

        if interictal
            % compute on interictal
            [rowsum, excluded_indices, num_high_fragility] = computedoainterictal(fragilityMat, epsilon, NORMALIZE);
        else
            % compute on preictal
            [prerowsum, preexcluded_indices, prenum_high_fragility] = computedoaictal(fragilityMat, ...
                              analstart, post_index, epsilon, NORMALIZE);

            % compute on ictal
            [rowsum, excluded_indices, num_high_fragility] = computedoaictal(fragilityMat, ...
                            analstart, post_index, epsilon, NORMALIZE);
        end

        % compute weighted sum
        if ~interictal
            weightnew_sum = a1*rowsum + a2*num_high_fragility;
        else
            weightnew_sum = a1*rowsum + a2*num_high_fragility;
        end
        weightnew_sum = weightnew_sum ./ max(weightnew_sum); 

        weightnew_sum(weightnew_sum < threshold) = nan;
        stem(xrange, weightnew_sum(xrange), 'k'); hold on; axis tight;
        stem(ezone_indices, weightnew_sum(ezone_indices), 'r');

        plot(ax.XLim, [threshold threshold], 'k--');
        
        xoffset = 0.04;
        pos = get(gca, 'Position');
        pos(1) = pos(1) + xoffset;
        xlim([1 size(fragilityMat,1)]);
        set(gca, 'Xdir', 'reverse');
        set(gca, 'Position', pos);
        set(gca, 'XTick', []); set(gca, 'XTickLabel', []);
        set(gca, 'yaxislocation', 'right');
        set(gca, 'XAxisLocation', 'bottom');
        xlabel('Weighted Sum', 'FontSize', FONTSIZE-3);
        view([90 90])
        ax = gca;
        ax.XLabel.Rotation = 270;
        ax.XLabel.Position = ax.XLabel.Position + [0 max(ax.YLim)*1.05 0];

        toSaveFigFile = fullfile(figDir, strcat(patient, '_weightedsum_withwindows'));
        print(toSaveFigFile, '-dpng', '-r0')
        pause(1);

        close all;
        %% Plot the patient specific plot too
        pid =inds(ind);
        
        % find indices of certain channels for pt3
        fginds = find(cellfun('length',regexp(included_labels,'FG')) == 1);
        weightnew_sum(fginds) = 0;

        % compute DOA
        [doas(pid), fragilesets] = compute_doa_threshold(weightnew_sum, ezone_labels, included_labels, threshold, metric);        

        %% Plotting Per Patient
        fig_heatmap = figure();
        subplot(131);
        imagesc(allfragmats{pid});

        ax = fig_heatmap.CurrentAxes; % get the current axes
        clim = ax.CLim;
        hold on;
        set(fig_heatmap, 'Units', 'inches');
        % fig_heatmap.Position = [17.3438         0   15.9896   11.6771];
        fig_heatmap.Position = [0.0417 0.6667 21.0694 13.0139];

        pause(0.005);
        % 2. label axes
        FONTSIZE = 13;
        PLOTARGS = struct();
        PLOTARGS.YAXFontSize = 9;
        PLOTARGS.FONTSIZE = FONTSIZE;
        PLOTARGS.xlabelStr = 'Time (1 col = 1 window)';
        PLOTARGS.ylabelStr = 'Electrode Channels';
        PLOTARGS.titleStr = {['Fragility Metric (', strcat(patient), ')'], ...
                [perturbationType, ' Perturbation: ', ' Time Locked to Seizure']};
        labelHeatmap(ax, fig_heatmap,clinicalIndices, PLOTARGS);

        % move ylabel to the left a bit
        ylab = ax.YLabel;
        ylab.Position = ylab.Position + [-110 0 0]; % move ylabel to the left

        % label the colorbar
        colorArgs = struct();
        colorArgs.colorbarStr = 'Fragility Metric';
        colorArgs.FontSize = FONTSIZE;
        labelColorbar(ax, colorArgs)

        % compute high fragility regions
        threshMat = allfragmats{pid};
        threshMat(threshMat < epsilon) = nan;
        subplot(132);
        imagesc(threshMat); colorbar(); colormap('jet'); hold on; ax = gca;
        ax.CLim = clim;
        labelHeatmap(ax, fig_heatmap,clinicalIndices, PLOTARGS);

        % DOA Plot
        subplot(133);
        ax = gca; 
        plot(ax.XLim, [doas(pid), doas(pid)], 'k-');
        ax.YLim = [0, 1];
        title('Degree of Agreement')
        toSaveFigFile = fullfile(figDir, strcat(patient, '_doaanalysis'));
        print(toSaveFigFile, '-dpng', '-r0')

        pause(1);
        close all;

        ind = ind + 1;
    end
end

save('CCgridsearchictalfailuremats.mat', 'allfragmats', ...
    'allezlabels', 'allincludedlabels', ...
    'allspreadlabels', 'allresectionlabels', 'allseizuremarks', 'allstartstop');