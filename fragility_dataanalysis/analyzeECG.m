%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       ex: analyzeECG
% function: analyzeECG()
%
%-----------------------------------------------------------------------------------------
%
% Description:  For a list of patients, analyzes the ECG signals of a
% patient
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

figDir = fullfile('./figures/ecg/');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end
adjMat = './adj_mats_win500_step500_freq1000/';

dataDir = './data/';
IS_SERVER = 0;
ECG = 1;

for iPat=1:length(patients)
    patient = patients{iPat};
    setupScripts; % run scripts to get all data
    index = strfind(labels, 'EKG');
    index = find(not(cellfun('isempty', index)));
    
    
end
