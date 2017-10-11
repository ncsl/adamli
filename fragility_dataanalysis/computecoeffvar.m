function cfvar = computecoeffvar(fragilityMat, markStart, markStop)
    avg = nanmean(fragilityMat(:, markStart:markStop), 2);
    vari = nanvar(fragilityMat(:, markStart:markStop), 0, 2);
    cfvar = avg ./ vari;
end