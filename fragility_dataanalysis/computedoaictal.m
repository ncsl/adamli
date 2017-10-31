function [rowsum, excluded_indices, num_high_fragility, cfvar_chan] = ...
                                    computedoaictal(fragilitymat, ...
                                        startindex, endindex, epsilon, NORMALIZE)
    % for interictal periods, we look at the entire spectrum
    % doa computation composes of two parts:
    % i) row sum of high fragility epsilon = 0.85
    % ii) exclusion of autocorrelated channels
    % iii) instances of high fragility
    % returns the rowsum and any excluded indices from ez set based on AC
    fragilitymat = fragilitymat(:, startindex:endindex);
    [num_channels, num_wins] = size(fragilitymat);
    
    delta = 0.7; % the marker for high fragility
    
     % compute high fragility regions 
    high_mask = fragilitymat;
    for ichan=1:num_channels
        indices = high_mask(ichan,:) < epsilon;
        high_mask(ichan,indices) = 0; 
    end
    
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
    
    % part iv) compute coefficient of variation
    % compute mean, variance and coefficient of variation for each chan
    cfvar_chan = computecoeffvar(fragilitymat);
    
    if NORMALIZE
        rowsum = rowsum ./ max(rowsum);
        num_high_fragility = num_high_fragility ./ max(num_high_fragility);
        cfvar_chan = cfvar_chan ./ max(cfvar_chan);
    end
end