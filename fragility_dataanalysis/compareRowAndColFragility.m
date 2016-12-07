%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       ex: compareRowAndColFragility
% function: compareRowAndColFragility()
%
%-----------------------------------------------------------------------------------------
%
% Description:  For a list of patients, analyzes the fragility metric
% derived from the row and column perturbations. 
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
close all;
clear all;

%% Initialization
% initialize variables
patients = {,...
%     'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1' 'pt2sz3' 'pt2sz4', ...
%     'pt3sz2' 'pt3sz4', ...
%     'pt1aslp1', 'pt1aslp2', ...
%     'pt1aw1', 'pt1aw2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', 'pt2aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
    'pt8sz1' 'pt8sz2' 'pt8sz3',...
    'pt10sz1' 'pt10sz2' 'pt10sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt14sz1' 'pt14sz2' 'pt14sz3' 'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2' 'pt17sz3',...
%     'JH101sz1' 'JH101sz2' 'JH102sz3' 'JH102sz4',...
% 	'JH102sz1' 'JH102sz2' 'JH102sz3' 'JH102sz4' 'JH102sz5' 'JH102sz6',...
% 	'JH103sz1' 'JH102sz2' 'JH102sz3',...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
% 	'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
% 	'JH106sz1' 'JH106sz2' 'JH106sz3' 'JH106sz4' 'JH106sz5' 'JH106sz6',...
% 	'JH107sz1' 'JH107sz2' 'JH107sz3' 'JH107sz4' 'JH107sz5' 'JH107sz6' 'JH107sz7' 'JH107sz8' 'JH107sz8',...
%     'JH102sz1',
%     'JH102sz2', 'JH102sz3', 'JH102sz4', 'JH102sz5', 'JH102sz6',...
    %'EZT030seiz001' ...
%     'EZT030seiz002' 'EZT037seiz001' 'EZT037seiz002',...
% 	'EZT070seiz001' 'EZT070seiz002', ...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
%     'pt1sz2', 'pt1sz3', 'pt2sz1', 'pt2sz3', 'JH105sz1', 'pt7sz19', 'pt7sz21', 'pt7sz22',  ...
%     'EZT005_seiz001', 'EZT005_seiz002', 'EZT007_seiz001', 'EZT007_seiz002', ...
%     'EZT019_seiz001', 'EZT019_seiz002', 'EZT090_seiz002', 'EZT090_seiz003', ...
    };
addpath(genpath('./fragility_library'));

figDir = fullfile('./figures/rowvscol/');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end
finalRowDataDir = './serverdata/adj_mats_win500_step500_freq1000/R_perturbations_radius1.5/';
finalColDataDir = './serverdata/adj_mats_win500_step500_freq1000/C_perturbations_radius1.5/';

% figure variables
FONTSIZE = 18;

regressionFit = cell(length(patients), 3);
regressionFitFile = 'regressionFits.txt';
fid = fopen(fullfile(figDir, regressionFitFile), 'w');

%% Output Spectral Map Per Patient
for iPat=1:length(patients) % loop through each patient
    % load in the fragility data for row and column
    patient = patients{iPat};
    patRowFragilityDir = fullfile(finalRowDataDir, strcat(patient, '_Rperturbation_leastsquares.mat'));
    finalRowData = load(patRowFragilityDir);
    rowFragility = finalRowData.perturbation_struct.fragility_rankings; % load in fragility matrix
    
    patColFragilityDir = fullfile(finalColDataDir, strcat(patient,  '_Cperturbation_leastsquares.mat'));
    finalColData = load(patColFragilityDir);
    colFragility = finalColData.perturbation_struct.fragility_rankings; % load in fragility matrix
    
    % compute linear regression and save it
    X = [ones(length(rowFragility(:)), 1) rowFragility(:)];
    regressCoeff = X\colFragility(:);
    yCalc = regressCoeff(1) + regressCoeff(2) * rowFragility(:);
    rsq = 1 - sum((colFragility(:) - yCalc).^2) / ...
        sum((colFragility(:) - mean(colFragility(:))).^2);
    fprintf(fid, [patient, ',', num2str(regressCoeff(2)), ',', num2str(rsq), '\n']);
    
    
    % PLOT FRAGILITY METRIC VS SIGNIFICANT FREQ BANDS
    figure;
    plot(rowFragility(:), colFragility(:), 'ko'); hold on;
    axes = gca;
    titleStr = ['Row and Column Fragility For ', patient];
    ylabel = 'Col Pert. Fragility';
    xlabel = 'Row Pert. Fragility';
    labelBasicAxes(axes, titleStr, ylabel, xlabel, FONTSIZE);
    xlim([0, 1]);
    ylim([0, 1]);
    
    
    currfig = gcf;
    currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
    currfig.Position = [1986           1        1535        1121];
    
    %- save the figure
    print(fullfile(figDir, strcat(patient, 'rowvscolfragility')), '-dpng', '-r0')
end