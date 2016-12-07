function clinical_indices = findElectrodeIndices(clinical_labels, all_labels)
%%- Get Indices for All Clinical Annotations
% define cell function to search for the EZ labels
cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));
clinical_indices = zeros(length(clinical_labels),1);
for i=1:length(clinical_labels)
    indice = cellfun(cellfind(clinical_labels{i}), all_labels, 'UniformOutput', 0);
    indice = [indice{:}];
    test = 1:length(all_labels);
    if ~isempty(test(indice))
        clinical_indices(i) = test(indice);
    end
end

if(length(find(clinical_indices==0)) > 0)
    disp('some clinical labels not included labels');
end
clinical_indices(clinical_indices==0) = [];
end