

function labelBasicAxes(axes, titleStr, ylabel, xlabel, fontSize)
    axes.Title.String = titleStr;
    axes.YLabel.String = ylabel;
    axes.XLabel.String = xlabel;
    axes.FontSize = fontSize;
end