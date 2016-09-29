function [xPos yPos]=convElecBipolar(subj,xElec,yElec)
%
% convElecBipolar.m
% 
% For given subject's idealized electrode location, computes new
% position based on bipolar referencing.
% 
% Input Args
% 
% subj       - which subject
% xElec      - x position of original electrodes
% yElec      - y position of original electrodes
% 
% Output Args
% 
% xPos       - x position of bipolar electrodes
% yPos       - y position of bipolar electrodes
%

homeDir='/Users/zaghloulka/Kareem/data/eeg/';
subjDir=[homeDir subj];
talDir=[subjDir '/tal'];

% Get original leads
chanFile=[talDir '/leads.txt'];
l=textread(chanFile,'%d');

% Get bipolar leads
chanFile=[talDir '/leads_bp.txt'];
[lBp_a,lBp_b]=textread(chanFile,'%d%d','delimiter','-');
lBp=[lBp_a lBp_b];
numChan=size(lBp,1);

% Only store leads that have EEG data, so have to adjust indices of
% leads_bp to point to correct indices of xElec and yElec in cases
% where EKG channels are in the middle of the recording channels
for c=1:numChan
  for b=1:2
    lBp(c,b)=find(lBp(c,b)==l);
  end
end

% Now loop through each bipolar pair and calculate new coords
xPos=zeros(numChan,1);
yPos=zeros(numChan,1);

for e=1:numChan
  xPos(e)=(xElec(lBp(e,1))+xElec(lBp(e,2)))/2;
  yPos(e)=(yElec(lBp(e,1))+yElec(lBp(e,2)))/2;
end
