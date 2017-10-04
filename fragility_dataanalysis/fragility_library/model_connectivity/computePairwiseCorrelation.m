%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       ex: computePairwiseCorrelation
% function: computePairwiseCorrelation()
%
%--------------------------------------------------------------------------
%
% Description:  For a given eeg matrix, compute pairwise correlations for a 
% matrix of EEG data. The model is such:
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
%   2. OPTIONS: 
%       - PEARSON: (1, 0) 
%       - SPEARMAN: (1, 0)
%   Output: 
%   theta_adj: a matrix of the connectivity
%                          
%--------------------------------------------------------------------------
% Author: Adam Li
%
% Ver.: 1.0 - Date: 11/23/2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function theta_adj = computePairwiseCorrelation(eegMat, TYPE_CONNECTIVITY)
    if strcmp(TYPE_CONNECTIVITY, 'PEARSON')
        theta_adj = corr(eegMat'); % compute pairwise correlations among all channels
    elseif strcmp(TYPE_CONNECTIVITY, 'SPEARMAN')
        theta_adj = corr(eegMat', 'type', 'Spearman');
    end
end