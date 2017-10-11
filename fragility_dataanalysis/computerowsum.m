function rowsum = computerowsum(matToPlot, seizureMarkStart, post_index)
    rowsum = nansum(matToPlot(:, seizureMarkStart:post_index), 2);
end