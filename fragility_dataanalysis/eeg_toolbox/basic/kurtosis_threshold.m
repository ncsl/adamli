function[good_events] = kurtosis_threshold(kthresh,data,chan,offset,duration,filtfreq)
%KURTOSIS_THRESHOLD  detect which events do not contain epileptic spikes
%                    using kurtosis thresholding
%
% Usage: 
% good_events = kurtosis_threshold(kthresh,data,[chan],[offset_ms],[duration_ms],[filtfreq])
%
% good_events: events satisfying kurtosis <= kthresh
%     kthresh: kurtosis threshold used for excluding events
%        data: either a matrix of EEG data (nEvents X nSamples) or an array
%              of events structs
%        chan: channel to obtain EEG data from.  this field is ignored if
%              "data" is not an array of event structs.
%      offset: EEG offset (ms) to use relative to each event.  this field
%              is ignored if "data" is not an array of event structs.
%    duration: duration (ms) of each event.  this field is ignored if
%              "data" is not an array of event structs.
%    filtfreq: frequencies to filter out of EEG data prior to kurtosis
%              thresholding.  a first order butterworth stop filter is used
%              (other options currently not supported).  this field is
%              ignored if "data" is not an array of event structs.
%
% 6-27-10  jrm  wrote it.

if isstruct(data)
    %samplerate = eegparams('samplerate',fileparts(data(1).eegfile));
    eeg = gete_ms(chan,data,duration,offset,0,filtfreq,'stop',1);
end

% detect which events exceed kurtosis threshold (kthresh)
if isempty(kthresh)
    good_events = true(size(eeg,1),1);
else    
    k = kurtosis(eeg');
    good_events = k <= kthresh;    
end