load('/Users/damerasr/Sri/matlab/eeg_toolbox/tal/mni_cortical_surface.mat') %loads the brain map
clear vloc vdist loc_lookup % clears uneeded variables

%get faces for a single hemisphere
v1 = v(f(:,1),:);
v2 = v(f(:,2),:);
v3 = v(f(:,3),:);
v_logic = v1(:,1)>0 & v2(:,1)>0 & v3(:,1)>0; 
f2 = f(v_logic,:); % faces in which all three vertices are on one side of the brain
clear v1 v2 v3 v_logic

% get vertices
v1 = v(f2(:,1),:);
v2 = v(f2(:,2),:);
v3 = v(f2(:,3),:);
v_all = unique([v1;v2;v3],'rows');

%translate current face2vertex indices to new vertex indices using v_all
[~,idx1] = ismember(v1,v_all,'rows');
[~,idx2] = ismember(v2,v_all,'rows');
[~,idx3] = ismember(v3,v_all,'rows');
f3 = [idx1 idx2 idx3]; %f3 now points to the appropriate vertices in v_all
f=  f3;
v = v_all;
%plot brain
FVCD = repmat([.5 .5 .5], size(v_all,1),1);
handle = figure;
set(handle,'PaperUnits','normalized');
set(handle, 'PaperPosition', [0 0 1 1]);
hs1 = patch('faces',f3,'vertices',v_all,'edgecolor','none','FaceColor',...
'flat','FaceVertexCData',FVCD); hold on;
axis off; axis equal; axis vis3d; rotate3d;
set(gca,'XLimMode','manual','YLimMode','manual','ZLimMode','manual',...
'XLim',[-95 95],'YLim',[-108 72],'ZLim',[-56 88]);

setBrainProps(hs1); lighting phong
view([-90 0]);
view([0 0]); camlight infinite;
view([180 0]); camlight infinite;
view([-180 -90]); camlight infinite; camlight infinite
view([90 0]); camlight infinite;

hold on
keyboard
save('/Users/damerasr/Sri/matlab/eeg_toolbox/tal/left_hemisphere_surface.mat','f','v')
keyboard