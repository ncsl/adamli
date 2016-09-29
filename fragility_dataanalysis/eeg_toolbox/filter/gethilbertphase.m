function [phase,amp,eeg] = gethilbertphase(chan,events,DurationMS,OffsetMS,BufferMS,bandpassFreq,notchFilterFreq,resampleFreq)
%GETHILBERTPHASE - uses a hilbert transformation to get the instantaneous phase
%in a particular bandpassed frequency band.
%
% FUNCTION: 
% [phase,amp,eeg] = gethilbertphase(chan,events,DurationMS,OffsetMS,BufferMS,bandpassFreq,notchFilterFreq,resampleFreq)
%
% INPUT ARGs:
%   chan = 2
%   events = events
%   DurationMS = 2000
%   OffsetMS = 0
%   BufferMS = 1000
%   bandpassFreq = [4 8]
%   notchFilterFreq = 60
%   resampleFreq = 500
%
% OUTPUT ARGS:
%   phase- (Events,Time)
%   amp- (Events,Time)
%   eeg- (Events,Time) (unfiltered)

if ~exist('notchFilterFreq','var')
    notchFilterFreq = [];
end
if ~exist('resampleFreq','var')
    resampleFreq = [];
end

if ~isvector(bandpassFreq)
    error('EEGTOOLBOX:GETHILBERTPHASE:MULTIBAND', ...
          'GETHILBERTPHASE can only handle one band at a time. Please call GETHILBERTPHASE2 for multiple bands');
end
if iscolumn(bandpassFreq)
    bandpassFreq = bandpassFreq';
end

[phase,amp,eeg] = gethilbertphase2(chan,events,DurationMS,OffsetMS,BufferMS,bandpassFreq,notchFilterFreq,resampleFreq);
phase = squeeze(phase);
amp = squeeze(amp);