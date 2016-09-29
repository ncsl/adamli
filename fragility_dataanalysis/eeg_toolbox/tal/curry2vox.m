function []=curry2vox(talPath,curryFile,colOrder)
%
% curry2vox.m
%
% This function takes in the text file created by Curry for
% electrode localization and converts it to a Vox file for
% talairaching.  
%
% The curry file has 6 columns.  Usually, Column 2 is the channel
% name, and column 4 is the original y coordinate for each channel,
% and column 5 is the new y-coordinate, calculated by subtracting the
% original y from 512.  This is necessary because Curry uses a
% different origin.  However, in some cases, the column order is
% different.  So the input 'colOrder' specifies which columns you
% want to extract, in the order of x-, y-, z-.  For example,
% colOrder=[3 5 6] means x data is in column 3, y in column 5 (the
% new y, which is 512-y based on the Curry coordinates), and z is
% in column 6.
% 
% Before running this, remove all header lines from the Curry
% file.  Also remove rows corresponding to Reference or EKG
% channels, and renumber electrode channels accordingly.
%
% Creates VOX_coords.txt in the format used for subsequent
% talairaching.
% 
% Input Args
%
% talPath          - path of tal files for this patient
% curryFile        - The original Curry file
% colOrder         - the order of columns to extract, corresponding
%                    x, y, and z.  colOrder=[3,5,6] means get the 
%                    x data from column 3, y from column 5, z from
%                    column 6.
%
% Output Args
%

inFile=fullfile(talPath,curryFile);
outFile=fullfile(talPath,'VOX_coords.txt');

% Get Curry coordinates
fid=fopen(inFile);
curr=textscan(fid,'%n%s%n%n%n%n');
fclose(fid);

% Make into Vox matrix, converting all numbers to integers and
% replacing original y-coordinate column with new 512-y coordinate
voxCoord=[round(curr{colOrder(1)}) round(curr{colOrder(2)}) round(curr{colOrder(3)})];

% Prefaces each row with the row number, so row number ordering in
% original curry file, if not sequential, does not matter
numEl=size(voxCoord,1);
voxCoord=[[1:numEl]' voxCoord];

% Write vox file
fid=fopen(outFile,'w','l');
fprintf(fid,'%d %d %d %d\n',voxCoord');
fclose(fid);
