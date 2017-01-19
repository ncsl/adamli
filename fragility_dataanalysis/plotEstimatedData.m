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

path1 = genpath('/Volumes/NIL_PASS/data/');
path2 = genpath('/Volumes/NIL_PASS/serverdata/fixed_adj_mats_win500_step500_freq1000/');
addpath(path1, path2);

%% Load in data
nihadjmat = load('pt1sz2_adjmats_leastsquares.mat');            % Patient NIH linear models A 3D matrix with all A matrices for 500 msec wins (numWins x numChannels x numChannels)
ccadjmat = load('EZT019_seiz002_adjmats_leastsquares.mat');    % Patient CC linear models

ecogdata = load('pt1sz2.mat')          % Patient ECoG raw data
seegdata = load('EZT019_seiz002.mat'); % Patient SEEG raw data

%% Define parameters
data = ecogdata.data;
seizureStart = ecogdata.seiz_start_mark;

numCh = size(data,1);
fs = 1000;
nSample = 5;       % how many different times we want to sample when using the observer for each number of missing channels

winsizes = 250:50:500;       % Size of window in samples
% time = linspace(0,winsize/fs*1000,winsize); % msec
% n = winsize;    % number of points

X_name = cell(numCh,1);
Xhat_name = X_name;
for i = 1:numCh
    X_name{i} = ['x',num2str(i)];
    Xhat_name{i} = ['x',num2str(i),'hat'];
end
%% Use A and reconstruct raw data
adjmat_struct = nihadjmat.adjmat_struct;
seizureStartMark = adjmat_struct.seizure_start/adjmat_struct.winSize;

data = data(adjmat_struct.included_channels,:);
winSize = adjmat_struct.winSize;

% only get -60 seconds to seizure
preSeizData = data(:, seizureStart-60*fs:seizureStart-1);
preSeizA = adjmat_struct.adjMats(seizureStartMark-60*fs/winSize:seizureStartMark-1,:,:);

% only get seizure to +30 seconds
postSeizData = data(:, seizureStart:seizureStart+30*fs-1);
postSeizA = adjmat_struct.adjMats(seizureStartMark:seizureStartMark+30*fs/winSize-1,:,:);

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