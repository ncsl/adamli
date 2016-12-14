%% Initialization
% initialize variables
patients = {,...
    'pt1sz2', 'pt1sz3', 'pt1sz4',...
    'pt2sz1' 'pt2sz3' 'pt2sz4', ...
    'pt3sz2' 'pt3sz4', ...
};

dataDir = './serverdata/testing_adj_mats_win500_step500_freq1000/';

for iPat=1:length(patients)
    patient = patients{iPat};
    
    %- load in the min perturbation / fragility data
    rowPertFile = fullfile(dataDir, 'R_perturbations_radius1.5', ...
        strcat(patient, '_Rperturbation_leastsquares_radius1.5.mat'));
    colPertFile = fullfile(dataDir, 'C_perturbations_radius1.5', ...
        strcat(patient, '_Cperturbation_leastsquares_radius1.5.mat'));
    
    rowPert = load(rowPertFile);
    rowPert = rowPert.perturbation_struct;
    
    
    
end