function [gl2,idx] = rmvRelatedBipolarPairs(pairs)
% Function [gl2,idx] = rmvRelatedPairs(gl)
%
%   Description: removes bipolar pairs that share a common electrode.
%   Inclusion occurs based on first come first serve basis. The first
%   instance of an electrode is kept all future pairs containing that same
%   electrode are deleted.
%
%   Input:
%           --pairs = N-by-2 array containing all bipolar pairs to be
%                    reviewed.
% 
%   Outputs:
%           --gl2 = revised set of bipolar pairs
%           --idx = logical indices indicating which of the original pairs
%           to include.


elecs = unique(reshape(pairs,size(pairs,1)*size(pairs,2),1));
idx = zeros(length(elecs),1); % if I've seen an electrode
track = ones(length(pairs),1); % which bipolar pairs to remove
% remove redundant pairs
for i = 1:size(pairs,1)
    elec1 = pairs(i,1);
    elec2 = pairs(i,2);
    if idx((elec1==elecs)) == 1
        track(i) = 0;
    elseif idx((elec2==elecs)) == 1
        track(i) = 0;
    else
        idx((elec1==elecs)) = 1;
        idx((elec2==elecs)) = 1;
    end
end
gl2 = pairs(idx,:);
