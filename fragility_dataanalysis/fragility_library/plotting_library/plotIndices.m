% 
% Description: Function to plot the different labels along the electrode
% axis based on indices and handle to the original axis
function plotIndices(handle, plotOptions, y_indices, labels, ...
                            y_ezoneindices, ...
                            y_earlyspreadindices, ...
                            y_latespreadindices)
YAXFontSize = plotOptions.YAXFontSize;

ax1 = handle.CurrentAxes; % get the current axes
ax1_xlim = ax1.XLim;
ax1_ylim = ax1.YLim;
set(ax1, 'YTick', []);
% leg = legend('EZ', 'Early Onset', 'Late Onset');
% try
%     leg.Position = [0.8792    0.0103    0.1021    0.0880];
% catch
%     disp('Legend not set yet for patient');
% end

%%- Create the first axes to label the original electrodes
axy = axes('Position',ax1.Position,...
    'XAxisLocation','bottom',...
    'YAxisLocation','left',...
    'Color','none', ...
    'XLim', ax1_xlim,...
    'YLim', ax1_ylim,...
    'box', 'off');
set(axy, 'XTick', []);
set(axy, 'YTick', y_indices, 'YTickLabel', labels(y_indices), 'fontsize', YAXFontSize);

%%- Create new axes to label the electrode axis (y-axis)
if sum(y_ezoneindices) > 0 
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
end
if sum(y_earlyspreadindices) > 0 
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
end
if sum(y_latespreadindices) > 0 
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
end