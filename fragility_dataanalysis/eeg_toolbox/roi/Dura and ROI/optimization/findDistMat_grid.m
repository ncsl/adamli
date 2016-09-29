function d = findDistMat_grid(grid,flag)
%% finds distances between all the ellipse points to be minimized. It only
%% cares about the distance in any two dimensions ignoring the third
%% dimension that was specified a priori.
if flag
    d = zeros(size(grid,1));
    for i = 1:size(grid,1)-1
        pt1 = grid(i,:);
        pt1 = repmat(pt1,size(grid,1),1);
        dist = grid-pt1;
        dist = dist.^2;
        dist = sum(dist,2);
        dist = sqrt(dist);
        d(i,:) = dist;
    end
else
    foo = ones(size(grid,1)-1,1);
    d =  diag(foo,1);
end