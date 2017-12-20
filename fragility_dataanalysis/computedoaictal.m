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
    threshMat = fragilitymat;
    threshMat(fragilitymat < epsilon) = nan;
    high_mask = threshMat;
     
    % part i) compute rowsum for entire period
    rowsum = computerowsum(high_mask, 1, num_wins);
    
    % compute num wins passing high_mask
    num_wins = zeros(num_channels,1);
    for i=1:num_channels
        num_wins(i) = sum(high_mask(i,:) > 0);
    end
    
    % part ii) to determine any channels that are periodically fragil
    excluded_indices = [];
    tempmask = fragilitymat;
%     tempmask(isnan(tempmask)) = [];
    for i=1:size(tempmask,1)
        [autocor, ~] = xcorr(tempmask(i,:)', floor(size(tempmask,2)/10), 'coeff');
          if nansum(autocor > 0.05) > floor(size(tempmask,2)/10)
              excluded_indices = [excluded_indices; i];
          end
    end
    
    % part iii) instances of high fragility
    % get instances of high fragility
    num_high_fragility = computenumberfragility(fragilitymat, 1, num_wins, delta);
    num_high_fragility = computenumberfragility(high_mask, 1, size(high_mask,2), delta);
    
    % part iv) compute coefficient of variation
    % compute mean, variance and coefficient of variation for each chan
    cfvar_chan = computecoeffvar(fragilitymat);
%     cfvar_chan = computecoeffvar(threshMat);
    
    if NORMALIZE
        rowsum = rowsum ./ num_wins;
        num_high_fragility = (num_high_fragility - nanmean(num_high_fragility)) ./ sqrt(nanvar(num_high_fragility));
%         num_high_fragility = num_high_fragility ./ num_wins;
        cfvar_chan = cfvar_chan ./ max(cfvar_chan);
    end
end