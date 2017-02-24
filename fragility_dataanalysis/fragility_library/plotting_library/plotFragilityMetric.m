function plotFragilityMetric(fragility_mat, minPert_mat, clinicalIndices,...
          timePoints, timeStart, timeEnd, PLOTARGS)
    %% Step 0: Extract Metadata from Structs
    %- extract clinical indices from EZ, spread regions
    all_indices = clinicalIndices.all_indices;
    ezone_indices = clinicalIndices.ezone_indices;
    resection_indices = clinicalIndices.resection_indices;
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
    seizureMarkStart = PLOTARGS.seizureMarkStart;
    YAXFontSize = 9;
    if isfield(PLOTARGS, 'seizureIndex')
        seizureIndex = PLOTARGS.seizureIndex;
    end
    if isfield(PLOTARGS, 'seizureEnd')
        seizureEnd = PLOTARGS.seizureEnd;
    end
    
    %- create rowsum of fragility_mat
    minpertsum = sum(minPert_mat, 2);
    rowsum = sum(fragility_mat, 2);
    xoffset = 0.05;
    
    %% Step 1: Plot Heatmap
    fig = figure;
    firstplot = 1:24;
    firstplot([6,12,18,24]) = []; hold on;
    firstfig = subplot(4,6, firstplot);
    imagesc(fragility_mat); hold on; axis tight;
    axes = gca; currfig = gcf;
    cbar = colorbar(); colormap('jet'); set(axes, 'box', 'off'); set(axes, 'YDir', 'normal');
    labelColorbar(cbar, colorbarStr, FONTSIZE);
    set(cbar.Label, 'Rotation', 270);
%     cbar.Label.Position = cbar.Label.Position + [1 0 0];
    
    XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);

    % create title string and label the axes of plot
    labelBasicAxes(axes, titleStr, ylabelStr, xlabelStr, FONTSIZE);
    ylab = axes.YLabel;

    % set x/y ticks and increment xlim by 1
    xTickStep = (XUpperLim - XLowerLim) / 10;
    xTicks = round(timeStart: (timeEnd-timeStart)/10 :timeEnd);
    yTicks = [1, 5:5:size(fragility_mat,1)];
    
    try
        plot([seizureMarkStart seizureMarkStart], get(gca, 'ylim'), 'k', 'MarkerSize', 2)
    catch e
        disp(e)
    end
    
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
    
    % plot *'s for the resection indices
    if ~isempty(resection_indices)
        xlim([XLowerLim-1, XUpperLim+2])
        
        xLocations = repmat(XLowerLim-1, length(resection_indices), 1);
        plot(xLocations, resection_indices, 'o', 'Color', [0 0.5 0], 'MarkerSize', 4); hold on;
        
        xLocations = repmat(XUpperLim+2, length(resection_indices), 1);
        plot(xLocations, resection_indices, 'o', 'Color', [0 0.5 0],'MarkerSize', 4); hold on;
    end

    if isempty(resection_indices)
        leg = legend('EZ', 'Early Onset', 'Late Onset');
    else
        leg = legend('EZ', 'Early Onset', 'Late Onset', 'Resected');
    end
    
    try
        leg.Position = [ 0.8752    0.0115    0.1179    0.0821];
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
    pause(0.001);
    cbarPos = cbar.Label.Position;
    cbar.Label.Position = [cbarPos(1)*1.45 cbarPos(2) cbarPos(3)]; % moving it after resizing
    
    % plot the second figure
    xrange = 1:size(fragility_mat, 1);
    xrange(ezone_indices) = [];
    avge = mean(rowsum);
    
    secfig = subplot(4,6, [6,12,18,24]);
    stem(xrange, rowsum(xrange), 'k'); hold on;
    stem(ezone_indices, rowsum(ezone_indices), 'r');
    plot([1 size(fragility_mat, 1)], [avge avge], 'k', 'MarkerSize', 1.5);
    
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

    % save the figure                 
    if SAVEFIG
        print(toSaveFigFile, '-dpng', '-r0')
    end
end