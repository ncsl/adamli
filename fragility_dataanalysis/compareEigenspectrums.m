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
%     'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1' 'pt2sz3' 'pt2sz4', ...
%     'pt3sz2' 'pt3sz4', ...
    'pt8sz1' 'pt8sz2' 'pt8sz3',...
    'pt10sz1' 'pt10sz2' 'pt10sz3', ...

    };

figDir = fullfile('./figures/eigenspectrums/');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

channel = 1;

adjMatDir = './serverdata/adj_mats_win500_step500_freq1000/';
finalRowDataDir = './serverdata/adj_mats_win500_step500_freq1000/R_perturbations_radius1.5/';
finalColDataDir = './serverdata/adj_mats_win500_step500_freq1000/C_perturbations_radius1.5/';

%% Output Spectral Map Per Patient
for iPat=1:length(patients) % loop through each patient
    % load in the fragility data for row and column
    patient = patients{iPat};
    
    if ~exist(fullfile(figDir, patient), 'dir')
        mkdir(fullfile(figDir, patient));
    end
    
    % get the perturbation structures
    patRowFragilityDir = fullfile(finalRowDataDir, strcat(patient, '_Rperturbation_leastsquares_radius1.5.mat'));
    finalRowData = load(patRowFragilityDir);
    rowFragility = finalRowData.perturbation_struct.fragility_rankings; % load in fragility matrix
    rowPerturbations = finalRowData.perturbation_struct.info.del_table;
    
    patColFragilityDir = fullfile(finalColDataDir, strcat(patient, '_Cperturbation_leastsquares_radius1.5.mat'));
    finalColData = load(patColFragilityDir);
    colFragility = finalColData.perturbation_struct.fragility_rankings; % load in fragility matrix
    colPerturbations = finalColData.perturbation_struct.info.del_table;
    
    % get the adjacency mat strcutures
    adjMatFile = fullfile(adjMatDir, patient, strcat(patient, '_adjmats_leastsquares.mat'));
    adjMats = load(adjMatFile);
    adjMats = adjMats.adjmat_struct.adjMats;
    
    [T, numChans, ~] = size(adjMats);
    
    channel = 3;
    for i=1:5
        index = i;
        adjMat = squeeze(adjMats(index, :, :));
        evals = eig(adjMat);

        colPerturbation = colPerturbations{channel, index};
        colPertMat = [zeros(channel-1, numChans); colPerturbation'; zeros(numChans-channel, numChans)]';
        colPerturbedMat = adjMat + colPertMat;
        colPertEVals = eig(colPerturbedMat);
        
        rowPerturbation = rowPerturbations{channel, index};
        rowPertMat = [zeros(channel-1, numChans); rowPerturbation; zeros(numChans-channel, numChans)];
        perturbedMat = adjMat + rowPertMat;
        pertEVals = eig(perturbedMat);

%         max(abs(evals))
%         max(abs(pertEVals))
%         max(abs(colPertEVals))

        close all
        figure;
        subplot(311);
        plot(real(evals), imag(evals), 'ko'); hold on;
        plot(real(pertEVals), imag(pertEVals), 'ro');
        plot(real(colPertEVals), imag(colPertEVals), 'go');
        xlabel('Real Part');
        ylabel('Imag Part');
        title(['Eigenspectrum of ', patient, ' channel ', num2str(channel)]);
        legend('Before', 'After Row', 'After Col');
        subplot(312);
        imagesc(colPertMat);
        title('Col Perturbations');
        colorbar();
        subplot(313);
        imagesc(rowPertMat);
        title('Row Perturbations');
        colorbar();
        
        currfig = gcf;
        currfig.PaperPosition = [ -3.7448   -0.3385   15.9896   11.6771];
        
        print(fullfile(figDir, patient, strcat(patient, '_chan', num2str(channel), '_index', num2str(index))), '-dpng', '-r0')
    end
end