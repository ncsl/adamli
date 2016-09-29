function []=drawElec2D(subj,bpFlag)
%
% drawElec2D.m
%
% Takes in subject and loads idealized electrode position.
% Computes bipolar location from ideal position if indicated, then
% displays ideal electrode positions in figure
%
% Input Args
%
% subj     - which subject
% bpFlag   - whether to draw bipolar electrodes
% 

% Set directories
homeDir='/Users/zaghloulka/Kareem/data/eeg/';
elecDir='/Users/zaghloulka/Kareem/experiments/pa3/analysis/vis/elecData';

% Load in electrode 2D position data
fileName=fullfile(elecDir,['elec2DPos_' subj '.txt']);
[xElec yElec]=textread(fileName);

numElec=length(xElec);

% Draw electrode 2 dimensional grid
radElec=2;  % Radius of each electrode
[x,y,z]=cylinder(radElec); % Use cylinder to get x and y of circle

figure(1)
hold on
for e=1:numElec
  plot(x(1,:)+xElec(e),y(1,:)+yElec(e),'k','LineWidth',2);  
end
axis off

% Draw bipolar electrodes
if bpFlag
  % Convert to bipolar
  [xElec,yElec]=convElecBipolar(subj,xElec,yElec);

  numElec=length(xElec);
  for e=1:numElec
    plot(x(1,:)+xElec(e),y(1,:)+yElec(e),'r','LineWidth',2);  
  end
end

