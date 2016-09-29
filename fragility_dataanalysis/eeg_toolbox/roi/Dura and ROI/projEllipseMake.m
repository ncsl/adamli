function ellipse = projEllipseMake(v,y,inter)
%Function ellipse = projEllipseMake(v,y,inter)
%
%   Description: Creates a coronal ellipse around the pial surface defined
%                by the set of vertices 'v' at point 'y'
%
%   Inputs:
%           --v are all the vertices that define the pial surface
%           --y is the point around which the coronal ellipse will be
%             formed
%           --inter is the distance between points
%
%   Outputs:
%           --ellipse is the deformed ellipse that fits around the
%             specified coronal slice.
res =1;
[xMax, zMax, xMin, zMin] = findEndVerts(v,y,'y',res);
xMax = xMax+15;
xMin = xMin-15;
zMax = zMax +15;
zMin = zMin -15;
zAxis = (zMax-zMin)/2;
zc = (zMax+zMin)/2;
xAxis = (xMax-xMin)/2;
xc = (xMax+xMin)/2;
[X, Z] = rawEllipseMake(xc, zc,xAxis,zAxis, 0, 10000);
clear xMax xMin zMax zMin res
Y = repmat(y,size(Z,1),1);
ellipse = [X Y Z];
keyboard
ellipse = filterEllipse(ellipse,abs(inter));
Y = ellipse(:,2);
ellipse = gridOptimize(v,ellipse);
ellipse(:,2) = Y;
% ellipse = filterEllipse(ellipse,abs(inter));