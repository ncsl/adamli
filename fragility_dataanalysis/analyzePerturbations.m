% close all;
clear all;
close all;
clc;

%% Define epileptogenic zone
pat_id = 'pt2';
sz_id = 'sz3';
patients = {'pt1sz2', 'pt1sz3', 'pt2sz1', 'pt2sz3'};
for z=1:length(patients)
patient = strcat(pat_id,sz_id);
patient = patients{z};
pat_id = patient(1:3);
dataDir = fullfile('./adj_mats_500_05/');
finalDataDir = fullfile(dataDir, 'finaldata');

load(fullfile(finalDataDir, strcat(patient, 'final_data'))); % load in final data mat
load(fullfile(dataDir, patient, strcat(patient, '_3')));    % load in example preprocessed mat

if strcmp(pat_id, 'pt1')
    included_channels = [1:36 42 43 46:69 72:95];
    
    if strcmp(sz_id, 'sz2')
        included_channels = [1:36 42 43 46:54 56:69 72:95];
    end
    ezone_labels = {'POLPST1', 'POLPST2', 'POLPST3', 'POLAD1', 'POLAD2'}; %pt1
    ezone_labels = {'POLATT1', 'POLATT2', 'POLAD1', 'POLAD2', 'POLAD3'}; %pt1
    earlyspread_labels = {'POLATT3', 'POLAST1', 'POLAST2'};
    latespread_labels = {'POLATT4', 'POLATT5', 'POLATT6', ...
                        'POLSLT2', 'POLSLT3', 'POLSLT4', ...
                        'POLMLT2', 'POLMLT3', 'POLMLT4', 'POLG8', 'POLG16'};
elseif strcmp(pat_id, 'pt2')
%     included_channels = [1:19 21:37 43 44 47:74 75 79]; %pt2
    included_channels = [1:14 16:19 21:25 27:37 43 44 47:74];
    ezone_labels = {'POLMST1', 'POLPST1', 'POLTT1'}; %pt2
    earlyspread_labels = {'POLTT2', 'POLAST2', 'POLMST2', 'POLPST2', 'POLALEX1', 'POLALEX5'};
    latespread_labels = {};
elseif strcmp(pat_id, 'JH105')
    included_channels = [1:4 7:12 14:19 21:37 42 43 46:49 51:53 55:75 78:99]; % JH105
    ezone_labels = {'POLRPG4', 'POLRPG5', 'POLRPG6', 'POLRPG12', 'POLRPG13', 'POLG14',...
        'POLAPD1', 'POLAPD2', 'POLAPD3', 'POLAPD4', 'POLAPD5', 'POLAPD6', 'POLAPD7', 'POLAPD8', ...
        'POLPPD1', 'POLPPD2', 'POLPPD3', 'POLPPD4', 'POLPPD5', 'POLPPD6', 'POLPPD7', 'POLPPD8', ...
        'POLASI3', 'POLPSI5', 'POLPSI6', 'POLPDI2'}; % JH105
    
    earlyspread_labels = {};
    latespread_labels = {};
end

fid = fopen(strcat('./data/',patient, '/', patient, '_labels.csv')); % open up labels to get all the channels
labels = textscan(fid, '%s', 'Delimiter', ',');
labels = labels{:}; labels = labels(included_channels);
fclose(fid);
                
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
if strcmp(pat_id, 'pt1')
    for i=1:length(latespread_labels)
        indice = cellfun(cellfind(latespread_labels{i}), labels, 'UniformOutput', 0);
        indice = [indice{:}];
        test = 1:length(labels);
        if ~isempty(test(indice))
            latespread_indices(i) = test(indice);
        end
    end
end
%% Compute Fragility Ranking and 
timeStart = data.timeStart / 1000;
timeEnd = data.timeEnd / 1000;
seizureTime = data.seizureTime / 1000;
winSize = data.winSize;
stepSize = data.stepSize;

fragility_rankings = zeros(size(minPerturb_time_chan,1),size(minPerturb_time_chan,2));
% loop through each channel
for i=1:size(minPerturb_time_chan,1)
    for j=1:size(minPerturb_time_chan, 2) % loop through each time point
        fragility_rankings(i,j) = (max(minPerturb_time_chan(:,j)) - minPerturb_time_chan(i,j)) ...
                                    / max(minPerturb_time_chan(:,j));
    end
end

if (size(fragility_rankings,2) > 121)
    fragility_rankings = fragility_rankings(:,1:end-20);
    minPerturb_time_chan = minPerturb_time_chan(:,1:end-20);
end

% save(fullfile('./adj_mats_500_05/','finaldata', strcat(patient,'final_data.mat')), 'avge_minPerturb', 'ezone_minPerturb_fragility', ...
%                                 'minPerturb_time_chan', 'colsum_time_chan', 'rowsum_time_chan', 'fragility_rankings');


%%- Compute final fragility using linear weight until seizure
% lin_weights = (1:size(minPerturb_time_chan,2));
% fragility_weights = fragility_rankings*lin_weights';
% % fragility_weights = sum(fragility_rankings, 2);
% avge_weight = mean(fragility_weights);
% SEM = std(fragility_weights) / sqrt(length(fragility_weights)); % standard error
% % ts_99 = tinv([1e-10 1-1e-10], length(fragility_weights) - 1);
% ts_99 = tinv([0.005 1-0.005], length(fragility_weights) - 1);
% CI_99 = avge_weight + ts_99*SEM;
% ts_95 = tinv([0.025 0.975], length(fragility_weights) - 1);
% CI_95 = avge_weight + ts_95*SEM;
% 
% % get 95 and 99 confidence interval
% electrodes_99 = labels(fragility_weights > CI_99(2))
% electrodes_95 = labels(fragility_weights > CI_95(2) & fragility_weights < CI_99(2))
% top50 = mean(fragility_weights(fragility_weights > avge_weight)) - avge_weight;

%%- compute threshold weight
threshold = 0.8;
threshold_fragility = fragility_rankings;
threshold_fragility(threshold_fragility > threshold) = 1;
threshold_fragility(threshold_fragility <= threshold) = 0;
rowsum = sum(threshold_fragility,2);
rowsum = rowsum/max(rowsum);
[y, ind] = sort(-rowsum);
sorted_fragility = fragility_rankings(ind,:);
sorted_weights = -y;
figure;
plot(sorted_weights); hold on;
ax = gca;
title(['Ranking of Electrodes Based on Threshold ', num2str(threshold)]);
xlabel('electrodes');
ylabel('Sum of Ones')
figDir = './acc_figures/';
print(fullfile(figDir, strcat(patient, 'electrodeRanks')), '-dpng', '-r0')

%%- print weights into an excel file
weight_file = fullfile(figDir, strcat(patient, 'electrodeWeights.csv'));
fid = fopen(weight_file, 'w');
sorted_labels = labels(ind);
for i=1:length(labels)
    fprintf(fid, '%6s, %f \n', sorted_labels{i}, sorted_weights(i)); 
end
fclose(fid);

% %%- Heatmap of sorted fragility ranks
% figure; FONTSIZE=20; LT=1.5; YAXFontSize = 10;
% imagesc(sorted_fragility); hold on;
% c = colorbar(); colormap('jet'); set(gca,'box','off')
% XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
% % set title, labels and ticks
% xticks = (timeStart - seizureTime) : 5 : (timeEnd - seizureTime);
% titleStr = {['Minimum Norm Perturbation Sorted By Rank ', patient], ...
%     'Time Locked To Seizure'};
% title(titleStr, 'FontSize', FONTSIZE+2);
% ax1 = gca;
% ylabel(c, 'Fragility Ranking');
% xlabel('Time (sec)', 'FontSize', FONTSIZE);  ylabel('Electrode Channels', 'FontSize', FONTSIZE);
% set(gca, 'FontSize', FONTSIZE-3, 'LineWidth', LT);
% set(gca, 'XTick', (XLowerLim+0.5:10:XUpperLim+0.5)); set(gca, 'XTickLabel', xticks); % set xticks and their labels
% set(gca, 'YTick', [1, 5:5:length(included_channels)]);
% ylabel(c, 'Fragility Ranking', 'FontSize', FONTSIZE);
% xlabel('Time (sec)', 'FontSize', FONTSIZE);  ylabel('Electrode Channels', 'FontSize', FONTSIZE);
% set(gca, 'YTick', sort(ind), 'YTickLabel', labels(ind), 'fontsize', YAXFontSize);
% figDir = './acc_figures/';
% currfig = gcf;
% currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
% print(fullfile(figDir, strcat(patient, 'sortedFragility')), '-dpng', '-r0')


% ezone_labels

% initialize variables for plotting and the indices of the channels
fig = {};
FONTSIZE = 22;
YAXFontSize = 9;
LT=1.5;
xticks = (timeStart - seizureTime) : 5 : (timeEnd - seizureTime);
ytick = 1:length(included_channels);
y_indices = setdiff(ytick, [ezone_indices; earlyspread_indices]);
if sum(latespread_indices > 0)
    latespread_indices(latespread_indices ==0) = [];
    y_indices = setdiff(ytick, [ezone_indices; earlyspread_indices; latespread_indices]);
end
y_ezoneindices = sort(ezone_indices);
y_earlyspreadindices = sort(earlyspread_indices);
y_latespreadindices = sort(latespread_indices);

%%- PLOT THE HEATMAP OF MIN PERTURBATION AND FRAGILITY 
% - Plot 01:
fig{end+1} = figure;
% subplot(121);
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
xlim([XLowerLim, XUpperLim+1]);
currfig = gcf;
plot(repmat(XUpperLim+1, length(ezone_indices),1), ezone_indices, '*r');
plot(repmat(XUpperLim+1, length(earlyspread_indices), 1), earlyspread_indices, '*', 'color', [1 .5 0]);
if sum(latespread_indices) > 0
    plot(repmat(XUpperLim+1, length(latespread_indices),1), latespread_indices, '*', 'color', 'blue');
end
ax1 = gca;
ax1_xlim = ax1.XLim;
ax1_ylim = ax1.YLim;
set(gca, 'YTick', []);
% move ylabel to the left
ylab.Position = ylab.Position + [-.25 0 0];

currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
currfig.Position = [1986           1        1535        1121];

% label all the electrodes
% set(gca, 'YTick', y_indices, 'YTickLabel', labels(y_indices), 'fontsize', YAXFontSize);
axy = axes('Position',ax1.Position,...
    'XAxisLocation','bottom',...
    'YAxisLocation','left',...
    'Color','none', ...
    'XLim', ax1_xlim,...
    'YLim', ax1_ylim,...
    'box', 'off');
set(axy, 'XTick', []);
set(axy, 'YTick', y_indices, 'YTickLabel', labels(y_indices), 'fontsize', YAXFontSize);

% set second axes for ezone indices
ax2 = axes('Position',ax1.Position,...
    'XAxisLocation','bottom',...
    'YAxisLocation','left',...
    'Color','none', ...
    'XLim', ax1_xlim,...
    'YLim', ax1_ylim,...
    'box', 'off');
set(ax2, 'XTick', []);
set(ax2, 'YTick', y_ezoneindices, 'YTickLabel', labels(y_ezoneindices), 'FontSize', YAXFontSize, 'YColor', 'red');
linkaxes([ax1 ax2], 'xy');

% set third axes for early spread
ax3 = axes('Position',ax1.Position,...
    'XAxisLocation','bottom',...
    'YAxisLocation','left',...
    'Color','none', ...
    'XLim', ax1_xlim,...
    'YLim', ax1_ylim,...
    'box', 'off');
set(ax3, 'XTick', []);
set(ax3, 'YTick', y_earlyspreadindices, 'YTickLabel', labels(y_earlyspreadindices), 'FontSize', YAXFontSize, 'YColor', [1 .5 0]);
linkaxes([ax1 ax3], 'xy');

if sum(latespread_indices) > 0 
    % 4th axes for latespread
    % set third axes for early spread
    ax4 = axes('Position',ax1.Position,...
        'XAxisLocation','bottom',...
        'YAxisLocation','left',...
        'Color','none', ...
        'XLim', ax1_xlim,...
        'YLim', ax1_ylim,...
        'box', 'off');
    set(ax4, 'XTick', []);
    set(ax4, 'YTick', y_latespreadindices, 'YTickLabel', labels(y_latespreadindices), 'FontSize', YAXFontSize, 'YColor', 'blue');
    linkaxes([ax1 ax3], 'xy');
end
axes(ax1);
leg = legend('EZ Electrodes', 'Early Onset', 'Late Onset');
% leg.Position = leg.Position + [.2 .2 0 0];

figDir = './acc_figures/';
currfig = gcf;
currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
savefig(fullfile(figDir, strcat(patient, 'minPerturbation')));
print(fullfile(figDir, strcat(patient, 'minPerturbation')), '-dpng', '-r0')

% - Plot 02:
% fragility ranking
fig{end+1} = figure;
% subplot(121);
imagesc(fragility_rankings); hold on;
c = colorbar(); set(c, 'fontsize', FONTSIZE); colormap('jet'); set(gca,'box','off')
titleStr = {['Fragility Ranking Of Each Channel (', patient ')'], ...
    'Time Locked To Seizure'};
XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
ax = gca;
set(gca, 'FontSize', FONTSIZE-3, 'LineWidth', LT); set(gca,'YDir','normal');
set(gca, 'XTick', (XLowerLim+0.5:10:XUpperLim+0.5)); set(gca, 'XTickLabel', xticks, 'fontsize', FONTSIZE); % set xticks and their labels
a = get(gca,'XTickLabel');
set(gca,'XTickLabel',a,'fontsize',FONTSIZE)
title(titleStr, 'FontSize', FONTSIZE+5);
ylabel(c, 'Fragility Ranking', 'FontSize', FONTSIZE);
xlabel('Time (sec)', 'FontSize', FONTSIZE);  
ylab = ylabel('Electrode Channels', 'FontSize', FONTSIZE);
xlim([XLowerLim XUpperLim+1]); % increase the xlim by 1, to mark regions of EZ
% add the labels for the EZ electrodes (rows)
plot(repmat(XUpperLim+1, length(ezone_indices),1), ezone_indices, '*r','LineWidth', LT);
plot(repmat(XUpperLim+1, length(earlyspread_indices),1), earlyspread_indices, '*', 'Color', [1 .5 0], 'LineWidth', LT);
if sum(latespread_indices) > 0
    plot(repmat(XUpperLim+1, length(latespread_indices),1), latespread_indices, '*', 'Color', 'blue', 'LineWidth', LT);
end
ax1 = gca;
ax1_xlim = ax1.XLim;
ax1_ylim = ax1.YLim;
set(gca, 'YTick', []);
% move ylabel to the left
ylab.Position = ylab.Position + [-.15 0 0];
legend('EZ Electrodes', 'Early Onset', 'Late Onset');

currfig = gcf;
currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
currfig.Position = [1986           1        1535        1121]; %workstation
currfig.Position = [1 55 1440 773];

% label all the electrodes
% set(gca, 'YTick', y_indices, 'YTickLabel', labels(y_indices), 'fontsize', YAXFontSize);
axy = axes('Position',ax1.Position,...
    'XAxisLocation','bottom',...
    'YAxisLocation','left',...
    'Color','none', ...
    'XLim', ax1_xlim,...
    'YLim', ax1_ylim,...
    'box', 'off');
set(axy, 'XTick', []);
set(axy, 'YTick', y_indices, 'YTickLabel', labels(y_indices), 'fontsize', YAXFontSize);

% set second axes for ezone indices
ax2 = axes('Position',ax1.Position,...
    'XAxisLocation','bottom',...
    'YAxisLocation','left',...
    'Color','none', ...
    'XLim', ax1_xlim,...
    'YLim', ax1_ylim,...
    'box', 'off');
set(ax2, 'XTick', []);
set(ax2, 'YTick', y_ezoneindices, 'YTickLabel', labels(y_ezoneindices), 'FontSize', YAXFontSize, 'YColor', 'red');
linkaxes([ax1 ax2], 'xy');

% set third axes for early spread
ax3 = axes('Position',ax1.Position,...
    'XAxisLocation','bottom',...
    'YAxisLocation','left',...
    'Color','none', ...
    'XLim', ax1_xlim,...
    'YLim', ax1_ylim,...
    'box', 'off');
set(ax3, 'XTick', []);
set(ax3, 'YTick', y_earlyspreadindices, 'YTickLabel', labels(y_earlyspreadindices), 'FontSize', YAXFontSize, 'YColor', [1 .5 0]);
linkaxes([ax1 ax3], 'xy');

if sum(latespread_indices) > 0 
    % 4th axes for latespread
    % set third axes for early spread
    ax4 = axes('Position',ax1.Position,...
        'XAxisLocation','bottom',...
        'YAxisLocation','left',...
        'Color','none', ...
        'XLim', ax1_xlim,...
        'YLim', ax1_ylim,...
        'box', 'off');
    set(ax4, 'XTick', []);
    set(ax4, 'YTick', y_latespreadindices, 'YTickLabel', labels(y_latespreadindices), 'FontSize', YAXFontSize, 'YColor', 'blue');
    linkaxes([ax1 ax3], 'xy');
end
axes(ax1);
leg = legend('EZ', 'Early Onset', 'Late Onset');
leg.Position = [0.8792    0.0103    0.1021    0.0880];
savefig(fullfile(figDir, strcat(patient, 'fragilityRanking')));
print(fullfile(figDir, strcat(patient, 'fragilityRanking')), '-dpng', '-r0')

%- re-sort the labels to plot the sorted fragility map
[a, b] = ismember(ind, ezone_indices);
b(b==0) = [];
ezone_indices = ezone_indices(b);

[a, b] = ismember(ind, earlyspread_indices);
b(b==0) = [];
earlyspread_indices = earlyspread_indices(b);

[a, b] = ismember(ind, latespread_indices);
b(b==0) = [];
latespread_indices = latespread_indices(b);

ytick = 1:length(included_channels);
y_indices = ind(~ismember(ind, [ezone_indices; earlyspread_indices]));
% y_indices = setdiff(ytick, [ezone_indices; earlyspread_indices]);
if sum(latespread_indices > 0)
    latespread_indices(latespread_indices ==0) = [];
    y_indices = ind(~ismember(ind, [ezone_indices; earlyspread_indices; latespread_indices]));
end
yticks = ytick(ismember(ind, y_indices)); % index thru sorted_labels
ezone_ticks = ytick(ismember(ind, ezone_indices));
earlyspread_ticks = ytick(ismember(ind, earlyspread_indices));
if (sum(latespread_indices) > 0)
    latespread_ticks = ytick(ismember(ind, latespread_indices));
end

%%- Heatmap of sorted fragility ranks
figure; FONTSIZE=20; LT=1.5; YAXFontSize = 10;
imagesc(sorted_fragility); hold on;
c = colorbar(); colormap('jet'); set(gca,'box','off')
XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
% set title, labels and ticks
xticks = (timeStart - seizureTime) : 5 : (timeEnd - seizureTime);
titleStr = {['Fragility Sorted By Rank ', patient], ...
    'Time Locked To Seizure'};
title(titleStr, 'FontSize', FONTSIZE+2);
ax = gca;
set(gca, 'FontSize', FONTSIZE-3, 'LineWidth', LT); set(gca,'YDir','normal');
set(gca, 'XTick', (XLowerLim+0.5:10:XUpperLim+0.5)); set(gca, 'XTickLabel', xticks, 'fontsize', FONTSIZE); % set xticks and their labels
a = get(gca,'XTickLabel');
set(gca,'XTickLabel',a,'fontsize',FONTSIZE)
title(titleStr, 'FontSize', FONTSIZE+5);
ylabel(c, 'Fragility Ranking', 'FontSize', FONTSIZE);
xlabel('Time (sec)', 'FontSize', FONTSIZE);  
ylab = ylabel('Electrode Channels', 'FontSize', FONTSIZE);
xlim([XLowerLim XUpperLim+1]); % increase the xlim by 1, to mark regions of EZ
% add the labels for the EZ electrodes (rows)
plot(repmat(XUpperLim+1, length(ezone_indices),1), ezone_ticks, '*r','LineWidth', LT);
plot(repmat(XUpperLim+1, length(earlyspread_indices),1), earlyspread_ticks, '*', 'Color', [1 .5 0], 'LineWidth', LT);
if sum(latespread_indices) > 0
    plot(repmat(XUpperLim+1, length(latespread_indices),1), latespread_ticks, '*', 'Color', 'blue', 'LineWidth', LT);
end
ax1 = gca;
ax1_xlim = ax1.XLim;
ax1_ylim = ax1.YLim;
set(gca, 'YTick', []);
% move ylabel to the left
ylab.Position = ylab.Position + [-.15 0 0];
legend('EZ Electrodes', 'Early Onset', 'Late Onset');

currfig = gcf;
currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
currfig.Position = [1986           1        1535        1121]; %workstation
currfig.Position = [1 55 1440 773];

% label all the electrodes
% set(gca, 'YTick', y_indices, 'YTickLabel', labels(y_indices), 'fontsize', YAXFontSize);
axy = axes('Position',ax1.Position,...
    'XAxisLocation','bottom',...
    'YAxisLocation','left',...
    'Color','none', ...
    'XLim', ax1_xlim,...
    'YLim', ax1_ylim,...
    'box', 'off');
set(axy, 'XTick', []);
set(axy, 'YTick', yticks, 'YTickLabel', sorted_labels(yticks), 'fontsize', YAXFontSize);

% set second axes for ezone indices
ax2 = axes('Position',ax1.Position,...
    'XAxisLocation','bottom',...
    'YAxisLocation','left',...
    'Color','none', ...
    'XLim', ax1_xlim,...
    'YLim', ax1_ylim,...
    'box', 'off');
set(ax2, 'XTick', []);
set(ax2, 'YTick', ezone_ticks, 'YTickLabel', sorted_labels(ezone_ticks), 'FontSize', YAXFontSize, 'YColor', 'red');
linkaxes([ax1 ax2], 'xy');

% set third axes for early spread
ax3 = axes('Position',ax1.Position,...
    'XAxisLocation','bottom',...
    'YAxisLocation','left',...
    'Color','none', ...
    'XLim', ax1_xlim,...
    'YLim', ax1_ylim,...
    'box', 'off');
set(ax3, 'XTick', []);
set(ax3, 'YTick', earlyspread_ticks, 'YTickLabel', sorted_labels(earlyspread_ticks), 'FontSize', YAXFontSize, 'YColor', [1 .5 0]);
linkaxes([ax1 ax3], 'xy');

if sum(latespread_indices) > 0 
    % 4th axes for latespread
    % set third axes for early spread
    ax4 = axes('Position',ax1.Position,...
        'XAxisLocation','bottom',...
        'YAxisLocation','left',...
        'Color','none', ...
        'XLim', ax1_xlim,...
        'YLim', ax1_ylim,...
        'box', 'off');
    set(ax4, 'XTick', []);
    set(ax4, 'YTick', latespread_ticks, 'YTickLabel', sorted_labels(latespread_ticks), 'FontSize', YAXFontSize, 'YColor', 'blue');
    linkaxes([ax1 ax3], 'xy');
end
axes(ax1);
leg = legend('EZ', 'Early Onset', 'Late Onset');
leg.Position = [0.8792    0.0103    0.1021    0.0880];

figDir = './acc_figures/';
currfig = gcf;
currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
print(fullfile(figDir, strcat(patient, 'sortedFragility')), '-dpng', '-r0')

end

