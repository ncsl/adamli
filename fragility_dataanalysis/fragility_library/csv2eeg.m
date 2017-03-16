%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: csv2eeg
% DESCRIPTION: Used to extract the eeg data from the csv files of a
% specified time frame.
%
% INPUT:
% - pathval = the path to the directory of the csv file
% - filename = the filename of the csv file
% - num_values = the number of rows to grab from the csv file
% - num_channels = the number of channels/columns in the csv file
% OUTPUT:
% - We = the synaptic connectivity matrix for the excitatory network
% - Wi = the synaptic connectivity matrix for the inhibitory network
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function eeg = csv2eeg(pathval, filename, num_values, num_channels)
    eeg_filename = sprintf('%s/%s', pathval, filename);
    if (isempty(filename) || ~ischar(filename) || ~exist(eeg_filename,'file'))
        error('Error: Could not open %s', eeg_filename);
    end

    % check if the file is corrupted and extract the length of the file (in number of bytes)
%     eeg_file = dlmread(eeg_filename, ',',[0 0 (num_values-1) (num_channels-1)]);
    eeg_file = dlmread(eeg_filename, ',');

    file_length = length(eeg_file);
    if (file_length == 0)
        error('Error: %s missing eeg data', eeg_filename);
    end
    
    % csv file is organized with channels in columns, so take the transpose.
    eeg = eeg_file';
end