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

BP_FILTER = 0;
% only use these two if working from external hard drive
% path1 = genpath('/Volumes/NIL_PASS/data/');
% path2 = genpath('/Volumes/NIL_PASS/serverdata/nofilter_adj_mats_win500_step500_freq1000/');
% 
% path1 = genpath(strcat('./serverdata/nofilter_adj_mats_win', num2str(winSize), '_step', num2str(winSize), '_freq1000/'));
% path2 = genpath('./data/');
% addpath(path1, path2);

addpath(genpath('./eeg_toolbox'));

winSize = 500;
winSizes = [125, 250, 500, 1000];

errors = zeros(length(winSizes), 1);
mses = zeros(length(winSizes), 1);

patient = 'pt1sz4';
patient = 'EZT019seiz002';

patient_id = patient(1:strfind(patient, 'seiz')-1);
seizure_id = strcat('_', patient(strfind(patient, 'seiz'):end));
seeg = 1;
if isempty(patient_id)
    patient_id = patient(1:strfind(patient, 'sz')-1);
    seizure_id = patient(strfind(patient, 'sz'):end);
    seeg = 0;
end
if isempty(patient_id)
    patient_id = patient(1:strfind(patient, 'aslp')-1);
    seizure_id = patient(strfind(patient, 'aslp'):end);
    seeg = 0;
end
if isempty(patient_id)
    patient_id = patient(1:strfind(patient, 'aw')-1);
    seizure_id = patient(strfind(patient, 'aw'):end);
    seeg = 0;
end

if seeg
    pat = patient_id;
else
    pat = patient;
end

[included_channels, ezone_labels, earlyspread_labels, latespread_labels, resection_labels, frequency_sampling, center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);

for i=1:length(winSizes)
    winSize = winSizes(i);

    frequency_sampling = 1000;
    dataDir = fullfile('./data/', center);
%     dataDir = '/Volumes/NIL_PASS/data/';
    if BP_FILTER
        adjDir = strcat('./serverdata/testing_winsizes/fixed_adj_mats_win', num2str(winSize), '_step', num2str(winSize), '_freq1000/');
%         adjDir = strcat('/Volumes/NIL_PASS/serverdata/fixed_adj_mats_win', num2str(winSize), '_step', num2str(winSize), '_freq1000/');
    else
        adjDir = strcat('./serverdata/testing_winsizes/nofilter_adj_mats_win', num2str(winSize), '_step', num2str(winSize), '_freq1000/');
%         adjDir = strcat('/Volumes/NIL_PASS/serverdata/nofilter_adj_mats_win', num2str(winSize), '_step', num2str(winSize), '_freq1000/');
    end
    

    %% Load in data
    %- 1. adj mat structure
    try
        adjmat_struct = load(fullfile(adjDir, pat, strcat(patient, '_adjmats_leastsquares.mat')));            % Patient NIH linear models A 3D matrix with all A matrices for 500 msec wins (numWins x numChannels x numChannels)
    catch e
        disp(e)
        adjmat_struct = load(fullfile(adjDir, strcat(patient, '_adjmats_leastsquares.mat')));            % Patient NIH linear models A 3D matrix with all A matrices for 500 msec wins (numWins x numChannels x numChannels)
    end
    
    %- 2. raw data
    data = load(fullfile(dataDir, pat, patient));          % Patient ECoG raw data

    %- Optional: Apply notch filter or not
    if BP_FILTER
        data.data = buttfilt(data.data,[59.5 60.5], frequency_sampling,'stop',1);
    end
    %% Define parameters and Extract Fields
    data = data.data;
    seizureStart = data.seiz_start_mark;
    adjmat_struct = adjmat_struct.adjmat_struct;

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

    preSeizData = double(data(:, 1:seizureStart));
    preSeizA = adjmat_struct.adjMats(1:seizureStartMark,:,:);

    % only get seizure to +30 seconds
    postSeizData = double(data(:, seizureStart:seizureStart+30*fs));
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

    exChans = [2, 3, 5, 6, 7];
    exChan = 2;
    
    % compute difference metric between observed and estimated
    error = norm(preSeiz_hat(exChans, :) - preSeizData(exChans,:)) / numWins;
    mse = immse(preSeiz_hat(exChans, :), preSeizData(exChans,:));

    %% Plotting
    FONTSIZE = 18;
    timePoints = 1:700;
    offset = 0;
    temp = preSeizData(exChans,timePoints);
    maxoffset = 1.5 * max(abs(temp(:)));

    titleStr = {'Estimated ECoG Data Vs. Actual Data', ...
        strcat('For Window Size (', num2str(winSize), ')')};
    titleStr = {'Estimated SEEG Data Vs. Actual Data', ...
        strcat('For Window Size (', num2str(winSize), ')')};
    
    
    figure;
%     subplot(211);
    yticklocs = zeros(length(exChans),1);
    for iChan=1:length(exChans)
        exChan = exChans(iChan);
        
        % get the data for this channel
        if iChan == 1
            datahat = preSeiz_hat(exChan, timePoints);
            datatrue = preSeizData(exChan, timePoints);
            
            prevdatahat = datahat;
            prevdatatrue = datatrue;
        else
            datahat = preSeiz_hat(exChan, timePoints) + offset;
            datatrue = preSeizData(exChan, timePoints) + offset;
            
            while(max(prevdatatrue) > min(datatrue))
                datatrue = datatrue + offset;
                datahat = datahat + offset;
            end
            
            prevdatahat = datahat;
            prevdatatrue = datatrue;
        end
        
        offset = 50;
        
        plot(datahat, 'k'); hold on;
        plot(datatrue, 'r'); 
        
        yticklocs(iChan) = mean(datatrue);
    end
    axes = gca; currfig = gcf;
    set(axes, 'box', 'off');
    xlabel('Time (seconds)', 'FontSize', FONTSIZE);
    ylabel('Electrodes', 'FontSize', FONTSIZE);
    title(titleStr, 'FontSize', FONTSIZE);
    legend('LTV Model', 'Actual Data');
    
    % set y axes
    set(axes, 'YTick', yticklocs);
    set(axes, 'YTickLabel', {adjmat_struct.all_labels{exChans}});
    % set x axes
    set(axes, 'XTick', 1:200:length(timePoints));
    set(axes, 'XTickLabel', 0:0.2:length(timePoints)/frequency_sampling);

    currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
    currfig.Position = [1666 1 1535 1121];
    toSaveFigDir = fullfile('./figures/ltvcomparison/ecog/');
    if ~exist(toSaveFigDir, 'dir')
        mkdir(toSaveFigDir);
    end
    toSaveFigFile = fullfile(toSaveFigDir, strcat(patient, '_seegdata_', num2str(winSize)));
    print(toSaveFigFile, '-dpng', '-r0')
    
    error = norm(preSeiz_hat(exChans, timePoints) - preSeizData(exChans,timePoints)) / (length(timePoints));
    mse = immse(preSeiz_hat(exChans, timePoints), preSeizData(exChans,timePoints))/ (length(timePoints));
    errors(i) = error;
    mses(i) = mse;
    %% Reconstruct postseizure data
    % postSeiz_hat = zeros(size(postSeizData));
    % [numChans, numTimes] = size(postSeizData);
    % numWins = numTimes / winSize;
    % 
    % if numWins ~= size(postSeizA, 1);
    %     disp('There is an error in the number of windows!');
    % end
    % 
    % for iWin=1:numWins              % loop through number of windows
    %     initialTime = (iWin-1)*winSize + 1;
    %     postSeiz_hat(:, initialTime) = postSeizData(:, initialTime);
    %     
    %     currentA = squeeze(postSeizA(iWin, :, :));
    %     for iTime=initialTime+1:initialTime+winSize-1   % loop through time points to estimate data
    %         iTime
    %         postSeiz_hat(:, iTime) = currentA*postSeiz_hat(:, iTime-1);
    %     end
    %     
    % %     exChan = 2;
    % %     chanData = preSeizData(exChan, :);
    % %     chanHat = preSeiz_hat(exChan, :);
    % %     figure;
    % %     plot(chanData(1:2000), 'k'); hold on;
    % %     plot(chanHat(1:2000), 'r')
    % end
end

winSizes(winSizes==250) = [];
errors(4) = [];
mses(4) = [];

figure;
subplot(211); % plot errors
plot(winSizes, errors, 'ko');
title('Plot of Reconstruction Error', 'FontSize', FONTSIZE);

subplot(212);
plot(winSizes, mses, 'ko');
title('Mean Squared Error', 'FontSize', FONTSIZE);
currfig = gcf;
currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
currfig.Position = [1666 1 1535 1121];
toSaveFigFile = fullfile(toSaveFigDir, strcat(patient, '_seegerrorswithout250_', num2str(winSize)));
print(toSaveFigFile, '-dpng', '-r0')