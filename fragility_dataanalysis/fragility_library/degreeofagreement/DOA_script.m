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
%   be considered part of the EEZ. Optional parameter. Default value is
%   0.70.
%   
% Output: [function]
%   DOA: (#CEZ intersect EEZ / #CEZ) / (#NOTCEZ intersect EEZ / #NOTCEZ)
%   Value between -1 and 1, Computes how well CEZ and EEZ match. 
%   < 0 indicates poor match.
% 
% Author: Kriti Jindal, NCSL 
% Last Updated: 02.23.17
%   
% #########################################################################

% function is in following format: 
% function[ D ] = DOA( EpiMap, EpiMapStruct, CEZ, ALL, clinicalStruct, threshold )
% where inputs are as described above. 

% List of inputs:
% --EpiMap = 'fake_data.EpiMap';
% EpiMapStruct = 'fake_data.mat';-- 
% CEZ = 'adjmat_struct.ezone_labels';
% ALL = 'adjmat_struct.all_labels';
% clinicalStruct = 'pt1sz2_adjmats_leastsquares.mat';
% threshold = 0.70; note threshold is optional 

% create struct with randomly simulated values from 0-1 for each electrode
% in the clinical ezone labels. 

load('pt1sz2_adjmats_leastsquares.mat');
k = adjmat_struct.ezone_labels;
num_labels = length(k);
v = rand(num_labels, 1);

EpiMap = containers.Map(k, v);

EpiMap_struct = struct('EpiMap_field', EpiMap);

% with default threshold
DOA_threshold_default = DOA('EpiMap_struct.EpiMap_field', 'EpiMap_struct', 'adjmat_struct.ezone_labels', 'adjmat_struct.all_labels', 'pt1sz2_adjmats_leastsquares.mat', 0.70);

% with 0.80 threshold 
DOA_threshold_default = DOA('EpiMap_struct.EpiMap_field', 'EpiMap_struct', 'adjmat_struct.ezone_labels', 'adjmat_struct.all_labels', 'pt1sz2_adjmats_leastsquares.mat', 0.80);

% with 0.90 threshold 
DOA_threshold_ninety = DOA('EpiMap_struct.EpiMap_field', 'EpiMap_struct', 'adjmat_struct.ezone_labels', 'adjmat_struct.all_labels', 'pt1sz2_adjmats_leastsquares.mat', 0.90);

% with 0.95 threshold
DOA_threshold_ninetyfive = DOA('EpiMap_struct.EpiMap_field', 'EpiMap_struct', 'adjmat_struct.ezone_labels', 'adjmat_struct.all_labels', 'pt1sz2_adjmats_leastsquares.mat', 0.95);

%% 
