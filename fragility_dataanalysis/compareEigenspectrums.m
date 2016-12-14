%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       ex: compareEigenspectrums
% function: compareEigenspectrums()
%
%-----------------------------------------------------------------------------------------
%
% Description:  For a list of patients, analyzes the eigenspectrum of
% before and after the perturbation structure 
%
%-----------------------------------------------------------------------------------------
%   
%   Input:   
% 
%   Output: 
%            
%                          
%-----------------------------------------------------------------------------------------
% Author: Adam Li
%
% Ver.: 1.0 - Date: 11/23/2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization
% initialize variables
patients = {,...
    'pt1sz2', 'pt1sz3', 'pt1sz4',...
    'pt2sz1' 'pt2sz3' 'pt2sz4', ...
    'pt3sz2' 'pt3sz4', ...
    'pt8sz1' 'pt8sz2' 'pt8sz3',...
    'pt10sz1' 'pt10sz2' 'pt10sz3', ...

    };

figDir = fullfile('./figures/eigenspectrums/');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

channel = 1;

adjMat = './serverdata/adj_mats_win500_step500_freq1000/';
finalRowDataDir = './serverdata/adj_mats_win500_step500_freq1000/R_perturbations_radius1.5/';
finalColDataDir = './serverdata/adj_mats_win500_step500_freq1000/C_perturbations_radius1.5/';

%% Output Spectral Map Per Patient
for iPat=1:length(patients) % loop through each patient
    % load in the fragility data for row and column
    patient = patients{iPat};
    
    % get the perturbation structures
    patRowFragilityDir = fullfile(finalRowDataDir, strcat(patient, 'final_data.mat'));
    finalRowData = load(patRowFragilityDir);
    rowFragility = finalRowData.fragility_rankings; % load in fragility matrix
    rowPerturbations = finalRowData.metadata.del_table;
    
    patColFragilityDir = fullfile(finalColDataDir, strcat(patient, 'final_data.mat'));
    finalColData = load(patColFragilityDir);
    colFragility = finalColData.fragility_rankings; % load in fragility matrix
    colPerturbations = finalColData.metadata.del_table;
    
    % get the adjacency mat strcutures
    adjMats = fullfile(adjMat);
    
%     num_chans = size(rowFragility,1);
%     rowPerturbations = finalRowData.metadata.del_table{:,end};
%     colPerturbations = finalColData.metadata.del_table{:,end};
    
    
end