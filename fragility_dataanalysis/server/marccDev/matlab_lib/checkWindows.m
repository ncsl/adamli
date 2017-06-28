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
    fileList = {'pt1sz2_adj_20.mat', 'UMMC001_sz2_adj_5.mat'};
    numWins = 30;
end
% initialize window list
winList = zeros(numWins, 1);
checkList = zeros(numWins, 1);

% break up file list by delimiter '_'
% fileWindows_buff = regexp(fileList, '_', 'split');
for i=1:length(fileList)
    file = fileList{i};
    buff = strsplit(file, '.');
    buff_winnum = strsplit(buff{1}, '_');
    winnum = str2double(buff_winnum{end});
    
    %- error displayer
    if winnum > numWins
        fprintf('There was a window computed greater then number of windows!\n');
        fprintf('computed window %d and actual number of windows %d\n', winnum, numWins);
        error('Error in checkWindows!');
    end
    
    %- add index that was computed
    winList(winnum) = 1;
    checkList(winnum) = winnum;
end
winsToCompute = find(winList==0);
end