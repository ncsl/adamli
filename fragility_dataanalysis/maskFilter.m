function filt_time = maskFilter(powerMat, freqs, highperctile, lowperctile)
% function: maskFilter
% By: Adam Li
% Date: 6/13/17
% Description: Passed the power matrix of a channel and the frequencies
% that were analyzed and the high/low percentile of the frequencies.
% Creates a mask of 0's and 1's that apply over time.
% 
% Implements a trapezoidal integration scheme to get metric of mask.
% 
% Input: 
% - highperctile: the high percentile (e.g. 95)
% - lowperctile: the low percentile to reject freqs (e.g. 5)
% - powerMat: the F x T power matrix for a certain channel that is
% frequencies by time
% - freqs: the F vector to map each row in powerMat to a frequency analyzed
% Ouput:
% - filt_time: the filtered time windows to mask with white space in
% fragility map

if nargin < 4
    highperctile = 95;
    lowperctile = 5;
end

%%- Loop through frequencies for this transform
%- initialize mask for power matrix 
maskMat = zeros(size(powerMat));

%-  compute low and high percentiles
perctiles(:, 1) = prctile(powerMat, lowperctile, 2);
perctiles(:, 2) = prctile(powerMat, highperctile, 2);

%- apply mask of {-1,0,1} to each frequency/time window in the power matrix
for i=1:length(freqs)
    % get time indices for this frequency that are greater then
    % the high percentile (e.g. 95th) -> set to +1
    indices = powerMat(i, :) > perctiles(i, 2);
    maskMat(i, indices) = 1;

    % get time indices for this frequency that are less then
    % the low percentile (e.g. 5th) -> set to -1
    indices = powerMat(i, :) < perctiles(i, 1);
    maskMat(i, indices) = -1;
end

%- create matrix on the mask of only high powers
highmask = zeros(size(maskMat));
highmask(maskMat == 1) = 1;

% this is the time windows to reject based on a certain
% threshold across frequency dimension 
filt_time = trapz(freqs, highmask, 1) ./ trapz(freqs, ones(size(highmask)), 1);    
end