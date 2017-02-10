% #########################################################################
% Script for testing function DOA. 
%
% Script Summary: Computes statistic (DOA = Degree of Agreement) indicat-
% ing how well EEZ (from EpiMap) and CEZ (clinical ezone) agree. 
% 
% Inputs: [function]
%   EpiMap: Map with keys as electrode labels and corresponding values from
%   0-1 indicating how likely an electrode is in the ezone 
%   EpiMapStruct: struct with EpiMap in it
%   CEZ: cell with clinically predicted ezone labels 
%   ALL: cell with all electrode labels
%   clinicalStruct: struct with clinical values, with CEZ and ALL values in it 
%   threshold: value from 0 - 1 required for an electrode in the EpiMap to 
%   be considered part of the EEZ
%   
% Output: [function]
%   DOA: (#CEZ intersect EEZ / #CEZ) / (#NOTCEZ intersect EEZ / #NOTCEZ)
%   Value between -1 and 1, Computes how well CEZ and EEZ match. 
%   < 0 indicates poor match.
% 
% Author: Kriti Jindal, NCSL 
% Last Updated: 02.10.17
%   
% #########################################################################

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% GLOBAL VARIABLES FOR TESTING 

EpiMap = 'fake_data.EpiMap';
EpiMapStruct = 'fake_data.mat';
CEZ = 'adjmat_struct.ezone_labels';
ALL = 'adjmat_struct.all_labels';
clinicalStruct = 'pt1sz2_adjmats_leastsquares.mat';
threshold = 0.70;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load in necesssary structs for EpiMap, CEZ and ALL 

load(EpiMapStruct);
load(clinicalStruct);

% seperate EpiMap values and keys 

EpiMap_values = cell2mat(values(EpiMap));
EpiMap_keys = keys(EpiMap);

% saves all labels in EpiMap with > THRESHOLD in vector 'EEZ'

y = 1;
for x = 1:length(EpiMap_values)
    if EpiMap_values(x) > threshold
        EEZ(y) = EpiMap_keys(x);
        y = y + 1;
    end
end

% finds appropriate set intersections to plug into DOA formula 

NotCEZ = setdiff(ALL, CEZ);
CEZ_EEZ = intersect(CEZ, EEZ);
NotCEZ_EEZ = intersect(NotCEZ, EEZ);

term1 = length(CEZ_EEZ) / length(CEZ);
term2 = length(NotCEZ_EEZ) / length(NotCEZ);

D = term1 - term2;

fprintf('The degree of agreement with threshold %.2f is %.5f. \n',threshold, D);
