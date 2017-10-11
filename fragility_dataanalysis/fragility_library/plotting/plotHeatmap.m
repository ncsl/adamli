function fig = plotHeatmap(fragility_mat)
    % open up the figure
    fig = figure;
    
    firstplot = 1:24;
    firstplot([6,12,18,24]) = []; hold on;
    firstfig = subplot(4,6, firstplot);
    % plot the heatmap
    imagesc(fragility_mat); hold on; axis tight; colormap('jet');
end