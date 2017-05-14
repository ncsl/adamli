% FUNCTION: computeConnectivity
%
% Note: Need to add in libraries (Example Below):
% add libraries of functions
% addpath(genpath('/Users/adam2392/Dropbox/eeg_toolbox'));
% addpath(genpath('/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/eeg_toolbox/'));
% 
% - eeg_toolbox has the toolkit for doing a notch filter 
%
% Inputs:
% 1. eeg: The eeg time series matrix N x T (number of channels by time)
% 2. adj_args: The arguments to run computation
%
% Outputs:
% 1. adjMats: 3D matrix that is N x N x T 
function [adjMats, timePoints] = computeConnectivity(eeg, adj_args, VERBOSE)
    if nargin==2
        VERBOSE = 0;
    end
    
    % extract arguments and clinical annotations
    BP_FILTER_RAW = adj_args.BP_FILTER_RAW; % apply notch filter or not?
    frequency_sampling = adj_args.frequency_sampling; % frequency that this eeg data was sampled at
    winSize = adj_args.winSize;
    stepSize = adj_args.stepSize;
    seizureStart = adj_args.seizureStart; % time seizure starts
    seizureEnd = adj_args.seizureEnd; % time seizure ends
    l2regularization = adj_args.l2regularization;
    numHarmonics = adj_args.numHarmonics;
    
    TYPE_CONNECTIVITY = adj_args.TYPE_CONNECTIVITY;

    % set options for connectivity measurements
    OPTIONS.l2regularization = l2regularization;

    %- apply a bandpass filter raw data? (i.e. pre-filter the wave?)
    if BP_FILTER_RAW==1,
        preFiltFreq      = [1 499];   %[1 499] [2 250]; first bandpass filter data from 1-499 Hz
        preFiltType      = 'bandpass';
        preFiltOrder     = 2;
        preFiltStr       = sprintf('%s filter raw; %.1f - %.1f Hz',preFiltType,preFiltFreq);
        preFiltStrShort  = '_BPfilt';
        % apply band notch filter to eeg data
        eeg = buttfilt(eeg,[59.5 60.5], frequency_sampling,'stop',1);
        eeg = buttfilt(eeg,[119.5 120.5], frequency_sampling,'stop',1);
        if frequency_sampling >= 250
            eeg = buttfilt(eeg,[179.5 180.5], frequency_sampling,'stop',1);
            eeg = buttfilt(eeg,[239.5 240.5], frequency_sampling,'stop',1);
            
            if frequency_sampling >= 500
                eeg = buttfilt(eeg,[299.5 300.5], frequency_sampling,'stop',1);
                eeg = buttfilt(eeg,[359.5 360.5], frequency_sampling,'stop',1);
                eeg = buttfilt(eeg,[419.5 420.5], frequency_sampling,'stop',1);
                eeg = buttfilt(eeg,[479.5 480.5], frequency_sampling,'stop',1);
            end
        end
    elseif BP_FILTER_RAW == 2,
        disp('Adaptive filtering ...');
        % apply an adaptive filtering algorithm.
        eeg = removePLI_multichan(eeg, frequency_sampling, numHarmonics, [50,0.01,4], [0.1,2,4], 2, 60);
    else
        preFiltFreq      = []; %keep this empty to avoid any filtering of the raw data
        preFiltType      = 'stop';
        preFiltOrder     = 1;
        preFiltStr       = 'Unfiltered raw traces';
        preFiltStrShort  = '_noFilt';
    end

    % window parameters - overlap, #samples, stepsize, window pointer
    [num_channels, lenData] = size(eeg); % length of data in seconds
    numWindows = lenData/stepSize;

    % initialize timePoints vector and adjacency matrices
    timePoints = [1:stepSize:lenData-winSize+1; winSize:stepSize:lenData]';
    adjMats = zeros(size(timePoints,1), num_channels, num_channels);

    % display data 
    if VERBOSE
        disp(['Length of to be included channels ', num2str(size(eeg,1))]);
        disp(['Seizure starts at ', num2str(seizureStart), ' milliseconds']);
        disp(['Seizure ends at ', num2str(seizureEnd), ' milliseconds']);
        disp(['Running analysis for ', num2str(numWindows), ' windows']);
    end
    
    for i=1:numWindows
        % step 1: extract the data and apply the notch filter. Note that column
        %         #i in the extracted matrix is filled by data samples from the
        %         recording channel #i.
        tmpdata = eeg(:, timePoints(i,1):timePoints(i,2));

        % step 2: compute some functional connectivity 
        if strcmp(TYPE_CONNECTIVITY, 'leastsquares')
            % linear model: Ax = b; A\b -> x
            b = double(tmpdata(:)); % define b as vectorized by stacking columns on top of another
            b = b(num_channels+1:end); % only get the time points after the first one

            % - use least square computation
            theta = computeLeastSquares(tmpdata, b, OPTIONS);
            theta_adj = reshape(theta, num_channels, num_channels)';    % reshape fills in columns first, so must transpose
        elseif strcmp(TYPE_CONNECTIVITY, 'spearman') || strcmp(TYPE_CONNECTIVITY, 'pearson')
            theta_adj = computePairwiseCorrelation(tmpdata, TYPE_CONNECTIVITY);
        elseif strcmp(TYPE_CONNECTIVITY, 'PDC')
            A = theta_adj; 
            p_opt = 1;
            Nf = 250;
            [~, PDC] = computeDTFandPDC(A, p_opt, frequency_sampling, Nf);
        elseif strcmp(TYPE_CONNECTIVITY, 'DTF')
            [DTF, ~] = computeDTFandPDC(A, p_opt, frequency_sampling, Nf);
        end

        % step 3: store the computed adjacency matrix
        adjMats(i, :, :) = theta_adj;

        % display a message for the user
        disp(['Finished: ', num2str(i), ' out of ', num2str(numWindows)]);
    end
end