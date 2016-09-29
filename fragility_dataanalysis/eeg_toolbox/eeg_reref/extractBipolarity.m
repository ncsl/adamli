function [bipolarPairs, electrodes] = extractBipolarity(subjDir)
% function [bipolarPairs,electrodes] = extractBipolarity(subjDir)
%
% Finds the appropriate pairs of bipolar electrodes 
% 
% INPUT:
% subjDir = subject directory. For example, '/Users/dongj3/Jian/data/eeg/NIH003/'
% 
% OUTPUT:
% bipolarPairs     = Array of n by 2 elements denoting the electrode numbers, where n is the number of pairs
% electrodes       = Array of electrodes from electrodes.m
%
% NOT OUTPUT?: bipolarDistances = Array of n elements denoting the distance, where n is the number of pairs
%
% JHW cleaned up a little 11/2013
%
clear r electrodeGroups

electrodeGroups = fullfile(subjDir,'docs','electrodes.m'); % should not contain the sync channels
run(electrodeGroups); %creates variable r with all electrode locations
if ~exist('r','var')
    error('No docs/electrodes.m file found!')
else
    %disp('The electrodes in electrodes.m are:')
    %disp(r);
    electrodes = r;
end

% check to see if layout of missing elecs is same as electrodes
if length(missingElecs)~=size(electrodes,1),
    error(sprintf('missingElecs.mat has %d entries, but electrodes.m has %d entries', length(missingElecs),size(electrodes,1)));
end

bipolarPairs =[];
for i = 1:length(missingElecs)
    grid         = 1:gridLayout(i,1)*gridLayout(i,2); % makes a linear version of strip or grid
    mElecs       = missingElecs{i};                   % identifies which electrodes in that linear version are missing
    grid(mElecs) = 0;                                 % sets missing electrodes to zero
    foo2         = double(grid==0);                   % foo2 is the same length as grid, but contains 1 at every missing electrode index
    for j = 1:length(grid)
        temp    = sum(foo2(1:j));                     % temp specifies the amount to subtract from existing grid indices to get new grid indices
        grid(j) = grid(j)-temp;                       % actually makes new grid indices and sets missing electrodes to negative indices
        clear temp
    end
    clear foo2
    grid         = reshape(grid,gridLayout(i,:));     % reforms the linear strip or grid into original dimensions
    startIdx     = electrodes(i,1);                   % gets what the absolute channel number is (not just for this specific grid or strip)
    bp_pairs     = createBipolarPairs(grid);          % actually specifies which electrodes are pairs
    bp_pairs     = bp_pairs+startIdx-1;               % converts to absolute bipolar electrode pairs so that it fits in with all other strips and grids
    bipolarPairs = [bipolarPairs;bp_pairs];
end
