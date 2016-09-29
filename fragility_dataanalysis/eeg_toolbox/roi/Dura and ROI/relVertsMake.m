function relVerts = relVertsMake(eeg_toolDir)

relVerts = {};
roi = load(fullfile(eeg_toolDir,'/trunk/roi/Finalized surfaces/ROI.mat'));
roi = roi.ROI;

left = load(fullfile(eeg_toolDir,'/trunk/roi/Pial Surfaces/Colin_27/Left_hemisphere.mat'));
right = load(fullfile(eeg_toolDir,'trunk/roi/Pial Surfaces/Colin_27/Right_hemisphere.mat'));
v = [left.v;right.v];

for j =1:size(roi,1)
    pt = roi(j,:);
    if pt(:,1)<0
        idx = find(v(:,1)<0);
        V = v(v(:,1)<0,:);
    else
        idx = find(v(:,1)>0);
        V = v(v(:,1)>0,:);
    end
    d = pdist2(pt,V);
    relVerts{j} = idx(find(d<=11.5));
end