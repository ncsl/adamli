function analyzeEZTPerturbations(patient_id, seizure_id, perturbationType, threshold, winSize, stepSize)
    close all;
if nargin == 0
    addpath('./fragility_library/');
    patient_id = '007';
    seizure_id = '_seiz001';
    radius = 1.1;
    w_space = linspace(-1, 1, 101);
    perturbationType = 'R';
    winSize = 500;
    stepSize = 500;
    included_channels = 0;
    patient_id = 'EZT007';
    perturbationType = 'C';
    threshold = 0.8;
end
                % can delete once, included_channels included in datafiles
                if strcmp(patient_id, '007')
                    included_channels = [];
                    ezone_labels = {'O7', 'E8', 'E7', 'I5', 'E9', 'I6', 'E3', 'E2',...
                        'O4', 'O5', 'I8', 'I7', 'E10', 'E1', 'O6', 'I1', 'I9', 'E6',...
                        'I4', 'O3', 'O2', 'I10', 'E4', 'Y1', 'O1', 'I3', 'I2'}; %pt1
                    earlyspread_labels = {};
                    latespread_labels = {};
                elseif strcmp(patient_id, '005')
                    included_channels = [];
                    ezone_labels = {'U4', 'U3', 'U5', 'U6', 'U8', 'U7'}; 
                    earlyspread_labels = {};
                     latespread_labels = {};
                elseif strcmp(patient_id, '019')
                    included_channels = [];
                    ezone_labels = {'I5', 'I6', 'B9', 'I9', 'T10', 'I10', 'B6', 'I4', ...
                        'T9', 'I7', 'B3', 'B5', 'B4', 'I8', 'T6', 'B10', 'T3', ...
                        'B1', 'T8', 'T7', 'B7', 'I3', 'B2', 'I2', 'T4', 'T2'}; 
                    earlyspread_labels = {};
                     latespread_labels = {}; 
                 elseif strcmp(patient_id, '045') % FAILURES 2 EZONE LABELS?
                    included_channels = [];
                    ezone_labels = {'X2', 'X1'}; %pt2
                    earlyspread_labels = {};
                     latespread_labels = {}; 
                  elseif strcmp(patient_id, '090') % FAILURES
                    included_channels = [];
                    ezone_labels = {'N2', 'N1', 'N3', 'N8', 'N9', 'N6', 'N7', 'N5'}; 
                    earlyspread_labels = {};
                     latespread_labels = {}; 
                elseif strcmp(patient_id, 'pt7')
                    included_channels = [1:17 19:35 37:38 41:62 67:109];
                    ezone_labels = {};
                    earlyspread_labels = {};
                    latespread_labels = {};
                elseif strcmp(patient_id, 'pt1')
                    included_channels = [1:36 42 43 46:69 72:95];
                    ezone_labels = {'POLATT1', 'POLATT2', 'POLAD1', 'POLAD2', 'POLAD3'}; %pt1
                    earlyspread_labels = {'POLATT3', 'POLAST1', 'POLAST2'};
                    latespread_labels = {'POLATT4', 'POLATT5', 'POLATT6', ...
                                        'POLSLT2', 'POLSLT3', 'POLSLT4', ...
                                        'POLMLT2', 'POLMLT3', 'POLMLT4', 'POLG8', 'POLG16'};
                elseif strcmp(patient_id, 'pt2')
                %     included_channels = [1:19 21:37 43 44 47:74 75 79]; %pt2
                    included_channels = [1:14 16:19 21:25 27:37 43 44 47:74];
                    ezone_labels = {'POLMST1', 'POLPST1', 'POLTT1'}; %pt2
                    earlyspread_labels = {'POLTT2', 'POLAST2', 'POLMST2', 'POLPST2', 'POLALEX1', 'POLALEX5'};
                     latespread_labels = {};
                elseif strcmp(patient_id, 'JH105')
                    included_channels = [1:4 7:12 14:19 21:37 42 43 46:49 51:53 55:75 78:99]; % JH105
                    ezone_labels = {'POLRPG4', 'POLRPG5', 'POLRPG6', 'POLRPG12', 'POLRPG13', 'POLG14',...
                        'POLAPD1', 'POLAPD2', 'POLAPD3', 'POLAPD4', 'POLAPD5', 'POLAPD6', 'POLAPD7', 'POLAPD8', ...
                        'POLPPD1', 'POLPPD2', 'POLPPD3', 'POLPPD4', 'POLPPD5', 'POLPPD6', 'POLPPD7', 'POLPPD8', ...
                        'POLASI3', 'POLPSI5', 'POLPSI6', 'POLPDI2'}; % JH105
                    earlyspread_labels = {};
                     latespread_labels = {};
                end

patient = strcat(patient_id, seizure_id);
%% 0: Initialize Variables, EZONE, EarlySpread and LateSpread Indices
%- initialize directories and labels
adjDir = fullfile(strcat('./adj_mats_win', num2str(winSize), ...
    '_step', num2str(stepSize)));
finalDataDir = fullfile(adjDir, strcat(perturbationType, '_finaldata')); % data computed from computePerturbations.m
%- set file path for the patient file 
dataDir = './data/';
patient_eeg_path = fullfile('./data/Seiz_Data/', patient_id, patient);
eegdata = load(patient_eeg_path);
labels = eegdata.elec_labels;

% load in example and processed data
final_data = load(fullfile(finalDataDir, strcat(patient, 'final_data'))); % load in final data mat
data = load(fullfile(adjDir, patient, strcat(patient, '_1_before60000')));    % load in example preprocessed mat
data = data.data;

%- load in meta data from example preprocessed mat
try
seizureTime = data.seizureTime / 1000;
timeStart    = data.timeStart / 1000;
timeEnd      = data.timeEnd / 1000;
seizureEnd   = data.seizureEnd / 1000;
winSize      = data.winSize;
stepSize     = data.stepSize;
included_channels = data.included_channels;
ezone_labels = data.ezone_labels;
earlyspread_labels = data.earlyspread_labels;
latespread_labels  = data.latespread_labels;
catch
    disp('Not yet data set.');
end

% define cell function to search for the EZ labels
cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));
ezone_indices = zeros(length(ezone_labels),1);
for i=1:length(ezone_labels)
    indice = cellfun(cellfind(ezone_labels{i}), labels, 'UniformOutput', 0);
    indice = [indice{:}];
    test = 1:length(labels);
    if ~isempty(test(indice))
        ezone_indices(i) = test(indice);
    end
end

earlyspread_indices = zeros(length(earlyspread_labels),1);
for i=1:length(earlyspread_labels)
    indice = cellfun(cellfind(earlyspread_labels{i}), labels, 'UniformOutput', 0);
    indice = [indice{:}];
    test = 1:length(labels);
    if ~isempty(test(indice))
        earlyspread_indices(i) = test(indice);
    end
end
earlyspread_indices(earlyspread_indices==0) =  [];

latespread_indices = zeros(length(latespread_labels),1);
if strcmp(patient_id, 'pt1')
    for i=1:length(latespread_labels)
        indice = cellfun(cellfind(latespread_labels{i}), labels, 'UniformOutput', 0);
        indice = [indice{:}];
        test = 1:length(labels);
        if ~isempty(test(indice))
            latespread_indices(i) = test(indice);
        end
    end
end

%% 1: Extract Processed Data and Begin Plotting and Save in finalDataDir
minPerturb_time_chan = final_data.minPerturb_time_chan;
fragility_rankings = final_data.fragility_rankings;
rowsum_time_chan = final_data.rowsum_time_chan;
colsum_time_chan = final_data.colsum_time_chan;

if (size(fragility_rankings,2) > 121)
    fragility_rankings = fragility_rankings(:,1:120);
    minPerturb_time_chan = minPerturb_time_chan(:,1:120);
end

%%- 1a) Apply thresholding to fragility_rankings
threshold_fragility = fragility_rankings;
threshold_fragility(threshold_fragility > threshold) = 1;
threshold_fragility(threshold_fragility <= threshold) = 0;
rowsum = sum(threshold_fragility,2); rowsum = rowsum/max(rowsum);
[sorted_weights, ind_sorted_weights] = sort(rowsum, 'descend'); % find the electrode's rowsums in descending order and the indices
sorted_fragility = fragility_rankings(ind_sorted_weights,:); % create the sorted fragility

%%- 1b) print weights into an excel file
elecWeightsDir = fullfile('./acc_figures/', strcat(perturbationType, '_electrode_weights'));
if ~exist(elecWeightsDir, 'dir')
    mkdir(elecWeightsDir);
end
weight_file = fullfile(elecWeightsDir, strcat(patient, 'electrodeWeights.csv'));
fid = fopen(weight_file, 'w');
sorted_labels = labels(ind_sorted_weights);
for i=1:length(labels)
    fprintf(fid, '%6s, %f \n', sorted_labels{i}, sorted_weights(i)); 
end
fclose(fid);

%% 2. Plotting
FONTSIZE = 22;
YAXFontSize = 9;
LT = 1.5;
figDir = fullfile('./acc_figures/', perturbationType);
if ~exist(figDir, 'dir')
    mkdir(figDir);
end
if ~exist(fullfile(figDir, patient), 'dir')
    mkdir(fullfile(figDir, patient));
end

xticks = (timeStart - seizureTime) : 5 : (timeEnd - seizureTime);
ytick = 1:size(fragility_rankings, 1);
y_indices = setdiff(ytick, [ezone_indices; earlyspread_indices]);
if sum(latespread_indices > 0)
    latespread_indices(latespread_indices ==0) = [];
    y_indices = setdiff(ytick, [ezone_indices; earlyspread_indices; latespread_indices]);
end
y_ezoneindices = sort(ezone_indices);
y_earlyspreadindices = sort(earlyspread_indices);
y_latespreadindices = sort(latespread_indices);

fig = {};

%- 2a) plotting sorted_weights
figure;
plot(sorted_weights); hold on; 
ax = gca; 
set(ax, 'box', 'off');
title(['Ranking of Electrodes Based on Threshold ', num2str(threshold)], 'FontSize', FONTSIZE);
xlabel('electrodes');
set(ax, 'XTick', ax.XLim(1):ax.XLim(2), 'XTickLabels', sorted_labels, 'XTickLabelRotation', 90);
ylabel('Ranking of Electrodes Based on Fragility Metric')
currfig = gcf;
currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
currfig.Position = [1986           1        1535        1121];
print(fullfile(figDir, patient, strcat(patient, 'electrodeRanks')), '-dpng', '-r0')

% - 2b) minimum perturbation over time and channels:
fig{end+1} = figure;
imagesc(minPerturb_time_chan); hold on;
c = colorbar(); colormap('jet'); set(gca,'box','off')
set(gca,'YDir','normal');
XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
% set title, labels and ticks
xticks = (timeStart - seizureTime) : 5 : (timeEnd - seizureTime);
titleStr = {'Minimum Norm Perturbation For All Channels', ...
    'Time Locked To Seizure'};
title(titleStr, 'FontSize', FONTSIZE+2);
ax1 = gca;
ylabel(c, 'Minimum L2-Norm Perturbation');
xlabel('Time (sec)', 'FontSize', FONTSIZE);  
ylab = ylabel('Electrode Channels', 'FontSize', FONTSIZE);
set(gca, 'FontSize', FONTSIZE-3, 'LineWidth', LT);
set(gca, 'XTick', (XLowerLim+0.5:10:XUpperLim+0.5)); set(gca, 'XTickLabel', xticks); % set xticks and their labels
set(gca, 'YTick', [1, 5:5:length(included_channels)]);
currfig = gcf;
currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
currfig.Position = [1986           1        1535        1121];
% move ylabel to the left
ylab.Position = ylab.Position + [-.25 0 0];
% plot start star's for the different clinical annotations
xlim([XLowerLim, XUpperLim+1]);
plot(repmat(XUpperLim+1, length(ezone_indices),1), ezone_indices, '*r');
plot(repmat(XUpperLim+1, length(earlyspread_indices), 1), earlyspread_indices, '*', 'color', [1 .5 0]);
if sum(latespread_indices) > 0
    plot(repmat(XUpperLim+1, length(latespread_indices),1), latespread_indices, '*', 'color', 'blue');
end
plotOptions = struct();
plotOptions.YAXFontSize = YAXFontSize;
plotOptions.FONTSIZE = FONTSIZE;
plotOptions.LT = LT;
plotIndices(currfig, plotOptions, y_indices, labels, ...
                            y_ezoneindices, ...
                            y_earlyspreadindices, ...
                            y_latespreadindices)
%- save the figure
% savefig(fullfile(figDir, strcat(patient, 'minPerturbation')));
print(fullfile(figDir, patient, strcat(patient, 'minPerturbation')), '-dpng', '-r0')

%- 2c) fragility_ranking over time and channels
fig{end+1} = figure;
imagesc(fragility_rankings); hold on;
c = colorbar(); set(c, 'fontsize', FONTSIZE); colormap('jet'); set(gca,'box','off')
titleStr = {['Fragility Ranking Of Each Channel (', patient ')'], ...
    'Time Locked To Seizure'};
XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
title(titleStr, 'FontSize', FONTSIZE+5);
ylabel(c, 'Fragility Ranking', 'FontSize', FONTSIZE);
xlabel('Time (sec)', 'FontSize', FONTSIZE);  
ylab = ylabel('Electrode Channels', 'FontSize', FONTSIZE);
set(gca, 'FontSize', FONTSIZE-3, 'LineWidth', LT); set(gca,'YDir','normal');
set(gca, 'XTick', (XLowerLim+0.5:10:XUpperLim+0.5)); set(gca, 'XTickLabel', xticks, 'fontsize', FONTSIZE); % set xticks and their labels
a = get(gca,'XTickLabel'); set(gca,'XTickLabel',a,'fontsize',FONTSIZE); % setting some fontsize
set(gca, 'YTick', [1, 5:5:length(included_channels)]);
currfig = gcf;
currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
currfig.Position = [1986           1        1535        1121];
% move ylabel to the left
ylab.Position = ylab.Position + [-.25 0 0];
% plot start star's for the different clinical annotations
xlim([XLowerLim, XUpperLim+1]);
plot(repmat(XUpperLim+1, length(ezone_indices),1), ezone_indices, '*r');
plot(repmat(XUpperLim+1, length(earlyspread_indices), 1), earlyspread_indices, '*', 'color', [1 .5 0]);
if sum(latespread_indices) > 0
    plot(repmat(XUpperLim+1, length(latespread_indices),1), latespread_indices, '*', 'color', 'blue');
end
plotOptions = struct();
plotOptions.YAXFontSize = YAXFontSize;
plotOptions.FONTSIZE = FONTSIZE;
plotOptions.LT = LT;
plotIndices(currfig, plotOptions, y_indices, labels, ...
                            y_ezoneindices, ...
                            y_earlyspreadindices, ...
                            y_latespreadindices)

% savefig(fullfile(figDir, strcat(patient, 'fragilityRanking')));
print(fullfile(figDir, patient, strcat(patient, 'fragilityRanking')), '-dpng', '-r0')

%% sort by rowsum of fragility ranking metrics
rowsum_fragility = sum(fragility_rankings, 2);
[vals, ind] = sort(rowsum_fragility); % sort in descending order

% get indices for each clinical annotation
ind_sorted_weights = ind;
[a, b] = ismember(ind_sorted_weights, ezone_indices);
b(b==0) = [];
ezone_indices = ezone_indices(b);

[a, b] = ismember(ind_sorted_weights, earlyspread_indices);
b(b==0) = [];
earlyspread_indices = earlyspread_indices(b);

[a, b] = ismember(ind_sorted_weights, latespread_indices);
b(b==0) = [];
latespread_indices = latespread_indices(b);

ytick = 1:size(fragility_rankings, 1);
y_indices = ind_sorted_weights(~ismember(ind_sorted_weights, [ezone_indices; earlyspread_indices]));
% y_indices = setdiff(ytick, [ezone_indices; earlyspread_indices]);
if sum(latespread_indices > 0)
    latespread_indices(latespread_indices ==0) = [];
    y_indices = ind_sorted_weights(~ismember(ind_sorted_weights, [ezone_indices; earlyspread_indices; latespread_indices]));
end
yticks = ytick(ismember(ind_sorted_weights, y_indices)); % index thru sorted_labels
ezone_ticks = ytick(ismember(ind_sorted_weights, ezone_indices));
earlyspread_ticks = ytick(ismember(ind_sorted_weights, earlyspread_indices));
latespread_ticks = 0;
if (sum(latespread_indices) > 0)
    latespread_ticks = ytick(ismember(ind_sorted_weights, latespread_indices));
end

%% Heatmap of sorted fragility ranks
fig{end+1} = figure; 
imagesc(fragility_rankings(ind,:)); hold on;  
c = colorbar(); colormap('jet'); set(gca,'box','off'); set(c, 'fontsize', FONTSIZE); 
XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
% set title, labels and ticks
titleStr = {['Fragility Sorted By RowSum ', patient], ... 
    'perturbation: ', perturbationType, ...
    'Time Locked To Seizure'};
title(titleStr, 'FontSize', FONTSIZE+2);
set(gca, 'FontSize', FONTSIZE-3, 'LineWidth', LT); set(gca,'YDir','normal');
set(gca, 'XTick', (XLowerLim+0.5:10:XUpperLim+0.5)); set(gca, 'XTickLabel', xticks, 'fontsize', FONTSIZE); % set xticks and their labels
a = get(gca,'XTickLabel'); set(gca,'XTickLabel',a,'fontsize',FONTSIZE)
title(titleStr, 'FontSize', FONTSIZE+5);
ylabel(c, 'Fragility Ranking', 'FontSize', FONTSIZE);
xlabel('Time (sec)', 'FontSize', FONTSIZE);  
ylab = ylabel('Electrode Channels', 'FontSize', FONTSIZE);
% move ylabel to the left
ylab.Position = ylab.Position + [-.25 0 0];
set(gca, 'YTick', [1, 5:5:length(included_channels)]);

currfig = gcf;
currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
currfig.Position = [1986           1        1535        1121]; %workstation
% currfig.Position = [1 55 1440 773];
% add the labels for the EZ electrodes (rows)
xlim([XLowerLim XUpperLim+1]); % increase the xlim by 1, to mark regions of EZ
plot(repmat(XUpperLim+1, length(ezone_indices),1), ezone_ticks, '*r');
plot(repmat(XUpperLim+1, length(earlyspread_indices), 1), earlyspread_ticks, '*', 'color', [1 .5 0]);
if sum(latespread_indices) > 0
    plot(repmat(XUpperLim+1, length(latespread_indices),1), latespread_ticks, '*', 'color', 'blue');
end
plotOptions = struct();
plotOptions.YAXFontSize = YAXFontSize;
plotOptions.FONTSIZE = FONTSIZE;
plotOptions.LT = LT;
plotIndices(currfig, plotOptions, yticks, labels, ...
                            ezone_ticks, ...
                            earlyspread_ticks, ...
                            latespread_ticks)

% savefig(fullfile(figDir, strcat(patient, 'sortedFragility')));
print(fullfile(figDir, patient, strcat(patient, 'sortedRowSumFragility')), '-dpng', '-r0')


%- 2d) re-sort the labels to plot the sorted fragility map
% [a, b] = ismember(ind_sorted_weights, ezone_indices);
% b(b==0) = [];
% ezone_indices = ezone_indices(b);
% 
% [a, b] = ismember(ind_sorted_weights, earlyspread_indices);
% b(b==0) = [];
% earlyspread_indices = earlyspread_indices(b);
% 
% [a, b] = ismember(ind_sorted_weights, latespread_indices);
% b(b==0) = [];
% latespread_indices = latespread_indices(b);
% 
% ytick = 1:length(included_channels);
% y_indices = ind_sorted_weights(~ismember(ind_sorted_weights, [ezone_indices; earlyspread_indices]));
% % y_indices = setdiff(ytick, [ezone_indices; earlyspread_indices]);
% if sum(latespread_indices > 0)
%     latespread_indices(latespread_indices ==0) = [];
%     y_indices = ind_sorted_weights(~ismember(ind_sorted_weights, [ezone_indices; earlyspread_indices; latespread_indices]));
% end
% yticks = ytick(ismember(ind_sorted_weights, y_indices)); % index thru sorted_labels
% ezone_ticks = ytick(ismember(ind_sorted_weights, ezone_indices));
% earlyspread_ticks = ytick(ismember(ind_sorted_weights, earlyspread_indices));
% latespread_ticks = 0;
% if (sum(latespread_indices) > 0)
%     latespread_ticks = ytick(ismember(ind_sorted_weights, latespread_indices));
% end
% 
% %%- Heatmap of sorted fragility ranks
% fig{end+1} = figure; 
% imagesc(sorted_fragility); hold on;  
% c = colorbar(); colormap('jet'); set(gca,'box','off'); set(c, 'fontsize', FONTSIZE); 
% XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
% % set title, labels and ticks
% titleStr = {['Fragility Sorted By Rank ', patient], ...
%     'Time Locked To Seizure'};
% title(titleStr, 'FontSize', FONTSIZE+2);
% set(gca, 'FontSize', FONTSIZE-3, 'LineWidth', LT); set(gca,'YDir','normal');
% set(gca, 'XTick', (XLowerLim+0.5:10:XUpperLim+0.5)); set(gca, 'XTickLabel', xticks, 'fontsize', FONTSIZE); % set xticks and their labels
% a = get(gca,'XTickLabel'); set(gca,'XTickLabel',a,'fontsize',FONTSIZE)
% title(titleStr, 'FontSize', FONTSIZE+5);
% ylabel(c, 'Fragility Ranking', 'FontSize', FONTSIZE);
% xlabel('Time (sec)', 'FontSize', FONTSIZE);  
% ylab = ylabel('Electrode Channels', 'FontSize', FONTSIZE);
% % move ylabel to the left
% ylab.Position = ylab.Position + [-.25 0 0];
% set(gca, 'YTick', [1, 5:5:length(included_channels)]);
% 
% currfig = gcf;
% currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
% currfig.Position = [1986           1        1535        1121]; %workstation
% % currfig.Position = [1 55 1440 773];
% % add the labels for the EZ electrodes (rows)
% xlim([XLowerLim XUpperLim+1]); % increase the xlim by 1, to mark regions of EZ
% plot(repmat(XUpperLim+1, length(ezone_indices),1), ezone_indices, '*r');
% plot(repmat(XUpperLim+1, length(earlyspread_indices), 1), earlyspread_indices, '*', 'color', [1 .5 0]);
% if sum(latespread_indices) > 0
%     plot(repmat(XUpperLim+1, length(latespread_indices),1), latespread_indices, '*', 'color', 'blue');
% end
% plotOptions = struct();
% plotOptions.YAXFontSize = YAXFontSize;
% plotOptions.FONTSIZE = FONTSIZE;
% plotOptions.LT = LT;
% plotIndices(currfig, plotOptions, yticks, labels, ...
%                             ezone_ticks, ...
%                             earlyspread_ticks, ...
%                             latespread_ticks)
% 
% savefig(fullfile(figDir, strcat(patient, 'sortedFragility')));
% print(fullfile(figDir, strcat(patient, 'sortedFragility')), '-dpng', '-r0')

end