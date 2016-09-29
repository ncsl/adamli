%% For a given location within a certain dimension this function finds the
%% maximum values of the other two dimensions.
function [max1 max2 min1 min2, res] =  findEndVerts(v,val,type,res)

%% this is for x
if strcmpi('x',type)
    Wall = v(v(:,1)<val+res &v(:,1)>val-res,:);
    max1 = max(Wall(:,2));
    min1 = min(Wall(:,2));
    
    max2 = max(Wall(:,3));
    min2 = min(Wall(:,3));

%% this is for y
elseif strcmpi('y',type)
    Wall = v(v(:,2)<val+res &v(:,2)>val-res,:);
    max1 = max(Wall(:,1));
    min1 = min(Wall(:,1));
    
    max2 = max(Wall(:,3));
    min2 = min(Wall(:,3));
    
%% This is for z
else
    Wall = v(v(:,3)<val+res &v(:,3)>val-res,:);
    max1 = max(Wall(:,1));
    min1 = min(Wall(:,1));
    
    max2 = max(Wall(:,2));
    min2 = min(Wall(:,2));    
end

if isempty(Wall) || (max1==min1) || (max2 ==min2)
    res = res+.01;
    [max1 max2 min1 min2,res] =  findEndVerts(v,val,type,res);
end