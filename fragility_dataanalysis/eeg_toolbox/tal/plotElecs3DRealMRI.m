function l=plotElecs3DRealMRI(sub,plotElecsOnCortex,plotElecSpheres,MRIFilename,elecColors,electrodeType,brainPlotThresh)
%function l=plotElecs3DRealMRI(sub,plotElecsOnCortex,plotElecSpheres,MRIFilename,elecColors,brainPlotThresh)
% 
% This function loads in the patient's real MRI, converts it to a 3d structure, and then plots the electrodes on top of these brains.  Electrodes can either be plotted as colored patches on the real brain or as colored 3D spheres.
%
% Inputs: 
% sub- name of the subject (required) 
% plotElecsOnCortex- a boolean that indicates whether you want the electrodes
%     plotted as colored patches on the cortical surface (optional; default true)
% plotElecSpheres- a boolean that indicates whether you want the electrodes
%     plotted as colored 3D spheres (optional; default false)
% MRIFilename- a string that indicates the name of a different MRI file to
%    use. If this is not specified, then the function tries to load one of the
%    files from the talairaching process as described on the wiki.
%    (optional; default <sub_name>MR2standard.nii or <sub_name>MR1standard.nii).
% elecColors-an (n X 3) matrix specifying what color to plot each electrode.
%     Each row corresponds to one electrode, and the three columns indicate which
%     color to plot each one (r,g,b).  (optional; default is [1 0 0] for each
%     electrode)
% brainPlotThresh- the value of structural MRI that is used to identify the cortical surfadce
%
% electrodeType-this optional (n X 1) vector specifies the type of each
% electrode, so that it can be projected to the surface correctly.  
%         0 = Do not  move electrode
%         1 = A standard electrode, which is projected to the
%               nearest brain surface.  This is the default and the most
%               commonly used projection feature.
%         2= A lateral or caudal surface electrode, which
%               should be projected out from the center of the brain (this
%               uses the more aggressive projection algorithm.)
%         3=A ventral surface electrode, which is projected directly
%               ventrally (to the most negative z coordinate).  (This uses a
%               more-aggressive projection algorithm.)
%
%Outputs:
%  l-handle to the light.  You can move the light using the camlight command:
%        e.g., camlight(l,'headlight');
%
%
% Example:
%   plotElecs3DRealMRI('UP017',0,1,'UP017_MR1standard_noCerebellum.nii');

%History:
%4/9/10-Written by JJ
%4/13/10-Modified by JJ with the electrodeTypes variable to allow the user to
%              manually tweak the surface electrode projection

if ~exist('plotElecsOnCortex','var')
  plotElecsOnCortex=true;
end

if ~exist('plotElecSpheres','var')
  plotElecSpheres=false;
end

if ~exist('brainPlotThresh','var')
  %brainPlotThresh=140;
  brainPlotThresh=200;  %the value of structural MRI that is used to identify the cortical surface
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%parameters that you might want to change:
% (a future version of the code could make these function arguments)
smoothWidth=2.1; %the  SD of the kernel (smooth3) used to smooth the structural MRI
smoothBoxSize=3;

smoothWidth=1.6;
brainColor=[.6 .6 .6]; %the color of the brain
electrodeRadius=2; %the radius of the plotted electrodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%find the correct MRI file to load in
if exist('MRIFilename','var')
  subDir=fullfile('/data/eeg/',sub);
  %manually specified MRI file
  [r,alignedMRIFile]=system(sprintf('find %s -name \\*%s', subDir,MRIFilename));
else
  %look for the 1mm spaced file
  [r,alignedMRIFile]=system(sprintf('find %s -name \\*MR1standard.nii', subDir));
  if length(alignedMRIFile)==0 %if it doesn't exist, try the 2mm one
    [r,alignedMRIFile]=system(sprintf('find %s -name \\*MR2standard.nii', subDir));
    if length(alignedMRIFile)==0
      error('cannot find a valid MRI file. try uncompressing the .nii.gz file into .nii');
    end
  end
end

disp(sprintf('loading structural MRI from %s',alignedMRIFile));
alignedMRIFile=alignedMRIFile(1:end-1); %remove trailing newline

nii=load_nii(alignedMRIFile);
brainData=permute(nii.img,[2 1 3]);

leads=getleads(sprintf('/data/eeg/%s/tal/leads.txt',sub));
load('/data/eeg/tal/allTalLocs_GM.mat','events');
for i=1:length(leads)
  t(i)=filterStruct(events,sprintf('strcmp(subject,''%s'') & (channel==%d)', sub,leads(i)));
end
talCoord=[t.x;t.y;t.z]';
mniCoord=tal2mni(talCoord);

if ~exist('elecColors','var')
  %if not specified by user, plot every electrode in red
  elecColors=repmat([1 0 0],length(t),1);
end

if ~exist('electrodeType','var')
  %if not specified by user, plot every electrode in red
  electrodeType=ones(length(t),1);
end


 
%create coordinates for each voxel of the structural MRI
xGrid=(0:(nii.hdr.dime.dim(2)-1))*nii.hdr.hist.srow_x(1)+nii.hdr.hist.srow_x(4);
yGrid=(0:(nii.hdr.dime.dim(3)-1))*nii.hdr.hist.srow_y(2)+nii.hdr.hist.srow_y(4);
zGrid=(0:(nii.hdr.dime.dim(4)-1))*nii.hdr.hist.srow_z(3)+nii.hdr.hist.srow_z(4);
smoothedBrain = smooth3(brainData,'gaussian',smoothBoxSize,smoothWidth);
%smoothedBrain = smooth3(brainData,'box',13);

cla;

isosurf=isosurface(xGrid,yGrid,zGrid,smoothedBrain,brainPlotThresh);
hiso = patch(isosurf, 'FaceColor',brainColor, 'EdgeColor','none','FaceAlpha',1);
isonormals(xGrid,yGrid,zGrid,smoothedBrain,hiso)
lighting phong;  material dull;
view(-180,-90);
axis vis3d
axis off
l=camlight('left');

%computes the center of each patch
x=reshape(isosurf.vertices(isosurf.faces,:),[],3,3);
faceCenter=squeeze(mean(x,2));

mniCoord2=mniCoord;

%%%%%%%%%%%%%%%%
% Different types of electrode relocation algorithms

inds=electrodeType==1; %electrodes to relocate to nearest neighbor
if any(inds)
  mniCoord2(inds,:)=bringElecsToSurface(mniCoord(inds,:),faceCenter);
end

inds=electrodeType==2; %electrodes to relocate to most outward point on that line
if any(inds)
  mniCoord2(inds,:)=bringElecsToSurface2(mniCoord(inds,:),faceCenter);
end

inds=electrodeType==3; %electrodes relocated ventrally
if any(inds)
  mniCoord2(inds,:)=projectElectrodesVentrally(mniCoord(inds,:),faceCenter);
end

%%%%%%%%%%%%%%%%

if plotElecsOnCortex
  faceColor=repmat(brainColor,size(get(hiso,'Faces'),1),1);
  for i=1:size(mniCoord,1)
    %compute the distance from each electrode to each patch
    dists=sqrt(sum(bsxfun(@minus,mniCoord2(i,:),faceCenter).^2,2));
    relevantFaces=dists<electrodeRadius;
    faceColor(relevantFaces,:)=repmat(elecColors(i,:),sum(relevantFaces),1);
  end
  set(hiso,'facecolor','flat','facevertexcdata',faceColor);   %update the brain based on the computed colors

end

if plotElecSpheres
  hold on;
  for i=1:size(mniCoord,1);
    [a,b,c]=sphere(20);;
    surf(a*electrodeRadius+mniCoord2(i,1),b*electrodeRadius+mniCoord2(i,2),c*electrodeRadius+mniCoord2(i,3),'facecolor',elecColors(i,:),'edgecolor',elecColors(i,:));
  end
  hold off;
end

function locs2=projectElectrodesVentrally(locs,faceCenter)
distThresh=.5; %only consider sites within .5mm of the x,y coordinate
locs2=locs;
for i=1:size(locs,1)
  dists=sqrt(sum(bsxfun(@minus,locs(i,1:2),faceCenter(:,1:2)).^2,2));
  goodFaceCenters=faceCenter(dists<distThresh,:);
  [m,bestFace]=min(goodFaceCenters(:,3));
  locs2(i,:)=goodFaceCenters(bestFace,:);
end



function locs2=bringElecsToSurface(locs,faceCenter,maxMovableDist)
%projects electrodes to the nearest surface

if ~exist('maxMovableDist','var'), maxMovableDist=inf;end

locs2=locs;
for i=1:size(locs,1)
  dists=sqrt(sum(bsxfun(@minus,locs(i,:),faceCenter).^2,2));
  [closestDist,closestFaceInd]=min(dists);
  if closestDist<maxMovableDist
    locs2(i,:)=faceCenter(closestFaceInd,:);
  end
end

function locs2=bringElecsToSurface2(locs,faceCenter)
%projects electrode outward from the center of the brain
locsMag=sqrt(dot(locs,locs,2));
faceMag=sqrt(dot(faceCenter,faceCenter,2));
normFactor=locsMag*faceMag';
proj=locs*faceCenter';
angle=acos(proj./normFactor);

angThresh=1*pi/180; %1 degree threshold
proj2=proj.*(angle<angThresh);

[m,bestProj]=max(proj2,[],2);
locs2=faceCenter(bestProj,:);





