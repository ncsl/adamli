function alpha = alphaMakeBipolar(grid)

alpha = zeros(size(grid,1));
dist = pdist2(grid,grid);
for j = 1:size(grid,1)-1
    temp = dist(j+1,:);
    alpha(:,j+1) = temp < 13;
end
