function sliceCOORD = plot_effect_on_surf_brain(roiCenters,effect,rad,interpIt,cLim,sigma,isSlice,sliceNum)
%
% DESCRIPTION:
%   paints the standard CML brain
%
% INPUT
% roiCenters = N x 3 matrix of talairach corrdinates 
% effect = the val to be distributed from each center.  This value
%          will be mapped to the areas delineated by roiCenters. 
%          (put a nan if you want that grey) 
% rad  = This is your Kernel.  Defines a shpere around each
%        roiCenter.  All vertices within this sphere will "see" the
%        effect.  
% interpIt = makes it slower, but cooler
% cLim = if interpIt=0, this will paint red any
%        vertex bigger than clim(2) and paint blue any vertex less than
%        clim(1).  if interpIt=1, this sets the color limits of the   
% sigma = the std of the three dimensional guassian kernel
%
%
% EXAMPLE:
% (1) no interp
%     plot_effect_on_surf_brain([-90 0 0],10,50,0,[-.5 .5])
% (2) interp 
%     plot_effect_on_surf_brain([-90 0 0],10,50,1,[0 3])
%
% written by jfburke (john.fred.burke@gmail.com). 
% Modifications
%  10/03 jfb: converted to a gaussian kernel
%  11/10 jfb: made the interp option
%  12/10 jfb: made the interpolation(s) thier own functions
%   4/11 jfb: made slice plot its own function (plot_effect_on_hipp_slice.m)
%

if ~exist('sigma','var')||isempty(sigma)
  sigma = rad/4;
end
if ~exist('isSlice','var')||isempty(isSlice)
  isSlice = false;
end
if ~exist('sliceNum','var')||isempty(sliceNum)
  sliceNum = 5;
end

% format the values to plot on a brain
global DECAY
viewAZEL = [-90 0];
nPoints  = size(roiCenters,1);
DECAY = sigma;

% load the brain pic
picpath = fileparts(which('tal3d'));
if isSlice
  picfile = fullfile(picpath,'mni_depth_slice.mat');
  load(picfile);  
  F  = fs{sliceNum};
  V  = vs{sliceNum};
  CS = cs{sliceNum};
  clear vs fs cs 
  sliceCOORD = mean(V(:,3),1);
else
  picfile = fullfile(picpath,'mni_cortical_surface.mat');
  load(picfile);  
  V = v;
  F = f;
  CS = [];
  sliceCOORD=[];
  clear v f loc_lookup vdist vloc
end

% distribute the values to the vertices
D_all = nan(size(V,1),1);
ticker = 0;
tick_inc = 10;
   
%Vertex values
%   nan = no roi within rad mm
%   val = sum of all roi vals within rad mm
%

fprintf('\n\nSmoothing values:\n\n')
for k=1:nPoints  
  if (k-1)/nPoints*100>=ticker
    ticker = ticker + tick_inc;
    fprintf(' %2.0f%%',ticker)
  end
  val = effect(k);
  if isnan(val)
    continue
  end
  xyz = roiCenters(k,:);
  [ind dist]= getElecsInRadius(xyz,V,rad);
  D_all(ind) = nansum([D_all(ind) val*smoother(dist)],2);
  %D_all(ind) = nansum([D_all(ind) val*exp(-1*dist./decay)],2);
end
fprintf(' 100%%\n\n')

% smooth and plot
fprintf('Rendering...')
vertex3d(D_all,V,F,viewAZEL,interpIt,cLim,isSlice,CS);
fprintf('done\n\n')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ind dist]= getElecsInRadius(xyz,xyz_all,radius);
  xyz_diff_norm = sqrt([(xyz_all(:,1)-xyz(1)).^2+...
		        (xyz_all(:,2)-xyz(2)).^2+...
		        (xyz_all(:,3)-xyz(3)).^2]);  
  ind = find(xyz_diff_norm < radius);
  dist = xyz_diff_norm(ind);

function  w = smoother(x)
  global DECAY
  w = exp(-((x.^2)/(2*DECAY^2)));
