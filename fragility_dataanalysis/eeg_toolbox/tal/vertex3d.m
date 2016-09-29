function vertex3d(D,V,F,viewAZEL,interpIt,colorCLIM,isSlice,CS)
%
% DESCRIPTION:
%   applies fill3 to the standard lab brain.  this lower level
%   function is called by plot_effect_on_surf_brain.m
%
% INPUT
%   (1) D = N x 1 (where N=number of verts on tal3d brain image) 
%           NaN = paints the defult color [.5 .5 .5]
%           val = paints an actual color
%           
%   (2) viewAzel = the view you want
%   (4) interpIt = interpolation vs. flat
%   (3) cLim = this sets the color limits of the interpolation  
%   (4) CS  = the facevertexdata of a hippocampal axial slice.
%             leave empty is you dont want to plot a slice
%
% written by jfburke (john.fred.burke@gmail.com). 
% Modifications:
%  (1) 12/10: converted this function to be a standalone
%  (2) 12/23: added a quick plot feature.  plots 'Flat' patches,
%      i.e one color per patch. 
%  (3) 4/11: made V and F as direct inputs, which allows slices. 
%

if isSlice
  % CS contains indices from 1:125 of what the colr at a vertex
  % should be to recover the hippocampal outline.  ROUND CS because
  % actually the indices are not integers,,, they are off by very
  % small decimal places
  CS      = round(CS);
  BW_cMap = gray(125);
  FVCD = BW_cMap(CS,:);
else
  FVCD = repmat([.5 .5 .5],size(V,1),1);
end

% indices of all the significant vertices to plot
sigVind = find(~isnan(D));

% only select faces that have all vertices = significant 
sigF    = find(prod(double(ismember(F,sigVind)),2)==1);
insigF  = find(prod(double(ismember(F,sigVind)),2)==0);

% create the color map
lenColorMap   = 1000;
CL_cMap       = jet(lenColorMap);
midColInd     = lenColorMap/2;
LoBoundColInd = midColInd - round(lenColorMap*.07);
HiBoundColInd = midColInd + round(lenColorMap*.07);
lenLoBound    = length(LoBoundColInd+1:midColInd);
lenHiBound    = length(midColInd+1:HiBoundColInd);
CL_cMap(LoBoundColInd+1:midColInd,:) = repmat(CL_cMap(LoBoundColInd,:),lenLoBound,1);
CL_cMap(midColInd+1:HiBoundColInd,:) = repmat(CL_cMap(HiBoundColInd,:),lenHiBound,1);
colormap(CL_cMap);
if length(colorCLIM)==1
  set(gca,'CLim',[-colorCLIM colorCLIM])
elseif length(colorCLIM)==2
  set(gca,'CLim',[colorCLIM])
else
  error('bad CLIM value')
end

% now go back and cover up all the areas with no electrodes
f_empty = F(insigF,:);
hold on
%hs = patch('faces',f_empty,'vertices',V,'edgecolor','none','facecolor',[.5 .5 .5]);
hs = patch('faces',f_empty,'vertices',V,'edgecolor','none','FaceColor',...
	   'interp','FaceVertexCData',FVCD);

% interp the colors of each sig vertex
X = [V(F(sigF,1),1)';V(F(sigF,2),1)';V(F(sigF,3),1)'];
Y = [V(F(sigF,1),2)';V(F(sigF,2),2)';V(F(sigF,3),2)'];
Z = [V(F(sigF,1),3)';V(F(sigF,2),3)';V(F(sigF,3),3)'];
C_raw = [D(F(sigF,1))';D(F(sigF,2))';D(F(sigF,3))'];
if interpIt
  C = C_raw;
else      
  C = mean(C_raw,1);
end
hBrain = fill3(X,Y,Z,C,'EdgeColor','none');
hold off

lighting phong    
if ~isSlice
  % you only need light with the brain surfae because the
  % hippocampal slice is colored already
  view(viewAZEL)
  hLight = camlight('headlight');
  set(hLight,'Color',[1 1 1],'Style','infinite');
  setBrainProps(hBrain);
  setBrainProps(hs);
else
  view([0 90])
  setBrainProps(hs,true);
end