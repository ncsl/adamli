%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function: comparePerturbationRadius
%
%--------------------------------------------------------------------------
%
% Description:  For a list of patients, analyzes the perturbation radius
%
%--------------------------------------------------------------------------
%   
%   Input:   
% 
%   Output: 
%            
%                          
%--------------------------------------------------------------------------
% Author: Adam Li
%
% Ver.: 1.0 - Date: 12/12/2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialization
% initialize variables
patients = {,...
    'pt1sz2', 'pt1sz3', 'pt1sz4',...
    'pt2sz1' 'pt2sz3' 'pt2sz4', ...
    'pt3sz2' 'pt3sz4', ...
    'pt8sz1' 'pt8sz2' 'pt8sz3',...
    'pt10sz1' 'pt10sz2' 'pt10sz3', ...

    };


figDir = fullfile('./figures/perturbationradius/');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

channel = 1;

adjMat = './serverdata/adj_mats_win500_step500_freq1000/';
finalRowDataDir = './serverdata/adj_mats_win500_step500_freq1000/R_perturbations_radius';
finalColDataDir = './serverdata/adj_mats_win500_step500_freq1000/C_perturbations_radius';
radius = [1.25, 1.5, 1.75];

for iPat=1:length(patients)
    patient = patients{iPat}
    
    rowSorted = cell(3, 1);
    colSorted = cell(3, 1);
    
    for iRad=1:length(radius)
        radii = radius(iRad);
        
        rowDataDir = strcat(finalRowDataDir, num2str(radii), '/');
        colDataDir = strcat(finalColDataDir, num2str(radii), '/');
        try
            rowPertFile = fullfile(rowDataDir, strcat(patient, '_Rperturbation_leastsquares_radius', num2str(radii), '.mat'));
            colPertFile = fullfile(colDataDir, strcat(patient, '_Cperturbation_leastsquares_radius', num2str(radii), '.mat'));
            rowPertStruct = load(rowPertFile);
            colPertStruct = load(colPertFile);
        catch e
            disp(e)
            rowPertFile = fullfile(rowDataDir, strcat(patient, '_Rperturbation_leastsquares.mat'));
            colPertFile = fullfile(colDataDir, strcat(patient, '_Cperturbation_leastsquares.mat'));
            rowPertStruct = load(rowPertFile);
            colPertStruct = load(colPertFile);
        end
            
        rowPertStruct = rowPertStruct.perturbation_struct;
        colPertStruct = colPertStruct.perturbation_struct;
        
        rowPert = squeeze(rowPertStruct.minNormPertMat(:,1));
        colPert = squeeze(colPertStruct.minNormPertMat(:,1));
        
        [rows rowI] = sort(rowPert);
        [cols colI] = sort(colPert);
        
        rowSorted{iRad} = rowI;
        colSorted{iRad} = colI;
        
%         figure;
%         subplot(211);
%         plot(rowI, 'ko'); hold on
%         subplot(212)
%         plot(colI, 'ko'); hold on
    end
    
    testrad1 = rowSorted{1};
    testrad2 = rowSorted{2};
    testrad3 = rowSorted{3};
    for i=1:length(rowI)
        if testrad1(i) ~= testrad2(i)
            testrad1(i)
            testrad2(i)
        end
    end
end

