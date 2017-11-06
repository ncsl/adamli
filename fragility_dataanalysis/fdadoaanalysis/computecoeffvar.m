function cfvar = computecoeffvar(fragilityMat, markStart, markStop)
if nargin == 1
    markStart = 1;
    markStop = size(fragilityMat, 2);
end
    avg = nanmean(fragilityMat(:, markStart:markStop), 2);
    vari = nanvar(fragilityMat(:, markStart:markStop), 0, 2);
    cfvar = avg ./ vari;
end