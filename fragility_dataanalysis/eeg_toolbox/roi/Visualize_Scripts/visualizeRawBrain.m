function visualizeRawBrain(v,f)
%
%
%   Description: Plots the brain specified by brain type
 
% left = load(fullfile('/Users/damerasr/Sri/hnl/matlab/eeg_toolbox/trunk/roi/Pial Surfaces/Colin_27','Left_hemisphere.mat'));
% right = load(fullfile('/Users/damerasr/Sri/hnl/matlab/eeg_toolbox/trunk/roi/Pial Surfaces/Colin_27','Right_hemisphere.mat'));
% V = [left.v;right.v];
% 
% f_left= left.f+1;
% 
% f_right= right.f+1;
% f_right = f_right + length(left.v);
% F = [f_left;f_right];
figure

V=v;
F=f;

FVCD = repmat([.5 .5 .5], size(V,1),1);
hs1 = patch('faces',F,'vertices',V,'edgecolor','none','FaceColor',...
   'flat','FaceVertexCData',FVCD); hold on;

axis off; axis equal; axis vis3d; rotate3d;
set(gca,'XLimMode','manual','YLimMode','manual','ZLimMode','manual',...
 'XLim',[-150 150],'YLim',[-150 150],'ZLim',[-150 150]);

setBrainProps(hs1); lighting phong
view([-90 0]); camlight infinite;
view([0 0]); camlight infinite;
view([180 0]); camlight infinite;
view([-180 -90]); camlight infinite;
view([-90 0]); camlight infinite;
% set(hs1, 'FaceAlpha',.1)