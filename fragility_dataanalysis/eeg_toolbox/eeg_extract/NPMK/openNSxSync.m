function NSx = openNSxSync(channelToRead)

% openNSxSync
% 
% Opens a synced NSx file and removed the extra bit of data from the file.
%
% This function does not take any inputs.
%
%   Kian Torab
%   Blackrock Microsystems
%   kian@blackrockmicro.com
%
%   Version 1.1.0.0
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Version History
%
% 1.0.0.0: 2012
%   - Initial release.
%
% 1.1.0.0:
%   - Added the ability to read in a single channel only.
%   - Took out the re-aligning segment and assigning it to openNSx.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Opening the NSx file
if exist('channelToRead', 'var')
    channelToRead = ['c:' num2str(channelToRead)];
    NSx = openNSx(channelToRead);
else
    NSx = openNSx;
end

%% Openning Synced files and removing the extra piece of data
if iscell(NSx.Data)
    % Removing the extra bit of empty data
    NSx.Data = NSx.Data{end};
    NSx.MetaTags.Timestamp = NSx.MetaTags.Timestamp(end);
    NSx.MetaTags.DataPoints = NSx.MetaTags.DataPoints(end);
    NSx.MetaTags.DataDurationSec = NSx.MetaTags.DataDurationSec(end);
end

%% If user does not specify an output argument it will automatically create a structure.
outputName = ['NS' NSx.MetaTags.FileExt(4)];
if (nargout == 0),
    assignin('caller', outputName, NSx);
    clear all;
end