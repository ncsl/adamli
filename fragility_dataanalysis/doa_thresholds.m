function doas = doa_thresholds(fragilityMat, ezone_labels, included_labels, thresholds, metric)
    % compute DOA for varying thresholds
    doas = zeros(length(thresholds), 1);
    for iThresh=1:length(thresholds)
        threshold = thresholds(iThresh);

        %% normal fragility metric
        % set threshold on the fragility mat
        thresh_fragility = fragilityMat;
        thresh_fragility(thresh_fragility < threshold) = 0;
        sum_fragility = sum(thresh_fragility, 2);
        sum_fragility = sum_fragility ./ max(sum_fragility);
%         thresh_fragility(thresh_fragility >= threshold) = 1;

        % compute fragility set of electrodes given this threshold
        fragility_set = included_labels(find(sum_fragility > 0));

        % compute doa 
        D = degreeOfAgreement(fragility_set, ezone_labels, included_labels, metric); 

        %% min/max scaled fragility
        % set threshold on the fragility mat min/maxed scaled
        thresh_fragility = minmaxFragility;
        thresh_fragility(thresh_fragility < threshold) = 0;
        sum_fragility = sum(thresh_fragility, 2);
        sum_fragility = sum_fragility ./ max(sum_fragility);
%         thresh_fragility(thresh_fragility >= threshold) = 1;

        % compute fragility set of electrodes given this threshold
        fragility_set = included_labels(find(sum_fragility > 0));

        % compute doa 
        D = degreeOfAgreement(fragility_set, ezone_labels, included_labels, metric); 

        doas(iThresh) = D;
    end % end of loop through thresholds
end