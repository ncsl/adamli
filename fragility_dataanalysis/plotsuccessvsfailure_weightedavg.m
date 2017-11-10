clear all
clc
close all

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
% if     ~isempty(dir(eegRootDirServer)), dataDir = eegRootDirServer;
% elseif ~isempty(dir(eegRootDirHD)), dataDir = eegRootDirHD;
% elseif ~isempty(dir(eegRootDirJhu)), dataDir = eegRootDirJhu;
% elseif ~isempty(dir(eegRootDirMarcc)), dataDir = eegRootDirMarcc;
% else   error('Neither Work nor Home EEG directories exist! Exiting'); end

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

thresholds = [0.6, 0.7, 0.8, 0.9, 0.95];

figDir = fullfile(rootDir, '/figures', 'fragilityStats', ...
    strcat(filterType), ...
    strcat('perturbation', perturbationType, '_win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)));

if ~exist(figDir, 'dir')
    mkdir(figDir);
end


%% load the fragility mats and grid search results
load('gridsearchictalsuccessmats_v2.mat');
load('CCgridsearchictalsuccessmats.mat');

% NIH success patients
patients = {...,
    {'pt1sz2','pt1sz3', 'pt1sz4'}, ...},...
    {'pt2sz1' 'pt2sz3' , 'pt2sz4'}, ...}, ...
    {'pt3sz2' 'pt3sz4'}, ...}, ...
    {'pt8sz1' 'pt8sz2' 'pt8sz3'},...
    {'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5'},...
    {'pt15sz1' 'pt15sz4'},...
};
% CC
patients = {,...
    {'LA01_ICTAL', 'LA01_Inter'},...
    {'LA02_ICTAL', 'LA02_Inter'}, ...
};

epsilon = 0.8;
a1 = 0.8;
a2 = 0.2;
a3=0;
threshold=0.35;

%% Create result matrices to store doa
% to see what the doa is of combined per patient
combinedoa = zeros(length(patients), 1);

% to keep track of regular doa for every patient
doa = zeros(length([patients{:}]), 1);
group_ind = 1;
pat_ind = 1;
NORMALIZE = 1;
%% Compute DOA For All Patients
doas = zeros(length([patients{:}]), 1);

successavg_weightsums = cell(length(patients), 1);
for iGroup=1:length(patients)
    patient_group = patients{iGroup};
    
    for pid=1:length(patient_group) % loop through each patient
        patient = patient_group{pid}
        buffpid = pid;
        pid = pat_ind
        if contains(lower(patient), 'aw') || contains(lower(patient), 'aslp') || contains(lower(patient), 'inter')
            interictal = 1;
        else
            interictal = 0;
        end

        fragilityMat = allfragmats{pid};
        ezone_labels = allezlabels{pid};
        included_labels = allincludedlabels{pid};
        resection_labels = allresectionlabels{pid};
        spread_labels = allspreadlabels{pid};
        % remove POL from labels
        included_labels = upper(included_labels);
        included_labels = strrep(included_labels, 'POL', '');
        included_labels = strtrim(included_labels);
        ezone_labels = strrep(ezone_labels, 'POL', '');
        ezone_labels = strtrim(ezone_labels);
        resection_labels = strrep(resection_labels, 'POL', '');
        spread_labels = strrep(spread_labels, 'POL', '');

        % initialize the weighted sums for all patients
        if buffpid==1
            weighted_sums = zeros(length(included_labels), length(patient_group));
        end
        
        if interictal
            % compute on interictal
            [rowsum, excluded_indices, num_high_fragility] = computedoainterictal(fragilityMat, epsilon, NORMALIZE);
        else
            % compute on preictal
            [prerowsum, preexcluded_indices, prenum_high_fragility] = computedoaictal(fragilityMat, ...
                              1, size(fragilityMat, 2), epsilon, NORMALIZE);

            % compute on ictal
            [rowsum, excluded_indices, num_high_fragility] = computedoaictal(fragilityMat, ...
                            1, size(fragilityMat, 2), epsilon, NORMALIZE);
        end

        % compute weighted sum
        if ~interictal
            weightnew_sum = a1*rowsum + a2*num_high_fragility; 
        else
            weightnew_sum = a1*rowsum + a2*num_high_fragility;
        end
        weightnew_sum = weightnew_sum ./ max(weightnew_sum); 

        % find indices of certain channels for pt3
        fginds = find(cellfun('length',regexp(included_labels,'FG')) == 1);
        weightnew_sum(fginds) = 0;
        
        weighted_sums(:, buffpid) = weightnew_sum;

        % compute DOA
        [doas(pat_ind), fragilesets] = compute_doa_threshold(weightnew_sum, ezone_labels, included_labels, threshold, metric);        

        % increment patient index
        pat_ind = pat_ind + 1;
        patient
        fragilesets
        ezone_labels

        %% Plotting Per Patient
    %     % Get Indices for All Clinical Annotations on electrodes
    %     ezone_indices = findElectrodeIndices(ezone_labels, included_labels);
    %     spread_indices = findElectrodeIndices(spread_labels, included_labels);
    %     resection_indices = findElectrodeIndices(resection_labels, included_labels);
    % 
    %     [num_channels, num_wins] = size(fragilityMat);
    %     allYTicks = 1:num_channels; 
    %     y_indices = setdiff(allYTicks, [ezone_indices; spread_indices]);
    %     y_ezoneindices = sort(ezone_indices);
    %     y_earlyspreadindices = sort(spread_indices);
    %     y_latespreadindices = [];
    %     y_resectionindices = resection_indices;
    % 
    %     % create struct for clinical indices
    %     clinicalIndices.all_indices = y_indices;
    %     clinicalIndices.ezone_indices = y_ezoneindices;
    %     clinicalIndices.earlyspread_indices = y_earlyspreadindices;
    %     clinicalIndices.latespread_indices = y_latespreadindices;
    %     clinicalIndices.resection_indices = y_resectionindices;
    %     clinicalIndices.included_labels = included_labels;
    %     
    %     fig_heatmap = figure();
    %     subplot(131);
    %     imagesc(fragilityMat);
    %     
    %     ax = fig_heatmap.CurrentAxes; % get the current axes
    %     clim = ax.CLim;
    %     hold on;
    %     set(fig_heatmap, 'Units', 'inches');
    %     % fig_heatmap.Position = [17.3438         0   15.9896   11.6771];
    %     fig_heatmap.Position = [0.0417 0.6667 21.0694 13.0139];
    % 
    %     pause(0.005);
    %     % 2. label axes
    %     FONTSIZE = 13;
    %     PLOTARGS = struct();
    %     PLOTARGS.YAXFontSize = 9;
    %     PLOTARGS.FONTSIZE = FONTSIZE;
    %     PLOTARGS.xlabelStr = 'Time (1 col = 1 window)';
    %     PLOTARGS.ylabelStr = 'Electrode Channels';
    %     PLOTARGS.titleStr = {['Fragility Metric (', strcat(patient), ')'], ...
    %             [perturbationType, ' Perturbation: ', ' Time Locked to Seizure']};
    %     % PLOTARGS.titleStr = {[outcome, ': Fragility Metric (', patient_id, ')'], ...
    %     %     [perturbationType, ' Perturbation: ']};
    %     labelHeatmap(ax, fig_heatmap,clinicalIndices, PLOTARGS);
    % 
    %     % move ylabel to the left a bit
    %     ylab = ax.YLabel;
    %     ylab.Position = ylab.Position + [-110 0 0]; % move ylabel to the left
    % 
    %     % label the colorbar
    %     colorArgs = struct();
    %     colorArgs.colorbarStr = 'Fragility Metric';
    %     colorArgs.FontSize = FONTSIZE;
    %     labelColorbar(ax, colorArgs)
    % 
    %     
    %     % compute high fragility regions
    %     threshMat = fragilityMat;
    %     threshMat(fragilityMat < epsilon) = nan;
    %     subplot(132);
    %     imagesc(threshMat); colorbar(); colormap('jet'); hold on; ax = gca;
    %     ax.CLim = clim;
    %     labelHeatmap(ax, fig_heatmap,clinicalIndices, PLOTARGS);
    % 
    %     
    %     % DOA Plot
    %     subplot(133);
    %     ax = gca; 
    %     plot(ax.XLim, [doas(pid), doas(pid)], 'k-');
    %     ax.YLim = [0, 1];
    %     title('Degree of Agreement')
    %     toSaveFigFile = fullfile(figDir, strcat(patient, '_doaanalysis'));
    %     print(toSaveFigFile, '-dpng', '-r0')
    % 
    %     pause(1);
    %     close all;
    end % end of loop through all patients
    
    weighted_sums(isnan(weighted_sums)) = 0;
    successavg_weightsums{iGroup} = mean(weighted_sums, 2);
    
    % compute DOA
    [avgdoa, fragilesets] = compute_doa_threshold(successavg_weightsums{iGroup}, ezone_labels, included_labels, threshold, metric);        

    % combine per patient
    combinedoa(iGroup) = avgdoa;
    
    % plot all weighted avg weight sums
%     xrange = 1:length(included_labels);
%     ezone_indices = findElectrodeIndices(ezone_labels, included_labels);
%     xrange(ezone_indices) = [];
%     figure;
%     stem(xrange,  successavg_weightsums{iGroup}(xrange), 'k'); hold on; axis tight;
%     ax = gca;
%     stem(ezone_indices,  successavg_weightsums{iGroup}(ezone_indices), 'r');
%     title(patient);
%     plot(ax.XLim, [threshold threshold], 'k--');
%     
%     close all;
end
%% Doas for Failure pats
% NIH
failurepatients = {,...
    {'pt6sz3', 'pt6sz4', 'pt6sz5'},...
    {'pt7sz19', 'pt7sz21', 'pt7sz22'},...
    {'pt10sz1','pt10sz2' 'pt10sz3'}, ...
    {'pt12sz1', 'pt12sz2'},...
    {'pt14sz1' 'pt14sz2' 'pt14sz3'}, ...
};

% CC
failurepatients = {,...
%     'LA02_ICTAL', 'LA02_Inter',...
    {'LA04_ICTAL','LA04_Inter'}, ...
    {'LA06_ICTAL', 'LA06_Inter'}, ...
    {'LA08_ICTAL', 'LA08_Inter'}, ...
    {'LA11_ICTAL', 'LA11_Inter'}, ...
    {'LA15_ICTAL', 'LA15_Inter'}, ...
    {'LA16_ICTAL', 'LA16_Inter'}, ...
};

load('gridsearchictalfailuremats_v2.mat');
load('CCgridsearchictalfailuremats.mat');
%% Compute DOA For All Patients

faildoas = zeros(length([failurepatients{:}]), 1);
% to see what the doa is of combined per patient
failcombinedoa = zeros(length(failurepatients), 1);
pat_ind = 1;
failavg_weightsums = cell(length(failurepatients), 1);
for iGroup=1:length(failurepatients)
    patient_group = failurepatients{iGroup};
    
    for pid=1:length(patient_group) % loop through each patient
        patient = patient_group{pid}
        buffpid = pid;
        pid = pat_ind
        
        if contains(lower(patient), 'aw') || contains(lower(patient), 'aslp') || contains(lower(patient), 'inter')
            interictal = 1;
        else
            interictal = 0;
        end

        fragilityMat = allfragmats{pid};
        ezone_labels = allezlabels{pid};
        included_labels = allincludedlabels{pid};
        % remove POL from labels
        included_labels = upper(included_labels);
        included_labels = strrep(included_labels, 'POL', '');
        included_labels = strtrim(included_labels);
        ezone_labels = strrep(ezone_labels, 'POL', '');
        ezone_labels = strtrim(ezone_labels);

        if buffpid==1
            weighted_sums = zeros(length(included_labels), length(patient_group));
        end
        if interictal
            % compute on interictal
            [rowsum, excluded_indices, num_high_fragility] = computedoainterictal(fragilityMat, epsilon, NORMALIZE);
        else
            % compute on preictal
            [prerowsum, preexcluded_indices, prenum_high_fragility] = computedoaictal(fragilityMat, ...
                              1, size(fragilityMat, 2), epsilon, NORMALIZE);

            % compute on ictal
            [rowsum, excluded_indices, num_high_fragility] = computedoaictal(fragilityMat, ...
                            1, size(fragilityMat, 2), epsilon, NORMALIZE);
        end

        % compute weighted sum
        if ~interictal
            weightnew_sum = a1*rowsum + a2*num_high_fragility;
        else
            weightnew_sum = a1*rowsum + a2*num_high_fragility;
        end
        weightnew_sum = weightnew_sum ./ max(weightnew_sum); 

        % compute DOA
        [faildoas(pid), fragilesets] = compute_doa_threshold(weightnew_sum, ezone_labels, included_labels, threshold, metric);        

        if strcmp(patient, 'pt14sz1')
            faildoas(pid) = [];
        end
        
        weighted_sums(:, buffpid) = weightnew_sum;
        
        % increment patient index
        pat_ind = pat_ind + 1;
    end % end of loop through all patients

    weighted_sums(isnan(weighted_sums)) = 0;
    failavg_weightsums{iGroup} = mean(weighted_sums, 2);
    
    % compute DOA
    [avgdoa, fragilesets] = compute_doa_threshold(failavg_weightsums{iGroup}, ezone_labels, included_labels, threshold, metric);        

    % combine per patient
    failcombinedoa(iGroup) = avgdoa;
    
    % plot all weighted avg weight sums
%     xrange = 1:length(included_labels);
%     ezone_indices = findElectrodeIndices(ezone_labels, included_labels);
%     xrange(ezone_indices) = [];
%     figure;
%     stem(xrange, failavg_weightsums{iGroup}(xrange), 'k'); hold on; axis tight;
%     ax = gca;
%     stem(ezone_indices, failavg_weightsums{iGroup}(ezone_indices), 'r');
%     title(patient);
%     plot(ax.XLim, [threshold threshold], 'k--');
%     
%     close all;
end
%% Combine DOAS per patient
% patients = {...,
%     'pt1sz2', 'pt1sz3', 'pt1sz4', ...},...
%     'pt2sz1' 'pt2sz3' , 'pt2sz4', ...}, ...
%     'pt3sz2' 'pt3sz4', ...}, ...
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
%     'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
% };
% patinds = [1, 1, 1, ...
%            2, 2, 2, ...
%            3, 3, ...
%            4, 4, 4, ...
%            5, 5, 5, 5, ...
%            6, 6, 6, 6, ...
%            ];

% compute doas and combine per patient to come up with 1 DOA per patient

%% Plot each weighted sum average
% figure;
% for i=1:length(failavg_weightsums)
%     subplot(length(failavg_weightsums), 1, i);
%     stem(xrange, weightnew_sum(xrange), 'k'); hold on; axis tight;
%     stem(ezone_indices, weightnew_sum(ezone_indices), 'r');
% end
% 
% figure;
% for i=1:length(successavg_weightsums)
%     subplot(length(successavg_weightsums), 1, i);
% end

%% Plot Relevant DOA
toplotdoas = [combinedoa; failcombinedoa];
toplotx = [ones(length(combinedoa), 1); ones(length(failcombinedoa),1)*2];
group = [repmat({'Success'}, length(combinedoa), 1); repmat({'Failure'}, length(failcombinedoa), 1)];

fig = figure;
%% Plot successes
% first plot boxplot
bh = boxplot(toplotdoas, group,'Whisker',1); hold on; axes = gca; currfig = gcf;
% second plot points with jitter on the x-axis
xvals = jitterxaxis(toplotx);
plot(xvals, toplotdoas, 'ko');
title(['CC LA Success Vs. Failure N=11 with #Points=', num2str(length(patients)+length(failurepatients))]);
if strcmp(metric, 'jaccard')
    axes.YLim = [0, 1];
    ylabel('Jaccard Index');
else 
    axes.YLim = [-1, 1];
    ylabel('DOA');
end
% plot(1, mean(doas), 'dg')
% plot(2, mean(faildoas), 'dg')
axes.FontSize = FONTSIZE;
toSaveFigFile = fullfile(figDir, strcat('CC', 'combined_doaanalysis'));
print(toSaveFigFile, '-dpng', '-r0')
