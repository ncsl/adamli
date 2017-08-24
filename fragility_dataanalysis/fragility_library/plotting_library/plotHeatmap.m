function fig = plotHeatmap(fragility_mat)
    % open up the figure
    fig = figure;
    
    % plot the heatmap
    imagesc(fragility_mat); hold on; axis tight; colormap('jet');
end