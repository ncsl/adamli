%%% function timeBinSpectrogram
%%% Input: 
%%%  - spectMat:     #events X #freqs. X #timepoints = 3D array
%%%  - WinLength: The size of the window (ms)
%%%  - Overlap: The overlap of all windows (ms)
%%% Output:
%%%  - spect: the new spectrogram with (#events X #freqs X numTimeWins)
%%%  size array
function spect = timeBinSpectrogram(spectMat, WinLength, Overlap)
    % initialize # events, # freqs., # times and spectrogram array
    numEvents = size(spectMat,1);
    numFreqs = size(spectMat,2);
    numTimeWindows = (size(spectMat,3) - WinLength)/Overlap + 1;
    spect = zeros(numEvents, numFreqs, numTimeWindows);

    % do the first time point, cuz matlab doesn't index at 0
    windowSpect = spectMat(:,:,1:(1*WinLength));
    spect(:,:,1) = mean(windowSpect,3);
    
    % loop through number of time windows
    for iTime=1:numTimeWindows-1,
        % get the window in that spectrogram and average it
        spect(:,:,iTime+1) = mean(spectMat(:,:,iTime*Overlap+1:iTime*Overlap+WinLength),3);
    end
    
    % check if return array dimensions are correct
    if ~isequal(size(spect),[size(spectMat,1),size(spectMat,2),numTimeWindows]),
        disp('error in timeBinSpectrogram.m')
    end
end