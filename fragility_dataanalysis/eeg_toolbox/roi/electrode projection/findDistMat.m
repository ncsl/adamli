function d = findDistMat(grid)
%% finds distances between all the ellipse points to be minimized. It only
%% cares about the distance in any two dimensions ignoring the third
%% dimension that was specified a priori.

d = zeros(size(grid,1));
for i = 1:size(grid,1)-1
    pt1 = grid(i,:);
    foo = repmat(pt1,size(grid,1),1);
    d(i,:) = sqrt(sum((foo-grid).^2,2));
end