function params = eegparams(field,filepath)
%EEGPARAMS - Get a subject specific eeg parameter from the params.txt file.
% 
% If paramdir is not specified, the function looks in the 'docs/'
% directory for the params.txt file.
%
% The params.txt file can contain many types of parameters and will
% evaluate them as one per line.  These are examples:
%
% Channels 1:64
% samplerate 256
% subj 'BR015'
%
% FUNCTION:
%   p = eegparams(field,paramdir)
%
% INPUT ARGS:
%   field = 'samplerate';        % Field or cell array of fields to retrieve
%   filepath = '~/eeg/012/dat/params.txt';  % Path to parameter file.
%       Alternatively, filepath can be a handle to an open file
%
% OUTPUT ARGS:
%   params- the parameters in a cell array, evaluated with eval()
%

if( ~iscell(field) )
    noCell = true;
    field = {field};
else
    noCell = false;
end

if( ~ischar(filepath) )
    file = filepath; % filepath is actually a file handle
else
    file = fopen(filepath,'rt'); % open the file
end

if( file == -1 )
    fileC = {'',''};
else
    fileC = textscan(file,'%s%s','Delimiter','= \b\t');
    fclose(file);
end

nField = length(field);
params = cell(nField,1);

for i = 1:nField
    ind = find( strcmp(field{i},fileC{1}) );
    
    if( ~isempty( ind ) )
        params{i} = eval(fileC{2}{ind(end)});
    else
        params{i} = [];
    end
end

if( noCell )
    % since input was not cell array, output shouldn't be either
    params = params{1};
end
