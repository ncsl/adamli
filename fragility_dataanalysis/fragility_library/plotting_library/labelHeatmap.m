function labelHeatmap(ax, fig, clinicalIndices, PLOTARGS)
    %- extract plotting args
    FONTSIZE = PLOTARGS.FONTSIZE;
    titleStr = PLOTARGS.titleStr;
    xlabelStr = PLOTARGS.xlabelStr;
    ylabelStr = PLOTARGS.ylabelStr;
    seizureMarkStart = PLOTARGS.seizureMarkStart;
    timeStart = PLOTARGS.timeStart;
    timeEnd = PLOTARGS.timeEnd;
    frequency_sampling = PLOTARGS.frequency_sampling;
    stepSize = PLOTARGS.stepSize;
    YAXFontSize = 9;
    if isfield(PLOTARGS, 'seizureIndex')
        seizureIndex = PLOTARGS.seizureIndex;
    end
    if isfield(PLOTARGS, 'seizureEnd')
        seizureEnd = PLOTARGS.seizureEnd;
    end
    
    %- extract clinical indices from EZ, spread regions
    all_indices = clinicalIndices.all_indices;
    ezone_indices = clinicalIndices.ezone_indices;
    resection_indices = clinicalIndices.resection_indices;
    earlyspread_indices = clinicalIndices.earlyspread_indices;
    latespread_indices = clinicalIndices.latespread_indices;
    included_labels = clinicalIndices.included_labels;

    % create title string and label the axes of plot
    labelBasicAxes(ax, titleStr, ylabelStr, xlabelStr, FONTSIZE);
    set(ax, 'box', 'off'); set(ax, 'YDir', 'normal');
    
    XLim = get(ax, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
    xTickStep = (XUpperLim - XLowerLim) / 10;
    xTicks = round(timeStart: (timeEnd-timeStart)/10 :timeEnd);
    yTicks = [1, 5:5:length(included_labels)];
    plot([seizureMarkStart seizureMarkStart], get(gca, 'ylim'), 'k', 'MarkerSize', 2)
    set(ax, 'XTick', (XLowerLim+0.5 : xTickStep : XUpperLim+0.5)); set(ax, 'XTickLabel', xTicks); % set xticks and their labels
    set(ax, 'YTick', yTicks);
    xlim([XLowerLim, XUpperLim+1]);
    
    % plot start star's for the different clinical annotations
    figIndices = {ezone_indices, earlyspread_indices, latespread_indices};
    colors = {[1 0 0], [1 .5 0], [0 0 1]};
    for i=1:length(figIndices)
        if sum(figIndices{i})>0
            xLocations = repmat(XUpperLim+1, length(figIndices{i}), 1);
            plotAnnotatedStars(gca, xLocations, figIndices{i}, colors{i});
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

    % plot the different labels on different axes to give different colors
    plotOptions = struct();
    plotOptions.YAXFontSize = YAXFontSize;
    plotOptions.FONTSIZE = FONTSIZE;
    plotIndices(fig, plotOptions, all_indices, included_labels, ...
                                ezone_indices, ...
                                earlyspread_indices, ...
                                latespread_indices)
    
end