clear all
clc
close all

%% Set Root Directories
% data directories to save data into - choose one
eegRootDirHD = '/Volumes/NIL Pass/';
eegRootDirHD = '/Volumes/ADAM LI/';
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';    % at JHU workstation
eegRootDirMarcctest = '/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/'; % at MARCC server
eegRootDirMarcc = '/scratch/groups/ssarma2/adamli/fragility_dataanalysis/';

% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
% elseif ~isempty(dir(eegRootDirHD)), rootDir = eegRootDirHD;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
elseif ~isempty(dir(eegRootDirMarcc)), rootDir = eegRootDirMarcc;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

% Determine which directory we're working with automatically
% if     ~isempty(dir(eegRootDirServer)), dataDir = eegRootDirServer;
% elseif ~isempty(dir(eegRootDirHD)), dataDir = eegRootDirHD;
% elseif ~isempty(dir(eegRootDirJhu)), dataDir = eegRootDirJhu;
% elseif ~isempty(dir(eegRootDirMarcc)), dataDir = eegRootDirMarcc;
% else   error('Neither Work nor Home EEG directories exist! Exiting'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

%% Parameters
winSize = 250;
stepSize = 125;
filterType = 'notchfilter';
radius = 1.5;
typeConnectivity = 'leastsquares';
typeTransform = 'fourier';
rejectThreshold = 0.3;
reference = '';
% set which pertrubation model to analyze
perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);

FONTSIZE = 16;
metric = 'jaccard';

figDir = fullfile(rootDir, '/figures', 'fragilityStats', ...
    strcat(filterType), ...
    strcat('perturbation', perturbationType, '_win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)));

if ~exist(figDir, 'dir')
    mkdir(figDir);
end

% Load data
nihdata = load('nihpermaptoplot.mat');
ccdata = load('ccpermaptoplot.mat');

combineddoas = [];
combinedfaildoas = [];

%% Plot Relevant DOA
doas = nihdata.doas;
faileddoas = nihdata.faildoas;
toplotdoas = [doas; faileddoas];
toplotx = [ones(length(doas), 1); ones(length(faileddoas),1)*2];

combineddoas = [combineddoas; doas];
combinedfaildoas = [combinedfaildoas; faileddoas];

fig = figure;
%% Plot successes
% second plot points with jitter on the x-axis
xvals = jitterxaxis(toplotx);
plot(xvals, toplotdoas, 'k.', 'MarkerSize', 15); hold on;

% get the other center's data
doas = ccdata.doas;
faileddoas = ccdata.faildoas;
toplotdoas = [doas; faileddoas];
toplotx = [ones(length(doas), 1); ones(length(faileddoas),1)*2];

combineddoas = [combineddoas; doas];
combinedfaildoas = [combinedfaildoas; faileddoas];

% second plot points with jitter on the x-axis
xvals = jitterxaxis(toplotx);
plot(xvals, toplotdoas, 'r.', 'MarkerSize', 15); hold on;

%% Plot successes
% second plot points with jitter on the x-axis
% xvals = jitterxaxis(toplotx);
% plot(xvals, toplotdoas, 'ko');


group = [repmat({'Success'}, length(combineddoas), 1); repmat({'Failure'}, length(combinedfaildoas), 1)];
toplotdoas = [combineddoas; combinedfaildoas];
% first plot boxplot
bh = boxplot(toplotdoas, group, 'Symbol', ''); hold on; axes = gca; currfig = gcf;

title(['Success Vs. Failure Per Heatmap']);
if strcmp(metric, 'jaccard')
    axes.YLim = [0, 1];
    ylabel('Jaccard Index');
else 
    axes.YLim = [-1, 1];
    ylabel('DOA');
end

% plot(1, mean(doas), 'dg')
% plot(2, mean(faildoas), 'dg')
axes.FontSize = FONTSIZE;
toSaveFigFile = fullfile(figDir, strcat('CCandNIH', 'combined_doaanalysis'));
print(toSaveFigFile, '-dpng', '-r0')

% Load data
nihdata = load('nihperpattoplot.mat');
ccdata = load('ccperpattoplot.mat');

combineddoas = [];
combinedfaildoas = [];

%% Plot Relevant DOA
doas = nihdata.combinedoa;
faileddoas = nihdata.failcombinedoa;

% w/o pt 6
faileddoas = faileddoas(2:end);

toplotdoas = [doas; faileddoas];
toplotx = [ones(length(doas), 1); ones(length(faileddoas),1)*2];

combineddoas = [combineddoas; doas];
combinedfaildoas = [combinedfaildoas; faileddoas];

fig = figure;
%% Plot successes
% second plot points with jitter on the x-axis
xvals = jitterxaxis(toplotx);
plot(xvals, toplotdoas, 'k.', 'MarkerSize', 15); hold on;

% get the other center's data
doas = ccdata.combinedoa;
faileddoas = ccdata.failcombinedoa;
toplotdoas = [doas; faileddoas];
toplotx = [ones(length(doas), 1); ones(length(faileddoas),1)*2];

combineddoas = [combineddoas; doas];
combinedfaildoas = [combinedfaildoas; faileddoas];

% second plot points with jitter on the x-axis
xvals = jitterxaxis(toplotx);
plot(xvals, toplotdoas, 'r.', 'MarkerSize', 15); hold on;

%% Plot successes
% second plot points with jitter on the x-axis
% xvals = jitterxaxis(toplotx);
% plot(xvals, toplotdoas, 'ko');


group = [repmat({'Success'}, length(combineddoas), 1); repmat({'Failure'}, length(combinedfaildoas), 1)];
toplotdoas = [combineddoas; combinedfaildoas];
% first plot boxplot
bh = boxplot(toplotdoas, group, 'Symbol', ''); hold on; axes = gca; currfig = gcf;

title(['Success Vs. Failure Per Patient']);
if strcmp(metric, 'jaccard')
    axes.YLim = [0, 1];
    ylabel('Jaccard Index');
else 
    axes.YLim = [-1, 1];
    ylabel('DOA');
end

% plot(1, mean(doas), 'dg')
% plot(2, mean(faildoas), 'dg')
axes.FontSize = FONTSIZE;
toSaveFigFile = fullfile(figDir, strcat('CCandNIH', 'perpatwopt6_combined_doaanalysis'));
print(toSaveFigFile, '-dpng', '-r0')
