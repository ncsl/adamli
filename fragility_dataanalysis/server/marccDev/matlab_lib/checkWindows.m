function [winsToCompute] = checkWindows(fileList, numWins)
% function: checkWindows
% By: Adam Li
% Date: 6/12/17
% Description: Checks the file list of computed windows and compares with
% the correct number of windows needed for this patient.
% 
% Input: 
% - fileList: cell array of all the files in this respective directory.
% Assuming each file name is <patient>_<meta>_<window>.mat
% - numWins: the total number of windows from 1:N that should be inside
% this directory
% Output:
% - vector of windows needed to compute
if nargin==0 % test
    fileList = {'pt1sz2_adj_2.mat', 'pt1sz2_adj_9.mat'};
    numWins = 10;
end
% initialize window list
winList = zeros(numWins, 1);
checkList = zeros(numWins, 1);

% break up file list by delimiter '_'
fileWindows_buff = regexp(fileList, '_', 'split');
for i=1:length(fileList)
    filesplit = fileWindows_buff{i};
    buff = strsplit(filesplit{3}, '.');
    buff_winnum = str2double(buff{1});
    
    %- error displayer
    if buff_winnum > numWins
        fprintf('There was a window computed greater then number of windows!\n');
        fprintf('computed window %d and actual number of windows %d\n', buff_winnum, numWins);
        error('Error in checkWindows!');
    end
    
    %- add index that was computed
    winList(buff_winnum) = 1;
    checkList(buff_winnum) = buff_winnum;
end
winsToCompute = find(winList==0);
end