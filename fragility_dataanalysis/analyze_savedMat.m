%% Define epileptogenic zone
patient = 'pt1sz2';
patient = 'pt2sz1';
included_channels = [1:36 42 43 46:54 56:69 72:95]; %pt1
included_channels = [1:19 21:37 43 44 47:74 75 79]; %pt2
dataDir = fullfile('./adj_mats_500_05/', patient);
fid = fopen(strcat('./data/',patient, '/', patient, '_labels.csv')); % open up labels to get all the channels
labels = textscan(fid, '%s', 'Delimiter', ',');
labels = labels{:}; labels = labels(included_channels);
fclose(fid);
ezone_labels = {'POLPST1', 'POLPST2', 'POLPST3', 'POLAD1', 'POLAD2'}; %pt1
ezone_labels = {'POLATT1', 'POLATT2', 'POLAD1', 'POLAD2', 'POLAD3'}; %pt1
earlyspread_labels = {'POLATT3', 'POLAST1', 'POLAST2'};
latespread_labels = {'POLATT4', 'POLATT5', 'POLATT6', ...
                    'POLSLT2', 'POLSLT3', 'POLSLT4', ...
                    'POLMLT2', 'POLMLT3', 'POLMLT4', 'POLG8', 'POLG16'};

ezone_labels = {'POLMST1', 'POLPST1', 'POLTT1'}; %pt2
earlyspread_labels = {'POLTT2', 'POLAST2', 'POLMST2', 'POLPST2', 'POLALEX1', 'POLALEX5'};

                
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
 

% test = mean(fragility_rankings,2);
% rest = 1:length(test);
% rest(ezone_indices) = [];
% figure;
% plot(ezone_indices,test(ezone_indices), 'ko'); hold on;
% plot(rest, test(rest), 'ro');

load(fullfile(dataDir, 'final_data'));
load(fullfile(dataDir, 'pt1sz2_1'));
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

fig = {};
FONTSIZE = 20;
LT=1.5;
xticks = (timeStart - seizureTime) : 5 : (timeEnd - seizureTime);



% fragility ranking
fig{end+1} = figure;
imagesc(fragility_rankings(:,1:end-10)); hold on;
c = colorbar(); colormap('jet'); set(gca,'box','off')
titleStr = {'Fragility Ranking Of Each Channel', ...
    'Time Locked To Seizure'};
title(titleStr, 'FontSize', FONTSIZE+2);
XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
ylabel(c, 'Fragility Ranking');
xlabel('Time (sec)', 'FontSize', FONTSIZE);  ylabel('Electrode Channels', 'FontSize', FONTSIZE);
set(gca, 'FontSize', FONTSIZE-3, 'LineWidth', LT);
set(gca, 'XTick', (XLowerLim+0.5:10:XUpperLim+0.5)); set(gca, 'XTickLabel', xticks); % set xticks and their labels
set(gca, 'YTick', [1, 5:5:length(included_channels)]);
xlim([XLowerLim XUpperLim+1]); % increase the xlim by 1, to mark regions of EZ
% add the labels for the EZ electrodes (rows)
plot(repmat(XUpperLim+1, length(ezone_indices),1), ezone_indices, '*r');
% for i=1:length(ezone_labels)
%     x1 = XLowerLim + 0.01;
%     x2 = XUpperLim - 0.01;
%     x = [x1 x2 x2 x1 x1];
%     y1 = ezone_indices(i)-0.5;
%     y2 = ezone_indices(i)+0.5;
%     y = [y1 y1 y2 y2 y1];
%     plot(x, y, 'r-', 'LineWidth', 2.5);
% end

plot(repmat(XUpperLim+1, length(earlyspread_indices), 1), earlyspread_indices, '*', 'color', [ .5 0]);
% for i=1:length(earlyspread_labels)
%     if earlyspread_indices(i) ~= 0
%         x1 = XLowerLim + 0.01;
%         x2 = XUpperLim - 0.01;
%         x = [x1 x2 x2 x1 x1];
%         y1 = earlyspread_indices(i)-0.5;
%         y2 = earlyspread_indices(i)+0.5;
%         y = [y1 y1 y2 y2 y1];
%         plot(x, y, 'k-', 'LineWidth', 2.5);
%     end
% end

plot(repmat(XUpperLim+1, length(latespread_indices),1), latespread_indices, '*', 'color', [1 .75 0]);
% for i=1:length(latespread_labels)
%     if latespread_indices(i) ~= 0
%         x1 = XLowerLim + 0.01;
%         x2 = XUpperLim - 0.01;
%         x = [x1 x2 x2 x1 x1];
%         y1 = latespread_indices(i)-0.5;
%         y2 = latespread_indices(i)+0.5;
%         y = [y1 y1 y2 y2 y1];
%         plot(x, y, 'y-', 'LineWidth', 2.5);
%     end
% end

legend('EZ Electrodes');