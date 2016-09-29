function bipolarPairs = createBipolarPairs(grid)
%   Description: returns the bipolar pairs based upon the inputted grid
%
%   Inputs:
%           --'grid' is set of electrodes that exist in either strip or
%              grid configurations
%   
%   Outputs:
%           --'bipolarPairs' are the matrix of pairs of real electrodes 
%              that are used to create the virtual bipolar electrodes

isStrip = size(grid,2)==1;

bipolarPairs = [];
if isStrip
    for j = 1:length(grid)-1
       bipolarPairs(j,:) = [grid(j) grid(j+1)]; 
    end 
else
    % go through rows and create pairs recursively
    for i = 1:size(grid,2)
        bipolarPairs = [bipolarPairs;createBipolarPairs(grid(:,i))];
    end
    
    % go through columns and create pairs recursively
    for i = 1:size(grid,1) % move through columns
        bipolarPairs = [bipolarPairs;createBipolarPairs(grid(i,:).')];
    end
    [~,idx] = sort(bipolarPairs(:,1));
    bipolarPairs = bipolarPairs(idx,:);
    foo = bipolarPairs(:,1) >0;
    foo2 = bipolarPairs(:,2) >0;
    bipolarPairs = bipolarPairs(foo&foo2,:);
end