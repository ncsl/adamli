%%% function timeBinSpectrogram
%%% Input: 
%%%  - spectMat:     #freqs. X #timepoints = 2D array
%%%  - WinLength: The size of the window (ms)
%%%  - Overlap: The overlap of all windows (ms)
%%% Output:
%%%  - spect: the new spectrogram with (#events X #freqs X numTimeWins)
%%%  size array
function [spect, t_sec] = timeBinSpectrogram(spectMat, fs, WinLength, Overlap)
    WinLength = (WinLength / (1000 / fs));
    Overlap = (Overlap / (1000/fs));
    buffOverlap = Overlap;
    
    %- now round to prevent indicing error
    WinLength = floor(WinLength);
    Overlap = floor(Overlap);

    % initialize # events, # freqs., # times and spectrogram array
    numFreqs = size(spectMat,1);
    numTimeWindows = round((size(spectMat,2) - WinLength)/Overlap + 1);
  
    %- compute number of windows needed
    Nsamples = WinLength;
    ovrlp_samples = round(buffOverlap);
    [spect_windowed, rem] = buffer(spectMat(1,:),Nsamples,ovrlp_samples,'nodelay'); %- starts at first sample (nodelay option), and tosses out samples at end if final window is not filled (rem output contains partial)
    numTimeWindows = size(spect_windowed, 2);
    
    %- compute the time range in seconds for each window
    t_sec    = nan(numTimeWindows,2);
    t_sec(:) = [((1:numTimeWindows)-1)*(Nsamples-ovrlp_samples),((1:numTimeWindows)*(Nsamples-ovrlp_samples)+ovrlp_samples)]/fs;
  
    %- initialize return matrix
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