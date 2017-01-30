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

winSizes = [125, 250, 500, 1000];
mses = zeros(length(winSizes), 1);

patient = 'pt1sz4';
% patient = 'EZT019seiz002';

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
    patient = strcat(patient_id, seizure_id);
else
    pat = patient;
end

[included_channels, ezone_labels, earlyspread_labels, latespread_labels, resection_labels, frequency_sampling, center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);

        
%%- Main Loop through Window Sizes
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
    rawdata = load(fullfile(dataDir, pat, patient));          % Patient ECoG raw data

    %- Optional: Apply notch filter or not
    if BP_FILTER
        rawdata.data = buttfilt(rawdata.data,[59.5 60.5], frequency_sampling,'stop',1);
    end
    %% Define parameters and Extract Fields
    data = rawdata.data;
    seizureStart = rawdata.seiz_start_mark;
    adjmat_struct = adjmat_struct.adjmat_struct;

    numCh = size(data,1);
    fs = 1000;
    nSample = 5;       % how many different times we want to sample when using the observer for each number of missing channels
    %% Use A and reconstruct raw data
    seizureStartMark = adjmat_struct.seizure_start/adjmat_struct.winSize;

    data = data(included_channels,:);
    winSize = adjmat_struct.winSize;
    labels = adjmat_struct.all_labels;
    
    if i==1
        %- get 2 channels from EZ and 2 channels from outside EZ
        ezElecs = findElectrodeIndices(ezone_labels, labels)';
        randez = randsample(length(ezone_labels), 2);
        ezIndices = ezElecs(randez);

        nonezChannels = 1:length(included_channels);
        nonezChannels(ezElecs) = [];
        randIndices = randsample(length(nonezChannels), 2);
        randIndices = nonezChannels(randIndices);

        % create indice vector of the channels we want to plot
        exChans = cat(2, ezIndices, randIndices);
    end
    
    % getting A and raw data
    preSeizData = double(data(:, 1:seizureStart+3000));
    preSeizA = adjmat_struct.adjMats(1:seizureStartMark+3000/winSize,:,:);
    
    if seeg
        preSeizData = double(data(:, 1:seizureStart-1+3000));
        seizureStartMark = (seizureStart-1)/winSize;
        preSeizA = adjmat_struct.adjMats(1:seizureStartMark+3000/winSize,:,:);
    end
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
%         if max(abs(eig(currentA))) > 1
%             [V, D] = eig(currentA, 'nobalance');
%             overEvs = D(abs(D) > 1);
%             theta = tanh(imag(overEvs)./real(overEvs));
%             bprime = sin(theta);
%             aprime = sqrt(1 - bprime.^2);
%             D(abs(D) > 1) = aprime+1i*bprime;
%             newA = abs(V*D*inv(V));
%             
%             imagesc(currentA)
%         end
        for iTime=initialTime+1:initialTime+winSize-1   % loop through time points to estimate data
    %         iTime
            preSeiz_hat(:, iTime) = currentA*preSeiz_hat(:, iTime-1);
        end
        evals(iWin) = max(abs(eig(currentA)));
    end
    toc;
    
    timePoints = [1:2000, seizureStart-2000:seizureStart, seizureStart+500:seizureStart+2500];
    timePoints = [1:2000, seizureStart-2000:seizureStart, seizureStart+500:seizureStart+2500];
    %% Plotting
    FONTSIZE = 24;
    offset = 0;
    temp = preSeizData(exChans,timePoints);
    maxoffset = 1.5 * max(abs(temp(:)));

    if ~seeg
        titleStr = {'Estimated ECoG Data Vs. Actual Data', ...
            strcat('For Window Size (', num2str(winSize), ')')};
    else
        titleStr = {'Estimated SEEG Data Vs. Actual Data', ...
        strcat('For Window Size (', num2str(winSize), ')')};
    end
    
    fig = figure;
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
        
        if iChan==1
            minVal = min([prevdatatrue, prevdatahat]); 
            maxVal = max([prevdatatrue, prevdatahat]); 
        else    
            minVal = min([minVal, prevdatatrue, prevdatahat]); 
            maxVal = max([maxVal, prevdatatrue, prevdatahat]);
        end
        
        offset = 10;
        
        plot(datahat, 'k', 'LineWidth', 1.75); hold on;
        plot(datatrue, 'r--', 'LineWidth', 3); 
        
        yticklocs(iChan) = mean(datatrue);
    end
    ax = gca; currfig = gcf; 
    set(ax, 'box', 'off');
    xlabel('Time Period (2 seconds per window)', 'FontSize', FONTSIZE);
    ylab = ylabel('Electrodes', 'FontSize', FONTSIZE);
    title(titleStr, 'FontSize', FONTSIZE);
    leg = legend('LTV Model', 'Actual Data');
   
    % set x axes
    set(ax, 'XTick', [1000 3000 5000]);
    set(ax, 'XTickLabel', {'Interictal', 'Preictal', 'Ictal'}, 'FontSize', FONTSIZE);

    currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
    currfig.Position = [1666 1 1535 1121];
    ylab.Position = ylab.Position + [6 0 0]; % move ylabel to the left

    plot([2000 2000], ylim, 'k', 'MarkerSize', 3)
    plot([4000 4000], ylim, 'k', 'MarkerSize', 3)
    
    xlim([0 6000])
    ax1 = currfig.CurrentAxes; % get the current axes
    ax1_xlim = ax1.XLim;
    ax1_ylim = ax1.YLim;
    set(ax1, 'YTick', []);
    %%- Create the first axes to label the original electrodes
    axy = axes('Position',ax1.Position,...
        'XAxisLocation','bottom',...
        'YAxisLocation','left',...
            'XLim', ax1_xlim,...
    'YLim', ax1_ylim,...
        'Color','none', ...
        'box', 'off');
    set(axy, 'XTick', []);
    set(axy, 'YTick', yticklocs(1:2), 'YTickLabel', labels(ezIndices), 'FontSize', FONTSIZE, 'YColor', 'red');

    %%- Create new axes to label the electrode axis (y-axis)
    % set second axes for ezone indices
    ax2 = axes('Position',ax1.Position,...
        'XAxisLocation','bottom',...
        'YAxisLocation','left',...
        'Color','none', ...
        'XLim', ax1_xlim,...
        'YLim', ax1_ylim,...
        'box', 'off');
    set(ax2, 'XTick', []);
    set(ax2, 'YTick', yticklocs(3:4), 'YTickLabel', labels(randIndices), 'FontSize', FONTSIZE);
    leg.Position = leg.Position + [0.05 0.075 0 0];
    
    toSaveFigDir = fullfile('./figures/ltvcomparison/', center);
    if ~exist(toSaveFigDir, 'dir')
        mkdir(toSaveFigDir);
    end
    
    toSaveFigFile = fullfile(toSaveFigDir, strcat(patient, '_ecog1_', num2str(winSize)));
    print(toSaveFigFile, '-dpng', '-r0')
    
    % store MSE of Reconstruction
    mse = immse(preSeiz_hat(exChans, timePoints), preSeizData(exChans,timePoints))/ (length(timePoints));
    mses(i) = mse;
end

figure;
bar(winSizes, mses, 'k'); set(gca, 'box', 'off');
    if ~seeg
        title('Mean Squared Error of ECoG Reconstruction', 'FontSize', FONTSIZE);
    else
        title('Mean Squared Error of SEEG Reconstruction', 'FontSize', FONTSIZE);
    end

xlabel('Window Size', 'FontSize', FONTSIZE);
ylabel('Mean Squared Error', 'FontSize', FONTSIZE);
set(gca, 'XTickLabel', [125 250 500 100], 'FontSize', FONTSIZE);
currfig = gcf;
currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
currfig.Position = [1666 1 1535 1121];
toSaveFigFile = fullfile(toSaveFigDir, strcat(patient, '_ecogerrors1_', num2str(winSize)));
print(toSaveFigFile, '-dpng', '-r0')