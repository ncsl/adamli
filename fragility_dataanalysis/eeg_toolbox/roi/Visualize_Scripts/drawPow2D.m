function drawPow2D(subj,powChan, bpflag)
%
% drawPow2D.m
%
% Takes in subject and power data and plots power on idealized
% electrode position.  Computes bipolar location from ideal position
% if indicated, then displays ideal electrode positions in figure
%
% Input Args
%
% subj     - which subject
% powChan  - vector containing power for each channel
% 

% Set directories
homeDir='/Users/damerasr/Sri/data/eeg/';
elecDir='/Users/damerasr/Sri/data/eeg/NIH008/tal';

% Load in electrode 2D position data
fileName=fullfile(elecDir,['elec2DPos_' subj '.txt']);
[xElec yElec]=textread(fileName);

% Convert to bipolar
if bpflag
    [xElec,yElec]=convElecBipolar(subj,xElec,yElec);
end

numElec=length(xElec);

% Draw electrode 2 dimensional grid
radElec=2;  % Radius of each electrode
[x,y]=cylinder(radElec); % Use cylinder to get x and y of circle

hold on
for e=1:numElec
  % Define color for this electrode
  elecCol=ones(1,size(x,2))*powChan(e);
  
  patch(x(1,:)+xElec(e),y(1,:)+yElec(e),elecCol);  
end
axis off
set(gca,'CLim',[-1 2])
