%%% function timeBinSpectrogram
%%% Input: 
%%%  - spectMat:     #events X #freqs. X #timepoints = 3D array
%%%  - rangeFreqs:  A nx2 matrix that holds the ranges for each freq.
%%%  window
%%%  - waveletFreqs: The vector of wavelet frequencies for each of the
%%%  bands in spectMat
%%%
%%% Output:
%%%  - newSpect: the new spectrogram with (#events X numFreqWins X #timepoints)
%%%  size array
function spect = freqBinSpectrogram(spectMat, rangeFreqs, waveletFreqs)
    % initialize # events, # freqs., # times and spectrogram array
    numEvents = size(spectMat,1);
    numFreqWindows = size(rangeFreqs,1);
    numTimes = size(spectMat,3);
    spect = zeros(numEvents, numFreqWindows, numTimes);
    
    for iFreq=1:numFreqWindows,
        lowerFreq = rangeFreqs(iFreq, 1);
        upperFreq = rangeFreqs(iFreq, 2);
        
        %%- go through indices in waveletFreqs and average those
        %%between lower and upper freq. -> append to eventpowerMat
        lowerInd = waveletFreqs >= lowerFreq;
        upperInd = waveletFreqs <= upperFreq;
        indices = lowerInd == upperInd; % binary selector index vector
        
        spect(:,iFreq,:) = mean(spectMat(:,indices,:), 2);
    end
    
    % check if return array dimensions are correct
    if ~isequal(size(spect),[size(spectMat,1),numFreqWindows, size(spectMat,3),]),
        disp('error in timeBinSpectrogram.m')
    end
end