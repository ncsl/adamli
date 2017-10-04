function labelColorbar(ax, colorArgs)
    colorbarStr = colorArgs.colorbarStr;
    fontSize = colorArgs.FontSize;

    % activate colorbar, and position it, label it and change fontsize
    cbar = colorbar();
    cbar.Position(1) = cbar.Position(1) + 0.04;
    cbar.Label.String = colorbarStr;
    cbar.FontSize = fontSize;
end