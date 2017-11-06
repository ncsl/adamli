function [rowsum, excluded_indices, num_high_fragility] = computedoainterictal(fragilitymat, epsilon, NORMALIZE)
    % for interictal periods, we look at the entire spectrum
    % doa computation composes of two parts:
    % i) row sum of high fragility epsilon = 0.85
    % ii) exclusion of autocorrelated channels
    % returns the rowsum and any excluded indices from ez set based on AC
    [num_channels, num_wins] = size(fragilitymat);
    delta = 0.7;
    
     % compute high fragility regions 
    threshMat = fragilitymat;
    threshMat(fragilitymat < epsilon) = nan;
    high_mask = threshMat;
    
    % part i) compute rowsum for entire period
    rowsum = computerowsum(high_mask, 1, num_wins);
    
    % part ii) to determine any channels that are periodically fragil
    excluded_indices = [];
    for i=1:size(high_mask,1)
        [autocor, ~] = xcorr(high_mask(i,:)', floor(size(high_mask, 2)/10), 'coeff');
          if nansum(autocor > 0.3) > floor(size(high_mask, 2)/10)
              excluded_indices = [excluded_indices; i];
          end
    end
    
    % part iii) instances of high fragility
    % get instances of high fragility
    num_high_fragility = computenumberfragility(fragilitymat, 1, num_wins, delta);
    
    if NORMALIZE
        rowsum = rowsum ./ num_wins;
        num_high_fragility = num_high_fragility ./ num_wins;
    end
end