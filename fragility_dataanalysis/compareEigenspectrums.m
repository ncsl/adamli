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
finalRowDataDir = './adj_mats_win500_step500_freq1000/R_finaldata_radius1.5/';
finalColDataDir = './adj_mats_win500_step500_freq1000/C_finaldata_radius1.5/';

%% Output Spectral Map Per Patient
for iPat=1:length(patients) % loop through each patient
    % load in the fragility data for row and column
    patient = patients{iPat};
    
    patRowFragilityDir = fullfile(finalRowDataDir, strcat(patient, 'final_data.mat'));
    finalRowData = load(patRowFragilityDir);
    rowFragility = finalRowData.fragility_rankings; % load in fragility matrix
    patColFragilityDir = fullfile(finalColDataDir, strcat(patient, 'final_data.mat'));
    finalColData = load(patColFragilityDir);
    colFragility = finalColData.fragility_rankings; % load in fragility matrix
    
    % PLOT FRAGILITY METRIC VS SIGNIFICANT FREQ BANDS
    figure;
    plot(rowFragility(:), colFragility(:), 'ko')
    hold on;
    title(['Row and Column Fragility For ', patient]);
    xlabel('Row Pert. Fragility');
    ylabel('Col Pert. Fragility');
    
    currfig = gcf;
    currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
    currfig.Position = [1986           1        1535        1121];
    
    %- save the figure
    print(fullfile(figDir, strcat(patient, 'rowvscolfragility')), '-dpng', '-r0')
end