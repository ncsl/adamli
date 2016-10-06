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
perturbationType = plot_args.perturbationType;
radius = plot_args.radius;
finalDataDir = plot_args.finalDataDir;
toSaveFigDir = plot_args.toSaveFigDir;
labels = plot_args.labels;
FONTSIZE = plot_args.FONTSIZE;
YAXFontSize = plot_args.YAXFontSize;
LT = plot_args.LT;
dataStart = plot_args.dataStart;
dataEnd = plot_args.dataEnd;

%- grab clinical annotations
ezone_labels = clinicalLabels.ezone_labels;
earlyspread_labels = clinicalLabels.earlyspread_labels;
latespread_labels = clinicalLabels.latespread_labels;
                
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
minPerturb_time_chan = final_data.minPerturb_time_chan;
fragility_rankings = final_data.fragility_rankings;
rowsum_time_chan = final_data.rowsum_time_chan;
colsum_time_chan = final_data.colsum_time_chan;
metadata = final_data.metadata;

num_channels = size(fragility_rankings,1);
num_windows = size(fragility_rankings,2);

% only get -60 to 0 seconds of data
if (size(fragility_rankings,2) > 121)
    fragility_rankings = fragility_rankings(:,1:end-20);
    minPerturb_time_chan = minPerturb_time_chan(:,1:end-20);
end

%%- 1a) Apply thresholding to fragility_rankings
threshold_fragility = fragility_rankings;
threshold_fragility(threshold_fragility > threshold) = 1;
threshold_fragility(threshold_fragility <= threshold) = 0;
rowsum = sum(threshold_fragility,2); rowsum = rowsum/max(rowsum);
[sorted_weights, ind_sorted_weights] = sort(rowsum, 'descend'); % find the electrode's rowsums in descending order and the indices
sorted_fragility = fragility_rankings(ind_sorted_weights,:); % create the sorted fragility

%%- 1b) print weights into an excel file
elecWeightsDir = fullfile(toSaveFigDir, '_electrode_weights');
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
xticks = (dataStart - seizureTime) : 5 : (dataEnd - seizureTime); % set x_ticks at intervals
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

%- 2a) plotting sorted_weights
figure;
plot(sorted_weights); hold on; 
ax = gca; 
set(ax, 'box', 'off');
title(['Ranking of Electrodes Based on Threshold ', num2str(threshold)], 'FontSize', FONTSIZE);
xlabel('electrodes');
set(ax, 'XTick', ax.XLim(1):ax.XLim(2), 'XTickLabels', sorted_labels, 'XTickLabelRotation', 90);
ylabel('Ranking of Electrodes Based on Fragility Metric')

print(fullfile(figDir, strcat(patient, 'electrodeRanks')), '-dpng', '-r0')

% - 2b) minimum perturbation over time and channels:
fig{end+1} = figure;
imagesc(minPerturb_time_chan); hold on;
c = colorbar(); colormap('jet'); set(gca,'box','off')
set(gca,'YDir','normal');
XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
% set title, labels and ticks
xticks = (dataStart - seizureTime) : 5 : (dataEnd - seizureTime);
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
savefig(fullfile(figDir, strcat(patient, 'minPerturbation')));
print(fullfile(figDir, strcat(patient, 'minPerturbation')), '-dpng', '-r0')

%- 2c) fragility_ranking over time and channels
fig{end+1} = figure;
imagesc(fragility_rankings); hold on;
c = colorbar(); set(c, 'fontsize', FONTSIZE); colormap('jet'); set(gca,'box','off')
titleStr = {['Fragility Ranking Of Each Channel (', patient ')'], ...
    'perturbation: ', perturbationType,...
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

savefig(fullfile(figDir, strcat(patient, 'fragilityRanking')));
print(fullfile(figDir, strcat(patient, 'fragilityRanking')), '-dpng', '-r0')

%- 2d) sort by rowsum of fragility ranking metrics
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

ytick = 1:length(included_channels);
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

savefig(fullfile(figDir, strcat(patient, 'sortedFragility')));
print(fullfile(figDir, strcat(patient, 'sortedRowSumFragility')), '-dpng', '-r0')


end
