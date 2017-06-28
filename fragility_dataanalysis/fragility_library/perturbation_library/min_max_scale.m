function norm_data = min_max_scale(data)
% function: min_max_scale
% By: Adam Li
% Date: 6/28/17
% Description: This function helps perform a minmax scaling, that is
% altered instead by taking:
%
%       -1 * (A - max(A)) / (max(A) - min(A))
% 
% Input: 
% - data: is a matrix of data that is N x T (channels by time)
% Output:
% - norm_data: the normalized data matrix that is in [0, 1].

[N, ~] = size(data);

% set the min/max across time axis of data matrix
minAtEachTime = min(data, [], 1);
maxAtEachTime = max(data, [], 1);

% normalize data with our version of minmax scaling
norm_data = -1 .* (data - repmat(maxAtEachTime, N, 1)) ./ repmat(maxAtEachTime - minAtEachTime, N, 1);
end