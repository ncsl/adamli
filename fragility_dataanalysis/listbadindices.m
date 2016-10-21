% script to quickly list indices to get rid of
cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));
% EZT120
% bad_labels = {'O10', 'O9', 'O2', 'X8', 'X7', 'X6', 'X5', 'X4', 'X3', 'X2',...
%     'E5', 'C5', 'C4', 'C3', 'B6', 'B5', 'B10', 'L8', 'L7', 'L6', 'L5', 'L1'};

% EZT070
% bad_labels = {'

for i=1:length(bad_labels)
    indice = cellfun(cellfind(bad_labels{i}), elec_labels, 'UniformOutput', 0);
    indice = [indice{:}];
    test = 1:length(elec_labels);
    if ~isempty(test(indice))
        bad_indices = test(indice)
    end
end