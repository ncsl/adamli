function [model_stats] = computeFragilityStats(fragilityMat, typeSnapshot, seizureOnsetInd, seizureOffsetInd)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       ex: computeFragilityStats(fragilityMat, seizureOnsetInd, seizureOffsetInd);
% function: computeFragilityStats
%
%-----------------------------------------------------------------------------------------
%
% Description:  For a fragility matrix, compute statistics on the given
% matrix for every channel. If fragilityMat is a snapshot with seizure,
% then use seizure onset and offset to also weight different areas
% differently.
%
%-----------------------------------------------------------------------------------------
%   
%   Input:  
%   1. fragilityMat: A cell of different datasets (e.g. pt1sz1, pt1sz2, pt1sz3)
%   2. typeSnapshot: is this 'iiaw', 'iiaslp', 'preictal', or 'sz'
%   3. 
% 
%   Output: 
%   1. doa_scores: a matrix of datasets X thresholds DOA
%   2. outcomes: a cell array of the outcomes (S, or F)
%   3. engel_scores: a vector of the engel scores ([1:4], or nan)
%                          
%-----------------------------------------------------------------------------------------
% Author: Adam Li
%
% Ver.: 1.0 - Date: 09/14/2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 1
   typeSnapshot = 'preictal';
   
end


