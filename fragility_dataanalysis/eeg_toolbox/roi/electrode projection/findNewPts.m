function pt =  findNewPts(pts,brainShell)
%% after energy minimization technique this function snaps the points onto
%% a vertex. Used because we specify the x or y-coordinates a priori, and
%% the brain surface does not always exist at the new points.
x= pts;
% 
% v_left = load('/Users/damerasr/Documents/ToSri/TT_N27.lh.pial.std100.1D.coord');
% v_right = load('/Users/damerasr/Documents/ToSri/TT_N27.rh.pial.std100.1D.coord');
% brainShell = [v_left;v_right];
% brainShell(:,2) = brainShell(:,2)*-1;
% brainShell(:,1) = brainShell(:,1)*-1;

d= pdist2(pts,brainShell);
foo = sort(d,2);
[~,idx] = sort(d,2);
pt = brainShell(idx(:,1),:);