function plotFragilityMetric(fragility_mat, minPert_mat, clinicalIndices,...
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
    
    XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);

    % create title string and label the axes of plot
    labelBasicAxes(axes, titleStr, ylabelStr, xlabelStr, FONTSIZE);
    ylab = axes.YLabel;

    % set x/y ticks and increment xlim by 1
    xTickStep = (XUpperLim - XLowerLim) / 10;
    xTicks = round(timeStart: (timeEnd-timeStart)/10 :timeEnd);
    yTicks = [1, 5:5:size(fragility_mat,1)];
    
    set(gca, 'XTick', (XLowerLim+0.5 : xTickStep : XUpperLim+0.5)); set(gca, 'XTickLabel', xTicks); % set xticks and their labels
    set(gca, 'YTick', yTicks);
    xlim([XLowerLim, XUpperLim+1]);

    % plot start star's for the different clinical annotations
    figIndices = {ezone_indices, earlyspread_indices, latespread_indices};
    colors = {[1 0 0], [1 .5 0], [0 0 1]};
    for i=1:length(figIndices)
        if sum(figIndices{i})>0
            xLocations = repmat(XUpperLim+1, length(figIndices{i}), 1);
            plotAnnotatedStars(firstfig, xLocations, figIndices{i}, colors{i});
        end
    end

    leg = legend('EZ', 'Early Onset', 'Late Onset');
    try
        leg.Position = [0.8792    0.0103    0.1021    0.0880];
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
    ylab.Position = ylab.Position + [-.15 0 0]; % move ylabel to the left

    % plot the different labels on different axes to give different colors
    plotOptions = struct();
    plotOptions.YAXFontSize = YAXFontSize;
    plotOptions.FONTSIZE = FONTSIZE;
    plotIndices(currfig, plotOptions, all_indices, included_labels, ...
                                ezone_indices, ...
                                earlyspread_indices, ...
                                latespread_indices)
                            
    % plot the second figure
    secfig = subplot(4,6, [6,12,18,24]);
    plot(rowsum, 1:size(fragility_mat,1), 'r'); hold on; set(axes, 'box', 'off');
    plot(minpertsum, 1:size(minPert_mat, 1), 'k'); 
    pos = get(gca, 'Position');
    pos(1) = pos(1) + xoffset;
    ylim([1 size(fragility_mat,1)]);
    ylabel('Row Sum of Fragility', 'FontSize', FONTSIZE-3);
    set(gca, 'Position', pos);
    set(gca, 'YTick', []); set(gca, 'YTickLabel', []);
    set(gca, 'yaxislocation', 'right');
    rowsumleg = legend('Fragility Row Sum', 'Min Perturb Row Sum');
    
    rowsumleg.Position = [0.8493    0.9297    0.1114    0.0308];
    
    % save the figure                 
    if SAVEFIG
        print(toSaveFigFile, '-dpng', '-r0')
    end
end