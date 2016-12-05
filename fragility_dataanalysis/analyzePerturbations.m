%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: analyzePerturbations
% DESCRIPTION: This function analyzes the perturbations 
% 
% INPUT:
% - patient_id = The id of the patient (e.g. pt1, JH105, UMMC001)
% - seizure_id = the id of the seizure (e.g. sz1, sz3)
% - perturbationType = 'R', or 'C' for row or column perturbation
% - threshold = [0, 1], some threshold to apply on the fragility_rankings
% 
% OUTPUT:
% - None, but it saves a mat file for the patient/seizure over all windows
% in the time range -> adjDir/final_data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function analyzePerturbations(patient_id, seizure_id, plot_args, clinicalLabels)
close all;
    
%% 0: Initialize Variables, EZONE, EarlySpread and LateSpread Indices
patient = strcat(patient_id, seizure_id);

perturbationType = plot_args.perturbationType;
radius = plot_args.radius;
winSize = plot_args.winSize;
stepSize = plot_args.stepSize;
finalDataDir = plot_args.finalDataDir;
toSaveFigDir = plot_args.toSaveFigDir;
toSaveWeightsDir = plot_args.toSaveWeightsDir;
labels = plot_args.labels;
FONTSIZE = plot_args.FONTSIZE;
YAXFontSize = plot_args.YAXFontSize;
LT = plot_args.LT;
dataStart = plot_args.dataStart;
dataEnd = plot_args.dataEnd;
threshold = plot_args.threshold;
seizureStart = plot_args.seizureStart;
frequency_sampling = plot_args.frequency_sampling;

dataStart = dataStart / 1000;
dataEnd  = dataEnd / 1000;
seizureStart = seizureStart / 1000;

%- grab clinical annotations
ezone_labels = clinicalLabels.ezone_labels;
earlyspread_labels = clinicalLabels.earlyspread_labels;
latespread_labels = clinicalLabels.latespread_labels;
resection_labels = clinicalLabels.resection_labels;               

%%- Get Indices for All Clinical Annotations
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

latespread_indices = zeros(length(latespread_labels),1);
for i=1:length(latespread_labels)
    indice = cellfun(cellfind(latespread_labels{i}), labels, 'UniformOutput', 0);
    indice = [indice{:}];
    test = 1:length(labels);
    if ~isempty(test(indice))
        latespread_indices(i) = test(indice);
    end
end

if(length(find(ezone_indices==0)) > 0)
    disp('some ezone labels not included labels');
end
if(length(find(earlyspread_indices==0)) > 0)
    disp('some earlyspread labels not included labels');
end
if(length(find(latespread_indices==0)) > 0)
    disp('some latespread labels not included labels');
end

ezone_indices(ezone_indices==0) = [];
earlyspread_indices(earlyspread_indices==0) =  [];
latespread_indices(latespread_indices==0) = [];

%% 1: Extract Processed Data and Begin Plotting and Save in finalDataDir
final_data = load(fullfile(finalDataDir, strcat(patient, 'final_data.mat'))); % load in final data mat

% set data to local variables
minPerturb_time_chan = final_data.minPerturb_time_chan;
fragility_rankings = final_data.fragility_rankings;
rowsum_time_chan = final_data.rowsum_time_chan;
colsum_time_chan = final_data.colsum_time_chan;
metadata = final_data.metadata;

if strcmp(patient_id, 'EZT005') & strcmp(seizure_id, 'seiz001')
    ignoredTimes = [44 39];
    ignoredTimes(1) = (60-ignoredTimes(1)) * frequency_sampling/winSize;
    ignoredTimes(2) = (60-ignoredTimes(2)) * frequency_sampling/winSize;
    fragility_rankings = fragility_rankings(:,[1:ignoredTimes(1), ignoredTimes(2)+1:120]);
elseif strcmp(patient_id, 'JH104')
    ignoredTimes = [60 57];
    ignoredTimes(1) = (60-ignoredTimes(1)) * frequency_sampling/winSize;
    ignoredTimes(2) = (60-ignoredTimes(2)) * frequency_sampling/winSize;
    fragility_rankings = fragility_rankings(:,[1:ignoredTimes(1), ignoredTimes(2)+1:120]);
elseif strcmp(patient_id, 'pt8')
    ignoredTimes = [60 44];
    ignoredTimes(1) = (60-ignoredTimes(1)) * frequency_sampling/winSize;
    ignoredTimes(2) = (60-ignoredTimes(2)) * frequency_sampling/winSize;
    fragility_rankings = fragility_rankings(:,[1:ignoredTimes(1), ignoredTimes(2)+1:120]);
    minPerturb_time_chan = minPerturb_time_chan(:,[1:ignoredTimes(1), ignoredTimes(2)+1:120]);
    xticks = -45:5:0;
elseif strcmp(patient_id, 'pt10')
    ignoredTimes = [60 44];
    ignoredTimes(1) = (60-ignoredTimes(1)) * frequency_sampling/winSize;
    ignoredTimes(2) = (60-ignoredTimes(2)) * frequency_sampling/winSize;
    fragility_rankings = fragility_rankings(:,[1:ignoredTimes(1), ignoredTimes(2)+1:120]);
    minPerturb_time_chan = minPerturb_time_chan(:,[1:ignoredTimes(1), ignoredTimes(2)+1:120]);
end

num_channels = size(fragility_rankings,1);
num_windows = size(fragility_rankings,2);

%%- 1a) Apply thresholding to fragility_rankings
threshold_fragility = fragility_rankings;
threshold_fragility(threshold_fragility > threshold) = 1;
threshold_fragility(threshold_fragility <= threshold) = 0;
rowsum = sum(threshold_fragility,2); rowsum = rowsum/max(rowsum);
[sorted_weights, ind_sorted_weights] = sort(rowsum, 'descend'); % find the electrode's rowsums in descending order and the indices
sorted_fragility = fragility_rankings(ind_sorted_weights,:); % create the sorted fragility


%% 2. Plotting
xticks = (dataStart - seizureStart) * 1000/frequency_sampling : 5  : (dataEnd - seizureStart) * 1000/frequency_sampling; % set x_ticks at intervals
ytick = 1:num_channels;                                           % 1 xtick per channel
y_indices = setdiff(ytick, [ezone_indices; earlyspread_indices]);
if sum(latespread_indices > 0)
    latespread_indices(latespread_indices ==0) = [];
    y_indices = setdiff(ytick, [ezone_indices; earlyspread_indices; latespread_indices]);
end
y_ezoneindices = sort(ezone_indices);
y_earlyspreadindices = sort(earlyspread_indices);
y_latespreadindices = sort(latespread_indices);

fig = {};

if strcmp(patient_id, 'EZT005') & strcmp(seizure_id, 'seiz001')
    ignoredTimes = [44 39];
    ignoredTimes(1) = (60-ignoredTimes(1)) * frequency_sampling/winSize;
    ignoredTimes(2) = (60-ignoredTimes(2)) * frequency_sampling/winSize;
    fragility_rankings = fragility_rankings(:,[1:ignoredTimes(1), ignoredTimes(2)+1:120]);
elseif strcmp(patient_id, 'JH104')
    ignoredTimes = [60 57];
    ignoredTimes(1) = (60-ignoredTimes(1)) * frequency_sampling/winSize;
    ignoredTimes(2) = (60-ignoredTimes(2)) * frequency_sampling/winSize;
    fragility_rankings = fragility_rankings(:,[1:ignoredTimes(1), ignoredTimes(2)+1:120]);
elseif strcmp(patient_id, 'pt8')
    ignoredTimes = [60 44];
%     ignoredTimes(1) = (60-ignoredTimes(1)) * frequency_sampling/winSize;
%     ignoredTimes(2) = (60-ignoredTimes(2)) * frequency_sampling/winSize;
%     fragility_rankings = fragility_rankings(:,[1:ignoredTimes(1), ignoredTimes(2)+1:120]);
    xticks = -45:5:0;
elseif strcmp(patient_id, 'pt10')
    ignoredTimes = [60 44];
%     ignoredTimes(1) = (60-ignoredTimes(1)) * frequency_sampling/winSize;
%     ignoredTimes(2) = (60-ignoredTimes(2)) * frequency_sampling/winSize;
%     fragility_rankings = fragility_rankings(:,[1:ignoredTimes(1), ignoredTimes(2)+1:120]);
    xticks = -45:5:0;
end

num_channels = size(fragility_rankings,1);
num_windows = size(fragility_rankings,2);


% figure options
colorbarLabel = 'Fragility Ranking';
xlabelStr = 'Time (sec)';
ylabelStr = 'Channels';

%% 2b) minimum perturbation over time and channels:
fig{end+1} = figure;
imagesc(minPerturb_time_chan); hold on;
c = colorbar(); colormap('jet'); set(gca,'box','off'); set(gca,'YDir','normal');
labelColorbar(c, 'Minimum Norm Perturbation', FONTSIZE);

XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
% set title, labels and ticks
titleStr = {'Minimum Norm Perturbation For All Channels', ...
    'Time Locked To Seizure'};
title(titleStr, 'FontSize', FONTSIZE+2);
xlabel('Time (sec)', 'FontSize', FONTSIZE);  
ylab = ylabel('Electrode Channels', 'FontSize', FONTSIZE);

set(gca, 'FontSize', FONTSIZE-3, 'LineWidth', LT);
set(gca, 'XTick', (XLowerLim+0.5 : 10*500/stepSize : XUpperLim+0.5)); set(gca, 'XTickLabel', xticks); % set xticks and their labels
set(gca, 'YTick', [1, 5:5:num_channels]);
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

% plot the different labels on different axes to give different colors
plotOptions = struct();
plotOptions.YAXFontSize = YAXFontSize;
plotOptions.FONTSIZE = FONTSIZE;
plotOptions.LT = LT;
plotIndices(currfig, plotOptions, y_indices, labels, ...
                            y_ezoneindices, ...
                            y_earlyspreadindices, ...
                            y_latespreadindices)
%- save the figure
savefig(fullfile(toSaveFigDir, strcat(patient, 'minPerturbation')));
print(fullfile(toSaveFigDir, strcat(patient, 'minPerturbation')), '-dpng', '-r0')

%% 2c) fragility_ranking over time and channels
fig{end+1} = figure;
imagesc(fragility_rankings); hold on; axes = gca; currfig = gcf;
set(axes,'YDir','normal'); set(axes,'box','off'); colormap('jet'); 
c = colorbar(); labelColorbar(c, colorbarLabel, FONTSIZE); % label and initialize colorbar

% create title string and label the axes of plot
titleStr = {['Fragility Metric (', patient, ')'], ...
    [perturbationType, ' perturbation: ', ' Time Locked to Seizure']};
labelBasicAxes(axes, titleStr, ylabelStr, xlabelStr, FONTSIZE);
ylab = axes.YLabel;

% set x/y ticks and increment xlim by 1
set(gca, 'XTick', (XLowerLim+0.5 : 10*500/stepSize : XUpperLim+0.5)); set(gca, 'XTickLabel', xticks); % set xticks and their labels
set(gca, 'YTick', [1, 5:5:num_channels]);
XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
xlim([XLowerLim, XUpperLim+1]);

% plot start star's for the different clinical annotations
figNum = currfig.Number;
figIndices = {ezone_indices, earlyspread_indices, latespread_indices};
colors = {[1 0 0], [1 .5 0], [0 0 1]};
for i=1:length(figIndices)
    if sum(figIndices{i})>0
        xLocations = repmat(XUpperLim+1, length(figIndices{i}), 1);
        plotAnnotatedStars(fig{figNum}, xLocations, figIndices{i}, colors{i});
    end
end

currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
currfig.Position = [1986           1        1535        1121];
ylab.Position = ylab.Position + [-.25 0 0]; % move ylabel to the left

% plot the different labels on different axes to give different colors
plotOptions = struct();
plotOptions.YAXFontSize = YAXFontSize;
plotOptions.FONTSIZE = FONTSIZE;
plotOptions.LT = LT;
plotIndices(currfig, plotOptions, y_indices, labels, ...
                            y_ezoneindices, ...
                            y_earlyspreadindices, ...
                            y_latespreadindices)
                        
savefig(fullfile(toSaveFigDir, strcat(patient, 'fragilityRanking')));
print(fullfile(toSaveFigDir, strcat(patient, 'fragilityRanking')), '-dpng', '-r0')

%% 2d) sort by rowsum of fragility ranking metrics
% rowsum_fragility = sum(fragility_rankings, 2);
% [vals, ind] = sort(rowsum_fragility); % sort in descending order
% 
% % get indices for each clinical annotation
% ind_sorted_weights = ind;
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
% ytick = 1:num_channels;
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
% %- Heatmap of sorted fragility ranks
% fig{end+1} = figure; 
% imagesc(fragility_rankings(ind,:)); hold on;  
% c = colorbar(); colormap('jet'); set(gca,'box','off'); set(c, 'fontsize', FONTSIZE); 
% XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
% % set title, labels and ticks
% titleStr = {['Fragility Rowsum sorted(', patient, ')'], ...
%     [perturbationType, ' perturbation: ', ' Time Locked to Seizure']};
% ylabel(c, 'Fragility Ranking', 'FontSize', FONTSIZE);
% title(titleStr, 'FontSize', FONTSIZE);
% set(gca, 'FontSize', FONTSIZE-3, 'LineWidth', LT); set(gca,'YDir','normal');
% set(gca, 'XTick', (XLowerLim+0.5 : 10*500/stepSize : XUpperLim+0.5)); set(gca, 'XTickLabel', xticks, 'fontsize', FONTSIZE); % set xticks and their labels
% a = get(gca,'XTickLabel'); set(gca,'XTickLabel',a,'fontsize',FONTSIZE)
% title(titleStr, 'FontSize', FONTSIZE+5);
% ylabel(c, 'Fragility Ranking', 'FontSize', FONTSIZE);
% xlabel('Time (sec)', 'FontSize', FONTSIZE);  
% ylab = ylabel('Electrode Channels', 'FontSize', FONTSIZE);
% % move ylabel to the left
% ylab.Position = ylab.Position + [-.25 0 0];
% set(gca, 'YTick', [1, 5:5:num_channels]);
% 
% % currfig.Position = [1 55 1440 773];
% % add the labels for the EZ electrodes (rows)
% xlim([XLowerLim XUpperLim+1]); % increase the xlim by 1, to mark regions of EZ
% plot(repmat(XUpperLim+1, length(ezone_indices),1), ezone_ticks, '*r');
% plot(repmat(XUpperLim+1, length(earlyspread_indices), 1), earlyspread_ticks, '*', 'color', [1 .5 0]);
% if sum(latespread_indices) > 0
%     plot(repmat(XUpperLim+1, length(latespread_indices),1), latespread_ticks, '*', 'color', 'blue');
% end
% currfig = gcf;
% currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
% currfig.Position = [1986           1        1535        1121]; %workstation
% plotOptions = struct();
% plotOptions.YAXFontSize = YAXFontSize;
% plotOptions.FONTSIZE = FONTSIZE;
% plotOptions.LT = LT;
% plotIndices(currfig, plotOptions, yticks, labels(ind_sorted_weights), ...
%                             ezone_ticks, ...
%                             earlyspread_ticks, ...
%                             latespread_ticks)
% 
% savefig(fullfile(toSaveFigDir, strcat(patient, 'sortedFragility')));
% print(fullfile(toSaveFigDir, strcat(patient, 'sortedRowSumFragility')), '-dpng', '-r0')
% 
% try
% %%- 1b) print weights into an excel file
% weight_file = fullfile(toSaveWeightsDir, strcat(patient, 'electrodeWeights.csv'));
% fid = fopen(weight_file, 'w');
% sorted_labels = labels(ind_sorted_weights);
% for i=1:length(labels)
%     fprintf(fid, '%6s, %f \n', sorted_labels{i}, sorted_weights(i)); 
% end
% fclose(fid);
% 
% %% 2a) plotting sorted_weights
% figure;
% plot(sorted_weights); hold on; 
% ax = gca; 
% set(ax, 'box', 'off');
% title(['Ranking of Electrodes Based on Threshold ', num2str(threshold)], 'FontSize', FONTSIZE);
% xlabel('electrodes'); ylabel('Ranking of Electrodes Based on Fragility Metric')
% set(ax, 'XTick', ax.XLim(1):ax.XLim(2), 'XTickLabels', sorted_labels, 'XTickLabelRotation', 90);
% 
% print(fullfile(toSaveFigDir, strcat(patient, 'electrodeRanks')), '-dpng', '-r0')
% 
% catch e
%     disp(e)
%     disp('cant make weights');
% end
end
