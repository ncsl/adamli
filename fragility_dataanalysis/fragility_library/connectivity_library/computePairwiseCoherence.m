%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       ex: computePairwiseCoherence
% function: computePairwiseCoherence()
%
%--------------------------------------------------------------------------
%
% Description:  For a given eeg matrix, compute pairwise frequency coherence
% for a matrix of EEG data. The model is such:
% 
%
% Assumptions:
% 1. All pairwise correlations do not take into effect multivariate
% effects.
% 
%--------------------------------------------------------------------------
%   
%   Input: 
%   1. eegMat: CxT matrix, with C channels and T time points, 
%   2. fs: sampling frequency
%   3. 
%
% 
%   Output: 
%   theta_adj: a 3D matrix of the connectivity for every frequency
%   freqs: a vector of the frequencies at which the coherence was computed
%                          
%--------------------------------------------------------------------------
% Author: Adam Li
%
% Ver.: 1.0 - Date: 11/23/2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [theta_adj, freqs] = computePairwiseCoherence(eegMat, fs)
%     eegMat = randn(50, 500);
%     fs = 1000;
    % initialize variables 
    [num_chans, num_times] = size(eegMat);
    freqs = 1:500; % frequencies to examine
    
    % initialize the adjacency matrix
    theta_adj = zeros(num_chans, num_chans, length(freqs));
    
    %%- Main Step: Loop through and compute pairwise coherence for each
    %%channel time series
    for iChan=1:num_chans
        for jChan=1:num_chans
            coherence = mscohere(eegMat(iChan,:), eegMat(jChan,:), [], [], freqs, fs);
            theta_adj(iChan, jChan, :) = coherence;
        end
    end
end