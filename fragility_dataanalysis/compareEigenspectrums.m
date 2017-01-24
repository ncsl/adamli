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
%     'EZT019_seiz002'...
%     'pt1aw1',...
    'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1' 'pt2sz3' 'pt2sz4', ...
%     'pt3sz2' 'pt3sz4', ...
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1' 'pt10sz2' 'pt10sz3', ...

    };

figDir = fullfile('./figures/eigenspectrums/');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

perturbations = ['C', 'R'];

exChan = 1;

serverDataDir = './serverdata/fixed_adj_mats_win500_step500_freq1000/';
adjMatDir = serverDataDir;
finalRowDataDir = fullfile(serverDataDir, 'R_perturbations_radius1.5/')
finalColDataDir = fullfile(serverDataDir, 'C_perturbations_radius1.5/')

%% Output Spectral Map Per Patient
for iPat=1:length(patients) % loop through each patient
    % load in the fragility data for row and column
    patient = patients{iPat};
    
    finalRowDataDir = fullfile(serverDataDir, patient, 'R_perturbations_radius1.5/_newfixedalg')
    finalColDataDir = fullfile(serverDataDir, patient, 'C_perturbations_radius1.5/_newfixedalg')

    finalRowDataDir = fullfile(serverDataDir, 'R_perturbations_radius1.5/_newfixedalg')
    finalColDataDir = fullfile(serverDataDir, 'C_perturbations_radius1.5/_newfixedalg')

    
    
    if ~exist(fullfile(figDir, patient), 'dir')
        mkdir(fullfile(figDir, patient));
    end
    
    % get the perturbation structures
    patRowFragilityDir = fullfile(finalRowDataDir, strcat(patient, '_Rperturbation_leastsquares_radius1.5.mat'));
    finalRowData = load(patRowFragilityDir);
    rowPerturbations = finalRowData.perturbation_struct.del_table;
    
    patColFragilityDir = fullfile(finalColDataDir, strcat(patient, '_Cperturbation_leastsquares_radius1.5.mat'));
    finalColData = load(patColFragilityDir);
    colPerturbations = finalColData.perturbation_struct.info.del_table;
    
    % get the adjacency mat strcutures
    adjMatFile = fullfile(adjMatDir, patient, strcat(patient, '_adjmats_leastsquares.mat'));
    load(adjMatFile);
    adjMats = adjmat_struct.adjMats;
    
    
    [T, numChans, ~] = size(adjMats);
    
    for iTime=1:5 % loop through time windows of adjMats
        adjMat = squeeze(adjMats(iTime,:,:));
        
        % get the two different min-norm perturbations
        del_col = colPerturbations{exChan, iTime};
        del_row = rowPerturbations{exChan, iTime};
        
        ek = [zeros(exChan-1, 1); 1; zeros(numChans-exChan, 1)];
        
        % create perturbation matrices
        coltemp = del_col'*ek';
        rowtemp = ek*del_row';
        
        evals = eig(adjMat);
        test = adjMat + rowtemp;
        rowPertEVals = eig(test);
         test = adjMat + coltemp;
        colPertEVals = eig(test);
        
        max(abs(colPertEVals))
        max(abs(rowPertEVals))
        
        figure;
        plot(real(evals), imag(evals), 'ko'); hold on;
        plot(real(rowPertEVals), imag(rowPertEVals), 'ro');
        plot(real(colPertEVals), imag(colPertEVals), 'g*');
        xlabel('Real Part');
        ylabel('Imag Part');
        title(['Eigenspectrum of ', patient, ' channel ', num2str(exChan)]);
        legend('Before', 'After Row', 'After Col');
        
        xlim([-0.5 1.6]);
        ylim([-0.85 0.85]);
        
        currfig = gcf;
        currfig.PaperPosition = [ -3.7448   -0.3385   15.9896   11.6771];
        print(fullfile(figDir, patient, strcat(patient, '_chan', num2str(exChan), '_index', num2str(iTime))), '-dpng', '-r0')
    end
    close all
end