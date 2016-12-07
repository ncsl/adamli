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
    
    %% Step 1: Plot Heatmap
    fig = figure;
    imagesc(minPerturb_time_chan(:, timeStart:timeEnd)); hold on;
    axes = gca; currfig = gcf;
    cbar = colorbar(); colormap('jet'); set(axes, 'box', 'off'); set(axes, 'YDir', 'normal');
    labelColorbar(cbar, colorbarStr, FONTSIZE);
    
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
    XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
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

    currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
    currfig.Position = [1986           1        1535        1121];
    ylab.Position = ylab.Position + [-.25 0 0]; % move ylabel to the left

    % plot the different labels on different axes to give different colors
    plotOptions = struct();
    plotOptions.YAXFontSize = YAXFontSize;
    plotOptions.FONTSIZE = FONTSIZE;
    plotIndices(currfig, plotOptions, all_indices, included_labels, ...
                                ezone_indices, ...
                                earlyspread_indices, ...
                                latespread_indices)
   % save the figure  
    if SAVEFIG
        print(toSaveFigFile, '-dpng', '-r0')
    end
end