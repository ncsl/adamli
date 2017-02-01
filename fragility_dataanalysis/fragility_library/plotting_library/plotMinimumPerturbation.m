function plotMinimumPerturbation(minPerturb_time_chan, clinicalIndices,...
          timeStart, timeEnd, PLOTARGS)
    %% Step 0: Extract Metadata from Structs
    %- extract clinical indices from EZ, spread regions
    all_indices = clinicalIndices.all_indices;
    ezone_indices = clinicalIndices.ezone_indices;
    earlyspread_indices = clinicalIndices.earlyspread_indices;
    latespread_indices = clinicalIndices.latespread_indices;
    included_labels = clinicalIndices.included_labels;

    %- extract plotting args
    FONTSIZE = PLOTARGS.FONTSIZE;
    titleStr = PLOTARGS.titleStr;
    xlabelStr = PLOTARGS.xlabelStr;
    ylabelStr = PLOTARGS.ylabelStr;
    colorbarStr = PLOTARGS.colorbarStr;
    SAVEFIG = PLOTARGS.SAVEFIG;
    toSaveFigFile = PLOTARGS.toSaveFigFile;
    YAXFontSize = 9;
    if isfield(PLOTARGS, 'seizureIndex')
        seizureIndex = PLOTARGS.seizureIndex;
    end
    if isfield(PLOTARGS, 'seizureEnd')
        seizureEnd = PLOTARGS.seizureEnd;
    end
    
    %- create rowsum of fragility_mat
    minpertsum = sum(minPerturb_time_chan, 2);
    xoffset = 0.05;
    
    %% Step 1: Plot Heatmap
    fig = figure;
    firstplot = 1:24;
    firstplot([6,12,18,24]) = []; hold on;
    firstfig = subplot(4,6, firstplot);
    imagesc(minPerturb_time_chan); hold on;
    axes = gca; currfig = gcf;
    cbar = colorbar(); colormap('jet'); set(axes, 'box', 'off'); set(axes, 'YDir', 'normal');
    labelColorbar(cbar, colorbarStr, FONTSIZE);
    set(cbar.Label, 'Rotation', 270);
    
    XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);

    % create title string and label the axes of plot
    labelBasicAxes(axes, titleStr, ylabelStr, xlabelStr, FONTSIZE);
    ylab = axes.YLabel;

    % set x/y ticks and increment xlim by 1
    xTickStep = (XUpperLim - XLowerLim) / 10;
    xTicks = round(timeStart: (timeEnd-timeStart)/10 :timeEnd);
    yTicks = [1, 5:5:size(minPerturb_time_chan,1)];
    
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
    
    leg = legend('EZ', 'Early Onset', 'Late Onset');
    try
        leg.Position = [0.8420    0.0085    0.1179    0.0880];
    catch
        disp('Legend not set yet for patient');
    end
    
    if exist('seizureIndex', 'var') 
        plot([seizureIndex seizureIndex], get(gca, 'YLim'), 'Color', 'black', 'LineWidth', 2);
    end
    if exist('seizureEnd', 'var')
        plot([seizureEnd seizureEnd], get(gca, 'YLim'), 'Color', 'black', 'LineWidth', 2);
    end

    currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
    currfig.Position = [1986           1        1535        1121];
    ylab.Position = ylab.Position + [6 0 0]; % move ylabel to the left

    % plot the different labels on different axes to give different colors
    plotOptions = struct();
    plotOptions.YAXFontSize = YAXFontSize;
    plotOptions.FONTSIZE = FONTSIZE;
    plotIndices(currfig, plotOptions, all_indices, included_labels, ...
                                ezone_indices, ...
                                earlyspread_indices, ...
                                latespread_indices)
    cbar.Label.Position = cbar.Label.Position + [1.2 0 0]; % moving it after resizing
                            
    % plot the second figure
    xrange = 1:size(minPerturb_time_chan, 1);
    xrange(ezone_indices) = [];
    avge = mean(minpertsum);
    
    secfig = subplot(4,6, [6,12,18,24]);
    stem(xrange, minpertsum(xrange), 'k'); hold on;
    stem(ezone_indices, minpertsum(ezone_indices), 'r');
    plot([1 size(minPerturb_time_chan, 1)], [avge avge], 'k', 'MarkerSize', 1.5);
    pos = get(gca, 'Position');
    pos(1) = pos(1) + xoffset;
    xlim([1 size(minPerturb_time_chan,1)]);
    set(gca, 'Xdir', 'reverse');
    set(gca, 'Position', pos);
    set(gca, 'XTick', []); set(gca, 'XTickLabel', []);
    set(gca, 'yaxislocation', 'right');
    set(gca, 'XAxisLocation', 'bottom');
    xlabel('Row Sum of Minimum Perturbation', 'FontSize', FONTSIZE-3);
    view([90 90])
    ax = gca;
    ax.XLabel.Rotation = 270;
    ax.XLabel.Position = ax.XLabel.Position + [0 700 0];

%     rowsumleg = legend('Fragility Row Sum', 'Min Perturb Row Sum');
%     
%     rowsumleg.Position = [0.8493    0.9297    0.1114    0.0308];
    
   % save the figure  
    if SAVEFIG
        print(toSaveFigFile, '-dpng', '-r0')
    end
end