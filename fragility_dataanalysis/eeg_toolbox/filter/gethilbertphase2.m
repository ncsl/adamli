function [phase,amp,eeg] = gethilbertphase2(chan,events,DurationMS,OffsetMS,BufferMS,bandpassFreq,notchFilterFreq,resampleFreq)
%GETHILBERTPHASE2 - uses a hilbert transformation to get the instantaneous phase
%in a *several* bandpassed frequency band.  This is just like
%gethilbertphase but does multiple bands at the same time
%
% FUNCTION: 
% [phase,amp,eeg] = gethilbertphase2(chan,events,DurationMS,OffsetMS,BufferMS,bandpassFreq,notchFilterFreq,resampleFreq)
%
% INPUT ARGs:
%   chan = 2
%   events = events
%   DurationMS = 2000
%   OffsetMS = 0
%   BufferMS = 1000
%   bandpassFreq = [4 8;8 16]
%   notchFilterFreq = 60
%   resampleFreq = 500
%
% OUTPUT ARGS:
%   phase- (Events,Bands,Time)
%   amp- (Events,Bands,Time)
%   eeg- (Events,Time) (unfiltered)

if ~exist('notchFilterFreq','var') || isempty(notchFilterFreq)
    notchFreqRange = [];
else
    notchFreqRange = notchFilterFreq + [-1 1];
end
if ~exist('resampleFreq','var') || isempty(resampleFreq)
    % resample to first event's sampling rate
    [resampleFreq] = GetRateAndFormat(events(1));
end

% convert the durations to samples
buffer = fix((BufferMS)*resampleFreq/1000);

% load the eeg
eeg = gete_ms(chan,events,DurationMS+(2*BufferMS),OffsetMS-BufferMS,0,...
              notchFreqRange,'stop',2,resampleFreq);

nBand = size(bandpassFreq,1);
sz = [size(eeg,1), nBand, size(eeg,2)-2*buffer];
phase = zeros(sz);
amp = zeros(sz);

for bandNum = 1:nBand
    eegFilt = buttfilt(eeg,bandpassFreq(bandNum,:),resampleFreq,'bandpass',2);
    h = hilbert(eegFilt')'; %hilbert only goes across columns, unfortunately...
    h = h(:,buffer+1:end-buffer); %remove the buffering
    
    phase(:,bandNum,:) = angle(h);
    amp(:,bandNum,:) = abs(h);
end
eeg = eeg(:,buffer+1:end-buffer);
