function plotElecMRISlices(sub,outFilename)
%
%function plotElecMRISlices(sub,outFilename)
%
%This function plots all of the patient's electrodes superimposed on their actual MRI.  This function critically relies on:
%  1. The patient's MRI scan being named <patientname>_MR1standard.nii in /data/eeg/<patientname>.
%  2. The patient's information appearing in the Talairach database.  
%  3.  You must have installed the NIFTI toolbox and it must be on your Matlab path.  Get it from:  http://www.rotman-baycrest.on.ca/~jimmy/NIfTI/
%
% Inputs:
%  sub- The name of the subject (e.g., 'UP017').
%  outFilename- the name of the postscript file where all the plots should be placed (it will be a multipage file).
%
%The function works by taking the coordinates in the Talairach database and converting them to MNI format.  Then, the structural MRI scan (which is in MNI coordinates) is plotted and the electrode's location is superimposed on top with a red 'x'.  Three images are plotted, showing the electrode position on sagittal, coronal, and axial slices.  Each page of the multipage postscript file indicates the location of a different electrode.
%

%History:
%4/8/10-Written by JJ


if ~exist('outFilename','var')
  outFilename=[sub '.ps'];
end
delete(outFilename);

subDir=fullfile('/data/eeg/',sub);

%first look for the 1mm spaced file
[r,alignedMRFile]=system(sprintf('find %s -name \\*MR1standard.nii', subDir));
if length(alignedMRFile)==0 %if it doesn't exist, try the 2mm one
  [r,alignedMRFile]=system(sprintf('find %s -name \\*MR2standard.nii', subDir));
  if length(alignedMRFile)==0
    error('cannot find a valid MRI file. try uncompressing the .nii.gz file into .nii');
  end
end

alignedMRFile=alignedMRFile(1:end-1); %remove trailing newline
disp(sprintf('loading structural MRI from:\n\t%s',alignedMRFile));

load('/data/eeg/tal/allTalLocs_GM.mat','events');  
t=filterStruct(events,['strcmp(subject,''' sub ''')']);
talCoord=[t.x;t.y;t.z]';
mniCoord=tal2mni(talCoord);
leads=[t.channel]';

nii=load_nii(alignedMRFile);
%mriData=permute(double(nii.img),[2 1 3]);
mriData=double(nii.img);


xGrid=(0:(nii.hdr.dime.dim(2)-1))*nii.hdr.hist.srow_x(1)+nii.hdr.hist.srow_x(4);
yGrid=(0:(nii.hdr.dime.dim(3)-1))*nii.hdr.hist.srow_y(2)+nii.hdr.hist.srow_y(4);
zGrid=(0:(nii.hdr.dime.dim(4)-1))*nii.hdr.hist.srow_z(3)+nii.hdr.hist.srow_z(4);
cRange=[0 .4*max(mriData(:))];

if xGrid(1)>xGrid(end);
  xGrid=fliplr(xGrid);
  xFlipped=true;
else
  xFlipped=false;
end
  

for lNum=1:length(leads)
  c=mniCoord(lNum,:);
  
  %compute the closest slice in each direction
  [~,bestSlice(1)]=min(abs(c(1)-xGrid));
  [~,bestSlice(2)]=min(abs(c(2)-yGrid));
  [~,bestSlice(3)]=min(abs(c(3)-zGrid));
  
  pointStyle='xr';pointSize=50;
  
  m=2;n=2;
  subplot(m,n,1);
  %plot a coronal slice, which holds the  y dimension constant
  d=squeeze(mriData(:,bestSlice(2),:));
  imagesc(xGrid,zGrid,d');

  axis xy
  title(sprintf('lead %d at (%.1f, %.1f, %.1f), coronal',leads(lNum),c));
  colormap bone
  set(gca,'clim',cRange);
  xlabel('x coor. (MNI)');   ylabel('z coor. (MNI)');

  hold on;  scatter(c(1),c(3),pointSize,pointStyle);  hold off; %add electrode position
  
  %plot a sagittal slice, which holds the  x dimension constant
  subplot(m,n,2);
  d=squeeze(mriData(bestSlice(1),:,:));
  imagesc(yGrid,zGrid,d');
  axis xy
  title('sagittal');
  set(gca,'clim',cRange);
  xlabel('y coor. (MNI)');   ylabel('z coor. (MNI)');
  hold on;  scatter(c(2),c(3),pointSize,pointStyle);  hold off; %add electrode position
  
  
  subplot(m,n,3);
  %plot an axial slice, which holds the  z dimension constant
  d=squeeze(mriData(:,:,bestSlice(3)));
  imagesc(xGrid,yGrid,d');
  axis xy
  title('axial');
    set(gca,'clim',cRange);
  xlabel('x coor. (MNI)');   ylabel('y coor. (MNI)')
  hold on;  scatter(c(1),c(2),pointSize,pointStyle);  hold off; %add electrode position

  if xFlipped
    set([subplot(m,n,1) subplot(m,n,3)],'xdir','reverse');
  end

  
  
  print(gcf,'-dpsc2','-append',outFilename);
  
end



