function ROIs = elecs2ROI(subj,serverDir,eeg_toolDir,bpFlag,rad,rFlag,sFlag)
% this function creates a strucutre array that contains a cell array for
% each subject specified in the subjects field. This cell array carries
% information about which of the electrodes for any given patient are
% within some radius (rad) from an ROI specified in grid.

dataDir = fullfile(serverDir,'dataWorking','eeg');
subjDir=fullfile(dataDir, subj);
talDir=fullfile(subjDir,'tal');
patientROIs = [];

if bpFlag
    ref = 'bipolar';
    coordFile=fullfile(talDir,'RAW_SURF_BIPOLAR_coords.txt');
    [x, y, z] = textread(coordFile,'%*f%f%f%f');
    elecs = [x, y, z];
else
    ref = 'monopolar';
    coordFile=fullfile(talDir,'RAW_SURF_coords.txt');
    coordFile2 = fullfile(talDir,'RAW_coords.txt');
    [x, y, z] = textread(coordFile,'%*f%f%f%f');
    labels = textread(coordFile2,'%f%*f%*f%*f');
    elecs = [x, y, z];
end

roi = load(fullfile(eeg_toolDir,'trunk/roi/Finalized surfaces/ROI.mat'));

switch rFlag
    case 'all'
        roi = roi.ROI;
    case 'cortical'
        roi = roi.corticalROI;
    case 'paren'
        roi = roi.parenROI;
end

d = pdist2(roi,elecs);
ROIs = {};
for j = 1:size(d,1)
    ROIs{j} = find(d(j,:)<=rad);
end

elecsUsed = [];
for j = 1:length(ROIs)
    elecsUsed = [elecsUsed;ROIs{j}.'];
end
% tal3d(elecs,'ant','b','.',20,0,0,0,0);
% pause 
% close all 
subj
% keyboard
assert(length(unique(elecsUsed)) == size(elecs,1),'Not all electrodes were captured by ROIs. Please retry with different radius')

if sFlag
    save(fullfile(dataDir,'tal',ref,'talROI',['talROI_' subj '.mat']),'ROIs');
end




