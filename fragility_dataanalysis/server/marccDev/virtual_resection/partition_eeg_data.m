%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% m-file: partition_eeg_data.m
%
% Description: This function removes certain number of EZ channels from the
% raw data matrix and passes it back
%
% Input:
% 1. raw_eeg: assumed to be in the form CxT (channels by time)
%
% Author: Adam Li
% Ver.: 1.0 - Date: 09/24/2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [part_eeg, part_chans, chan_to_remove] = partition_eeg_data(raw_eeg, all_chans, ez_chans, num_chans_remove) 
%% Error Checking
% if the number requested to remove is greater then the number of chans in
% EZ set, then display warning message
if num_chans_remove > length(ez_chans)
    num_chans_remove = length(ez_chans);
    warning('Number of channels requested to remove is greater then the number of channels within EZ set!');
end

%% Perform Virtual Resection of Raw Data
indices_to_remove = randsample(length(ez_chans), num_chans_remove);
chan_to_remove = ez_chans(indices_to_remove);

% get the index in all channels cell array 
index_of_chan = find(contains(all_chans, chan_to_remove));

% remove that part of the raw eeg
part_eeg = raw_eeg;
part_eeg(index_of_chan,:) = [];
part_chans = all_chans;
part_chans(index_of_chan) = [];
end