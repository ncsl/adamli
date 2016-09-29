function [bipolarPairs,bipolarDistances, r] = extractBipolarity(subjDir,threshold_mm)
% [bipolarPairs,bipolarDistances]=extractBipolarity(subjDir,threshold_mm)
% Finds the combinations of electrode pairs and their distance in mm that
% are adjacent to each other in common electrode strips/grids. 
% 
% INPUT:
% subjDir = subject directory. For example, '/Users/dongj3/Jian/data/eeg/NIH003/'
% threshold_mm = the distance (in mm) under which the electrode pairs are
% considered to be adjacent. threshold can be a number or an array of
% numbers that correspond to the thresholds for each electrode strip/grid
% in electrodes.m
% 
% OUTPUT:
% bipolarPairs = Array of n by 2 elements denoting the electrode numbers, where n is the number of pairs
% bipolarDistances = Array of n elements denoting the distance, where n is the number of pairs

clear r electrodeGroups

electrodeGroups = fullfile(subjDir,'docs','electrodes.m'); % should not contain the sync channels
run(electrodeGroups); %creates variable r with all electrode locations
talCoordinates = fullfile(subjDir,'tal','RAW_coords.txt');
[electrodeNum,talX,talY,talZ]=textread(talCoordinates); Tal=[talX,talY,talZ]; % Reads in electrode numbers and their coordinates
if ~exist('r','var')
    error('No grids found in docs.')
else
    disp('The electrodes in electrodes.m are:')
    disp(r);
    r=r;
end

if length(threshold_mm) == 1
    threshold_mm(1:size(r,1))=threshold_mm;
end

if length(threshold_mm) ~= size(r,1)
    error('threshold_mm has different length than electrode.m');
end

bipolarPairs = [];
bipolarDistances=[];
for i=1:size(r,1)   % loop through all the electrode strips/grids
    currentElectrodes = r(i,1):1:r(i,2); %look at the electrodes in the current strip/grid
    [commonElectrodes,electrodeNumIndex,foo] = intersect(electrodeNum,currentElectrodes); % find the common electrodes
    if ~isequal(commonElectrodes,currentElectrodes)
%         disp(commonElectrodes);disp(currentElectrodes);disp(i)
        error('Electrode information do not match. Make sure electrodes.m and leads.txt are correct.');
    end
    %for each of the current electrodes, find the electrodes (whose numbers
    %is/are greater than the current one) and check their distance apart
    for j=1:length(electrodeNumIndex)-1
        for k=j+1:length(electrodeNumIndex)
            dist_J_K = pdist([Tal(electrodeNumIndex(j),:);Tal(electrodeNumIndex(k),:)],'euclidean');
            if dist_J_K < threshold_mm(i) % store only the electrodes whose distance is less than threshold
                bipolarDistances=[bipolarDistances;dist_J_K];
                bipolarPairs = [bipolarPairs; [electrodeNum(electrodeNumIndex(j)),electrodeNum(electrodeNumIndex(k))]];
            end
        end
    end     
end

