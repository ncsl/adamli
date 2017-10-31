function numhighfragility = computenumberfragility(fragilityMat, seizureMarkStart, post_index, epsilon)
    mattocheck = fragilityMat(:, seizureMarkStart:post_index);
    
    mattocheck(mattocheck <= epsilon) = 0;
    mattocheck(mattocheck > epsilon) = 1;
    
    numhighfragility = nansum(mattocheck, 2);
end