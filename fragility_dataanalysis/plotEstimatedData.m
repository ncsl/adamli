%%% Script: plotEstimatedData.m
% Author: Kristin 
% edited by: Adam Li
% 
% Used to plot estimated data from the linear time varying model of A_i
% (some functional connectivity matrix changing over time windows). Then
% compare the orginal eeg plots and the estimated eeg plots. Then compute
% and compare the mean squared error between the two.
%
% *Figures to be used in EMBC 2017 publication

close all; clear all; clc;
%% Estimate A for different windowsizes, then use a reduced order observer to estimate signals from some of the channels, using A_hat

BP_FILTER = 1;
% only use these two if working from external hard drive
% path1 = genpath('/Volumes/NIL_PASS/data/');
% path2 = genpath('/Volumes/NIL_PASS/serverdata/nofilter_adj_mats_win500_step500_freq1000/');
% 
% path1 = genpath(strcat('./serverdata/nofilter_adj_mats_win', num2str(winSize), '_step', num2str(winSize), '_freq1000/'));
% path2 = genpath('./data/');
% addpath(path1, path2);

addpath(genpath('./eeg_toolbox'));

winSize = 500;
frequency_sampling = 1000;
dataDir = './data/';
if BP_FILTER
    adjDir = strcat('./serverdata/fixed_adj_mats_win', num2str(winSize), '_step', num2str(winSize), '_freq1000/');
else
    adjDir = strcat('./serverdata/nofilter_adj_mats_win', num2str(winSize), '_step', num2str(winSize), '_freq1000/');
end
nihpat = 'pt1sz4';
ccpat = 'EZT019';
%% Load in data
nihadjmat = load(fullfile(adjDir, nihpat, 'pt1sz4_adjmats_leastsquares.mat'));            % Patient NIH linear models A 3D matrix with all A matrices for 500 msec wins (numWins x numChannels x numChannels)
ccadjmat = load(fullfile(adjDir, strcat(ccpat, '_seiz002'), 'EZT019_seiz002_adjmats_leastsquares.mat'));     % Patient CC linear models

ecogdata = load(fullfile(dataDir, nihpat, 'pt1sz4.mat'));          % Patient ECoG raw data
seegdata = load(fullfile(dataDir, 'Seiz_Data', ccpat, 'EZT019_seiz002.mat')); % Patient SEEG raw data

if BP_FILTER
    ecogdata.data = buttfilt(ecogdata.data,[59.5 60.5], frequency_sampling,'stop',1);
    seegdata.data = buttfilt(seegdata.data,[59.5 60.5], frequency_sampling,'stop',1);
end
%% Define parameters
data = ecogdata.data;
seizureStart = ecogdata.seiz_start_mark;
adjmat_struct = nihadjmat.adjmat_struct;

data = seegdata.data;
seizureStart = seegdata.seiz_start_mark-1;
adjmat_struct = ccadjmat.adjmat_struct;

numCh = size(data,1);
fs = 1000;
nSample = 5;       % how many different times we want to sample when using the observer for each number of missing channels
%% Use A and reconstruct raw data
seizureStartMark = adjmat_struct.seizure_start/adjmat_struct.winSize;

data = data(adjmat_struct.included_channels,:);
winSize = adjmat_struct.winSize;

% only get -60 seconds to seizure
% preSeizData = data(:, seizureStart-60*fs:seizureStart-1);
% preSeizA = adjmat_struct.adjMats(seizureStartMark-60*fs/winSize-1:seizureStartMark,:,:);

preSeizData = data(:, 1:seizureStart);
preSeizA = adjmat_struct.adjMats(1:seizureStartMark,:,:);

% only get seizure to +30 seconds
postSeizData = data(:, seizureStart:seizureStart+30*fs);
postSeizA = adjmat_struct.adjMats(seizureStartMark:seizureStartMark+30*fs/winSize-1,:,:);

%% Reconstruct preseizure data
preSeiz_hat = zeros(size(preSeizData));
[numChans, numTimes] = size(preSeizData);
numWins = numTimes / winSize;
if numWins ~= size(preSeizA, 1);
    disp('There is an error in the number of windows!');
end

evals = zeros(numWins, 1);
tic;
for iWin=1:numWins              % loop through number of windows
    initialTime = (iWin-1)*winSize + 1;
    preSeiz_hat(:, initialTime) = preSeizData(:, initialTime);
    
    currentA = squeeze(preSeizA(iWin, :, :));
    for iTime=initialTime+1:initialTime+winSize-1   % loop through time points to estimate data
%         iTime
        preSeiz_hat(:, iTime) = currentA*preSeiz_hat(:, iTime-1);
        
        
    end
    evals(iWin) = max(abs(eig(currentA)));
end
toc;

% compute difference metric between observed and estimated
error = norm(preSeiz_hat(exChan, :) - preSeizData(exChan,:)) / numWins;


exChan = 2;
chanData = preSeizData(exChan, :);
chanHat = preSeiz_hat(exChan, :);
figure;
plot(chanData(1:9000), 'k'); hold on;
plot(chanHat(1:9000), 'r')

figure;
plot(evals, 'ko')
%% Reconstruct postseizure data
postSeiz_hat = zeros(size(postSeizData));
[numChans, numTimes] = size(postSeizData);
numWins = numTimes / winSize;

if numWins ~= size(postSeizA, 1);
    disp('There is an error in the number of windows!');
end

for iWin=1:numWins              % loop through number of windows
    initialTime = (iWin-1)*winSize + 1;
    postSeiz_hat(:, initialTime) = postSeizData(:, initialTime);
    
    currentA = squeeze(postSeizA(iWin, :, :));
    for iTime=initialTime+1:initialTime+winSize-1   % loop through time points to estimate data
        iTime
        postSeiz_hat(:, iTime) = currentA*postSeiz_hat(:, iTime-1);
    end
    
%     exChan = 2;
%     chanData = preSeizData(exChan, :);
%     chanHat = preSeiz_hat(exChan, :);
%     figure;
%     plot(chanData(1:2000), 'k'); hold on;
%     plot(chanHat(1:2000), 'r')
end


%% Define actual measured and unmeasured variables for plotting
numX = size(A_hat,1);           % number of variables
indM = find(sum(C_hat,1)>0);   % measured variables
indU = 1:numX;          % unmeasured variables
indU(indM) = [];
xu = data(indU,:);  % unmeasured, t = 0:n
xm = data(indM,:);  % measured, t = 0:n
numU = size(indU,2);

%% Plot subplots of estimated vs. actual
% Define parameters for plotting 
p_winsize = 0.5*fs;        % in samples (here: plotting 500 msec at a time)
chOff = 100;
channelOffset = repmat(chOff*(1:numU)',1,size(data,2));

for pwin = 6%1:p_numWin
    time = linspace(0,p_winsize,p_winsize);       % msec
%     time = linspace((pwin-1)*p_winsize+1,pwin*p_winsize,p_winsize);       % msec
    p_data = data(indU,(pwin-1)*p_winsize+1:pwin*p_winsize);
    p_xu_est = xu_est(:,(pwin-1)*p_winsize+1:pwin*p_winsize);
     
    f1 = figure;
    for u = 1:5
        subplot(5,1,u)
        plot(time,p_data(u,:),'b','LineWidth',1.2)
        hold on
        plot(time,p_xu_est(u,:),'m')
        legend('actual','observer estimate')
%         ylabel([X_name{indU(u)},' (unmeasured)'])
        ylabel(elec_labels(indU(u)))
        axis('tight')
        if u == 1
            title('$$x^u$$[t] vs. $$\hat{x}^u$$[t]','Interpreter','Latex')
        end
        if u == 5
            xlabel('t (msec)')
        end
    end
%     pause;

    f2 = figure;
    for u = 6:10
        subplot(5,1,u-5)
        plot(time,p_data(u,:),'b','LineWidth',1.2)
        hold on
        plot(time,p_xu_est(u,:),'m')
        legend('actual','observer estimate')
%         ylabel([X_name{indU(u)},' (unmeasured)'])
        ylabel(elec_labels(indU(u)))
        axis('tight')
        if u == 1+5
            title('$$x^u$$[t] vs. $$\hat{x}^u$$[t]','Interpreter','Latex')
        end
        if u == 5+5
            xlabel('t (msec)')
        end
    end
    
    f3 = figure;
    for u = 11:15
        subplot(5,1,u-10)
        plot(time,p_data(u,:),'b','LineWidth',1.2)
        hold on
        plot(time,p_xu_est(u,:),'m')
        legend('actual','observer estimate')
%         ylabel([X_name{indU(u)},' (unmeasured)'])
        ylabel(elec_labels(indU(u)))
        axis('tight')
        if u == 1+10
            title('$$x^u$$[t] vs. $$\hat{x}^u$$[t]','Interpreter','Latex')
        end
        if u == 5+10
            xlabel('t (msec)')
        end
    end
    
end