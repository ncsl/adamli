function pts = relPtsSelect(elecs,brainShell)
%% for each electrode coordinate it selects the set of all possible points
%% to search among for the closest face in the findSurface call of fmincon
pts = cell(size(elecs,1),1);
for i = 1:size(elecs,1)
    pt1 = elecs(i,:);
    d = pdist2(pt1,brainShell,'euclidean');
    [~,idx] = sort(d); 
    
    pts{i} = brainShell(idx(1:2000),:);
end

% if bpFlag
%     save(fullfile(dataDir, subj,'tal','elecLocaleBipolar.mat'),'pts');
% else
%     save(fullfile(dataDir, subj,'tal','elecLocale.mat'),'pts');
% end