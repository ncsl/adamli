function xpoints = jitterxaxis(points, jitter)
if nargin==1
    jitter = 0.15;
end
    [numy, numx] = size(points);
    
    % get range from 1 to num x points there are
    x = 1:numx;
    
    % create x values that jitter with uniform distribution
    xpoints = zeros(size(points));
    for i=1:length(x)
        xpoints(:, i) = points(:,i) - (rand(numy, 1)-0.5)*jitter;
    end
end