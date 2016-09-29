function res = tal3d(xyz,viewAZEL,ecolor,markertype,markersize,append,convert2mni,doFastSlice,bringToSurf)
% TAL3D - Topographical map of electrodes on 3D brain.
%
% Allows plotting on either cortical surface or depth slice.  To
% plot depth electrodes on a transparent set of slices, simply
% set viewAZEL to 'slice'.
%
% You can specify electrodes either as a Nx3 or Nx4 matrix, or as a
% structure of electrodes from an electrode database.  In the
% matrix form, if the 4xN matrix is passed in, the first column
% represents the channel number for use with the markertype = 'num'
% option.
%
% To rotate the view of the cortical surface, use the view3d
% function with the res from a call to tal3d.
%
% You can append electrodes to a plot by simply calling the
% function with append = 1.
%
% To print the cortical surface plot with all the electrodes pulled
% to the surface to match your current view, use the printtal3d
% function.  It is usually best to call axis off before printing so
% that you are left with just the brain.
% 
% FUNCTION:
%   res = tal3d(xyz,viewAZEL,ecolor,markertype,markersize,append,convert2mni)
%
% INPUT ARGS:
%   xyz = get_lead_coords('RAW_coords.txt'); % the electrodes to plot
%   viewAZEL = [-90 0] or 'rsag' etc;       % 3d view or 'slice' for depth plot
%   ecolor = [1 0 0];         % color specification of plot
%   markertype = '.';  % Any plot marker or 'num' to plot channel numbers
%   markersize = 20;   % Size of marker if using plot marker
%   append = 0; % Set to 1 in order to append electrodes to existing plot
%   convert2mni = 1;  % Set to 0 if the coords are already in mni space
%   doFastSlice = do a slice really fast.  This is an
%                 approximation, and sacrifices accuracy for speed. 
%   bringToSurf = bring electrodes to surface.  Relies on anotical
%     illusion.  You cannot rotate the brain once its rendered.
%     You cannot look at oblique views with this option.  It is
%     a faster way to bring electrodes to the surface than
%     printtal3d, but it sacrifices accuracy for speed. You can
%     only use this for string inputs for viewAzel.
% OUTPUT ARGS:
%   res.hLight - Handle to light object
%   res.hBrain - Handle to brain objects
%   res.hElec - Handle to electrodes
%
%

% Changes:
% 08/13/09 - JFB - added options to increase speed
%                  (doFastSlice,bringToSurf) 
% 11/22/2007 - MvV - made the string option backward compatible by
% checking whether viewAZEL is given as a string or vector. Also
% increased the LineWidth of the markers, so that none-circle
% markers look better.
% 8/27/2007 - NWM - added option to pass in a string for certain
% standard views
% 11/01/2005 - PBS - Made it so the res is persistent across
%                    appends.
%

% process input vars
if ~exist('xyz','var')
  xyz = [];
end
if ~exist('viewAZEL','var') | isempty(viewAZEL)
  viewAZEL = [90,0];
end
if ~exist('append','var') | isempty(append)
  append = 0;
end
if ~exist('ecolor','var') | isempty(ecolor)
  ecolor = [1 0 0];
end
if ~exist('markertype','var') | isempty(markertype)
  markertype = '.';
end
if ~exist('markersize','var') | isempty(markersize)
  markersize = 20;
end
if ~exist('convert2mni','var') | isempty(convert2mni)
  convert2mni = 1;
end

if ~exist('doFastSlice','var') || isempty(doFastSlice)
  doFastSlice = 0;
end

if ~exist('bringToSurf','var') || isempty(bringToSurf)
  bringToSurf = 0;
end

if isstr(viewAZEL)
  switch viewAZEL
   case 'rsag'
    viewAZEL = [90 0];
    str = 'XData';
    int = 100;
   case 'lsag'
    viewAZEL = [-90 0];
    str = 'XData';
    int = -100;
   case 'ant'
    viewAZEL = [180 0];
    str = 'YData';
    int = 100;
   case 'post'
    viewAZEL = [0 0];
    str = 'YData';
    int = -100;
   case 'sup'
    viewAZEL = [0 90];
    str = 'ZData';
    int = 100;
   case 'inf'
    viewAZEL = [-180 -90];
    str = 'ZData';
    int = -100;
   case 'slice'
    str = 'ZData';
    int = 100;
   otherwise
    if bringToSurf
      error('Bad Value for bring to Surf')
    end
  end
else
  if bringToSurf
    error('Can only use bring to surf for str values of viewAzel')
  end
end

% See if we'll plot a cortical surface or slice
if ischar(viewAZEL)
  % doing a slice
  isSlice = 1;
  viewAZEL = 2;
else
  % cortical plot
  isSlice = 0;
end

% set up return structure
persistent lastres
res = lastres;
if ~append
  res.noFace = [];
  res.hLight = [];
  res.hBrain = [];
  res.hElec = [];
end

% read in the faces and vertices of the surface
% get path to pictures
picpath = fileparts(fileparts(which('tal3d')));
surfaceDir = fullfile(picpath,'Pial Surfaces','Colin_27');
% surfaceDir = fullfile(picpath,'Pial Surfaces','MNI_152');

% if isSlice
%   picfile = fullfile(surfaceDir,'mni_depth_slice.mat');
% else
% 
%   picfile = fullfile(surfaceDir,'mni_cortical_surface.mat');
% end
% load(picfile);
v_left = load(fullfile(surfaceDir,'TT_N27.lh.pial.std100.1D.coord'));
v_right = load(fullfile(surfaceDir,'TT_N27.rh.pial.std100.1D.coord'));
v = [v_left;v_right];

v(:,2) = v(:,2)*-1;
v(:,1) = v(:,1)*-1;

f_left = load(fullfile(surfaceDir,'TT_N27.lh.pial.std100.1D.topo'));
f_left= f_left+1;
f_right = load(fullfile(surfaceDir,'TT_N27.rh.pial.std100.1D.topo'));
f_right= f_right+1;
f_right = f_right + length(v_left);
f = [f_left;f_right];

clear v_left v_right f_left f_right

% process the electrodes if necessary
if ~isempty(xyz)
  % see if is struct
  if isstruct(xyz)
    % extract channel and xyz fields
    chans = getStructField(xyz,'channel');
    xyz = [getStructField(xyz,'x')' getStructField(xyz,'y')' getStructField(xyz,'z')'];
  else
    % See if can get channel info
    if size(xyz,2) == 4
      % chan is first column
      chans = xyz(:,1);
      xyz = xyz(:,2:4);
    else
      % no channel info
      chans = [];
    end
  end
  
  % Do coordinant conversion if necessary
  if convert2mni
    xyz = tal2mni(xyz);
  end
end

% draw the brain patches
if ~append
  if isSlice
    
    if doFastSlice
      nslice = 1;
      fs = {fs{6}};
      vs = {vs{6}};
      cs = {cs{6}};
      arange = 1;
    else
      nslice = length(fs);
      arange = linspace(.2,.05,nslice);
    end
    
    % draw the slice patches
    hs = zeros(nslice,1);    
    for i = 1:nslice
      hs(i) = patch('faces',fs{i},'vertices',vs{i},'facevertexcdata',cs{i},'edgecolor','none','facecolor','interp',...
		    'facealpha',arange(i));
    end
    
    colormap(gray(128));
  else
    % draw the cortical surface patches  
    hs = patch('faces',f,'vertices',v,'edgecolor','none','facecolor',[.5 .5 .5]);
  end
  
  % set aspect, view, and light
  daspect([1 1 1]);
  view(viewAZEL)

  % save the handle
  res.hBrain = hs;
  
  if ~isSlice
    res.hLight = camlight;
    set(res.hLight,'Color',[1 1 1],'Style','infinite');
    lighting phong
  end
  
  
end

if ~isempty(xyz)
  % draw the electrodes
  hold on;
  if ~strcmp(markertype,'num')
    h = plot3(xyz(:,1),xyz(:,2),xyz(:,3),markertype,'Color',ecolor);
    set(h,'markersize',markersize,'LineWidth',3)
  else
    % plot the channel number
    if isempty(chans)
      % Whoops no channel info provided
      warning('No channel info provided for ''num'' plot.',...
	      'TAL3D:noChannelInfo');
    else
      % loop and use text
      h = zeros(length(chans),1);
      for c = 1:length(chans)
	h(c) = text(xyz(c,1),xyz(c,2),xyz(c,3),num2str(chans(c)));
	set(h(c),'FontWeight','Bold','Color',ecolor,'HorizontalAlignment','center');
      end
    end
  end
  hold off;

  % save the handle
  res.hElec = [res.hElec; h];
end

% save the last res
lastres = res;

% bring them to surface
if bringToSurf
  for e=1:length(res.hElec)
    nEl = length(get(res.hElec(e),str));
    corrFactor=int*ones(1,nEl,1);
    set(res.hElec(e),str,corrFactor);  
  end
end