function doas = compute_doa_threshold(computed_metric, ezone_labels, included_labels, thresholds, metric)
if nargin==4
    metric = 'default';
%     metric = 'jaccard';
end
    % compute DOA for varying thresholds
    doas = zeros(length(thresholds), 1);
    for iThresh=1:length(thresholds)
        threshold = thresholds(iThresh);

        %% normal fragility metric
        % set threshold on the fragility mat
        thresh_metric_ind = find(computed_metric > threshold);
        
        % compute fragility set of electrodes given this threshold
        fragility_set = included_labels(thresh_metric_ind);
        
        % get rid of grid electrodes in fragility set
        gridindsC = strfind(fragility_set, 'X');
        gridinds = find(not(cellfun('isempty', gridindsC))); 
        fragility_set(gridinds) = [];
        
        % compute doa 
        D = degreeOfAgreement(fragility_set, ezone_labels, included_labels, metric); 
        
        doas(iThresh) = D;
    end % end of loop through thresholds
end