function [included_indices, included_labels] = findEkgRefDC(all_labels)
    all_labels = upper(all_labels);
    all_labels = strrep(all_labels, 'POL', '');
    
    included_indices = 1:length(all_labels);
    
    % find the corresponding indices using cell funcs
    dcindices = find(~cellfun(@isempty, cellfun(@(x)strfind(x, 'DC'), all_labels, 'uniform', 0)));
    ekgindices = find(~cellfun(@isempty, cellfun(@(x)strfind(x, 'EKG'), all_labels, 'uniform', 0)));
    refindices = find(~cellfun(@isempty, cellfun(@(x)strfind(x, 'REF'), all_labels, 'uniform', 0)));
    emptyindices = find(cellfun(@isempty, all_labels));
    
    dcindices
    ekgindices
    refindices
    emptyindices
    
    included_indices([dcindices; ekgindices; refindices; emptyindices]) = [];
    included_labels = all_labels(included_indices);
end