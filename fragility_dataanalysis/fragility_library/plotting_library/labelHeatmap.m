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
    YAXFontSize = 11;
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
    xlim([XLowerLim, XUpperLim+1]);

    yTicks = [1, 5:5:length(included_labels)];    
    set(ax, 'YTick', yTicks);
    
    % plot start star's for the different clinical annotations
    figIndices = {ezone_indices, earlyspread_indices, latespread_indices};
    colors = {[1 0 0], [1 .5 0], [0 0 1]};
    for i=1:length(figIndices)
        if sum(figIndices{i})>0
            xLocations = repmat(XUpperLim+1, length(figIndices{i}), 1);
            plotAnnotatedStars(gca, xLocations, figIndices{i}, colors{i});
        end
    end
    
    leg = legend('EZ', 'Early Onset', 'Late Onset');
    try
        leg.Position = [0.8792    0.0103    0.1021    0.0880];
    catch
        disp('Legend not set yet for patient');
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
    plotIndices(fig, plotOptions, all_indices, included_labels, ...
                                ezone_indices, ...
                                earlyspread_indices, ...
                                latespread_indices)
    
end