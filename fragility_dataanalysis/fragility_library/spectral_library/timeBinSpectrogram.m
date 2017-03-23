%%% function timeBinSpectrogram
%%% Input: 
%%%  - spectMat:     #freqs. X #timepoints = 2D array
%%%  - WinLength: The size of the window (ms)
%%%  - Overlap: The overlap of all windows (ms)
%%% Output:
%%%  - spect: the new spectrogram with (#events X #freqs X numTimeWins)
%%%  size array
function spect = timeBinSpectrogram(spectMat, WinLength, Overlap)
    % initialize # events, # freqs., # times and spectrogram array
    numFreqs = size(spectMat,1);
    numTimeWindows = (size(spectMat,2) - WinLength)/Overlap + 1;
    spect = zeros(numFreqs, numTimeWindows);

    % do the first time point, cuz matlab doesn't index at 0
    windowSpect = spectMat(:,1:(1*WinLength));
    spect(:,1) = mean(windowSpect,2);
    
    % loop through number of time windows
    for iTime=1:numTimeWindows-1,
        % get the window in that spectrogram and average it
        spect(:,iTime+1) = mean(spectMat(:,iTime*Overlap+1:iTime*Overlap+WinLength),2);
    end
    
    % check if return array dimensions are correct
    if ~isequal(size(spect),[size(spectMat,1),numTimeWindows]),
        disp('error in timeBinSpectrogram.m')
    end
end