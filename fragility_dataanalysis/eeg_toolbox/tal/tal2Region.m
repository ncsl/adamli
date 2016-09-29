function baStruct=tal2Region(oldStruct)
%function baStruct=tal2Region(oldStruct)
%
%Inputs: A baDatabase struct array with possibly wrong region information
%
%Outputs: a fixed struct array

if ~exist('load_nii'), 
  error('NIFTI toolbox must be in the current path (http://www.rotman-baycrest.on.ca/~jimmy/NIFTI/)');
end


%this text file contains the information for each region number
[labelNumber,loc1,loc2,loc3,loc4,loc5]=textread('talairach_nii_labels.txt','%n%s%s%s%s%s','delimiter','\t.');
badLabelNumbers=labelNumber(~strfound(loc1,'Cerebrum')|strfound(loc5,'*'));
d=load_nii('talairach.nii');

%the .nii file contains a labeled 'region number' for each voxel in the brain
%the algorithm works by finding the closest labeled region to each electrode.
%
%Here we do lots of calculations on the talairach.nii file that depend on it having a particular structure (e.g.,
%symmetry). The original version that I checked into CVS has precisely this structure, but if anyone ever changes it, they
%*may* need to change this code.

if ~(d.hdr.dime.xyzt_units==2 &&  ... %format of everything is millimeters
     size(d.img,1)==abs(d.hdr.hist.qoffset_x)*2+1)
  error('talairach.nii has something in the wrong format...');
end

[voxelX,voxelY,voxelZ]=ndgrid(d.hdr.hist.qoffset_x+[0:size(d.img,1)-1], ...
                              d.hdr.hist.qoffset_y+[0:size(d.img,2)-1], ...
                              d.hdr.hist.qoffset_z+[0:size(d.img,3)-1]);



voxelCoords=[voxelX(:) voxelY(:) voxelZ(:)];
voxelLabels=d.img(:);
badVoxelLabels=ismember(voxelLabels,badLabelNumbers);
voxelLabels=voxelLabels(~badVoxelLabels);
voxelCoords=voxelCoords(~badVoxelLabels,:);

baStruct=oldStruct;

numChanged=0;

for i=1:size(oldStruct,1)
  cur=repmat([oldStruct(i).x oldStruct(i).y oldStruct(i).z],size(voxelCoords,1),1);
  dist=sqrt(sum((cur-voxelCoords).^2,2));
  [m,bestVoxelNum]=min(dist);
  
  talIndex=labelNumber==voxelLabels(bestVoxelNum);
  
  baStruct(i).Loc1=loc1{talIndex};
  baStruct(i).Loc2=loc2{talIndex};  
  baStruct(i).Loc3=loc3{talIndex};    
  baStruct(i).Loc4=loc4{talIndex};    
  baStruct(i).Loc5=loc5{talIndex};      
  
  baStruct(i)=fixUp(baStruct(i));
  
  if ~(strcmp(baStruct(i).Loc1,oldStruct(i).Loc1) &&...
       strcmp(baStruct(i).Loc2,oldStruct(i).Loc2) &&...
       strcmp(baStruct(i).Loc3,oldStruct(i).Loc3) &&...
       strcmp(baStruct(i).Loc4,oldStruct(i).Loc4) &&...
       strcmp(baStruct(i).Loc5,oldStruct(i).Loc5)) 
    disp(sprintf('%d: %s %d (%d,%d,%d) difference:',i,oldStruct(i).subject,oldStruct(i).channel, ...
                 oldStruct(i).x,oldStruct(i).y,oldStruct(i).z));
    disp(sprintf('\told Loc1: %s, new: %s.',oldStruct(i).Loc1,baStruct(i).Loc1));
    disp(sprintf('\told Loc2: %s, new: %s.',oldStruct(i).Loc2,baStruct(i).Loc2));
    disp(sprintf('\told Loc3: %s, new: %s.',oldStruct(i).Loc3,baStruct(i).Loc3));
    disp(sprintf('\told Loc4: %s, new: %s.',oldStruct(i).Loc4,baStruct(i).Loc4));
    disp(sprintf('\told Loc5: %s, new: %s.',oldStruct(i).Loc5,baStruct(i).Loc5));      
    numChanged=numChanged+1;
  end
    
end

disp(sprintf('changed %d of %d',numChanged,length(oldStruct)));

function x=fixUp(x)
%this is per's code from posttal.m

if strcmp(x.Loc5,'Brodmann area 1') | strcmp(x.Loc5,'Brodmann area 2') | strcmp(x.Loc5,'Brodmann area 3') | strcmp(x.Loc5,'Brodmann area 5')
  x.Loc5 = 'Brodmann area 1_2_3_5';
elseif strcmp(x.Loc5,'Brodmann area 4') | strcmp(x.Loc5,'Brodmann area 6')
  x.Loc5 = 'Brodmann area 4_6';
elseif strcmp(x.Loc5,'Brodmann area 41') | strcmp(x.Loc5,'Brodmann area 42')
  x.Loc5 = 'Brodmann area 41_42';
end




