% function: computeSpectralPower
% By: Adam Li | 3/21/17
% Description: Used to compute power for an eeg wave
%
% Example:
% transformArgs.winSize = 500;
% transformArgs.stepSize = 250;
% transformArgs.mtBandWidth = 4;
% transformArgs.mtFreqs = [];
% [powerMat, phaseMat] = computeSpectralPower(eegWave, fs, freqs, 'fourier', transformArgs);
% 
function [powerMat, phaseMat, freqs, t_sec] = computeSpectralPower(eegWave, fs, typeTransform, transformArgs)
    %% INPUT INITIAL ARGUMENTS TO TEST
    if nargin == 0
        disp('No arguments, so feeding in test data!\n');
        datafile = fullfile('~/Downloads/pt1sz2.mat');
        data = load(datafile);
        
        eegWave = data.data;
        fs = data.fs;
        typeTransform = 'fourier';
        winSize = 250;
        stepSize = 125;
        transformArgs.winSize = winSize;
        transformArgs.stepSize = stepSize;
        transformArgs.mtBandWidth = 4;
        transformArgs.mtFreqs = [];
    end

    %% Initial Argument Checking
    %- check user entered in correct transforms
    transforms = {'morlet', 'fourier'};
    if ~strmatch(typeTransform, transforms)
        disp('Enter in either morlet or fourier as a transform.');
    end
    
    %- intialize buffer region if transform calls for it
    BufferMS = 1000 * fs/1000; % buffer region of 1 second (milliseconds)
    
    t_sec = -1;
    
    [N, T] = size(eegWave);
    disp(['Number of channels: ', num2str(N)]);
    disp(['Number of time points: ', num2str(T)]);
    %% Perform spectral computation
    if strcmp(typeTransform, 'morlet')
        %- extract arguments
        waveletWidth = transformArgs.waveletWidth;
        freqs = transformArgs.waveletFreqs;
        
        % add buffer to the eeg wave
        eegWave = [zeros(1, BufferMS), eegWave, zeros(1, BufferMS)];
        
        %%- i. multiphasevec3: get the phase and power for events x frequency x duration of time for each channel
        [rawPhase,rawPow] = multiphasevec3(freqs,eegWave,fs,waveletWidth);

        %%- ii. REMOVE LEADING/TRAILING buffer areas from power, phase, eegWave, timeVector
        rawPow   = rawPow(:,:,BufferMS+1:end-BufferMS);
        rawPhase = rawPhase(:,:,BufferMS+1:end-BufferMS);
        
        %%- iii. make powerMat, phaseMat and set time and freq axis
        % chan X event X freq X time
        % make power 10*log(power)
        powerMat = 10*log10(rawPow); % log transform the power
        phaseMat = rawPhase;
    elseif strcmp(typeTransform, 'fourier')
        winSize = transformArgs.winSize;
        stepSize = transformArgs.stepSize;
        mtBandWidth = transformArgs.mtBandWidth;        % number of times to avge the FFT
        mtFreqs = transformArgs.mtFreqs;
        
        %%- i. eeg_mtwelch2: get the phase and power using multitaper
        % parameters for multitaper FFT:
        % sampling freq, overlap, stepsize, bandwidth
        T = winSize/1000;       % the window size in milliseconds
        overlap = (winSize - stepSize)/winSize; % in percentage

        %%- multitaper FFT 
        [rawPowBase, freqs, t_sec,rawPhaseBase] = eeg_mtwelch2(eegWave, fs, T, overlap, mtBandWidth, mtFreqs, 'eigen');

        %%- ii. make powerMat, phaseMat and set time and freq axis
        powerMat = 10*log10(rawPowBase);
        phaseMat = rawPhaseBase;
    end
    
    %% Adding Test Saving of the Results to Compare with Other Methods Written in Python
    testfile = 'test.mat';
    save(fullfile('~/Downloads/', testfile), 'powerMat', 'phaseMat');
end