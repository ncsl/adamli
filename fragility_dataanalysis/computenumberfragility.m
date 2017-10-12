function numhighfragility = computenumberfragility(fragilityMat, seizureMarkStart, post_index)
    mattocheck = fragilityMat(:, seizureMarkStart:post_index);
    
    mattocheck(mattocheck <= 0.7) = 0;
    mattocheck(mattocheck > 0.7) = 1;
    
    numhighfragility = nansum(mattocheck, 2);
end