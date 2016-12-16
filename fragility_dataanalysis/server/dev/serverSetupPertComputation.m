function serverSetupPertComputation(patient, radius, winSize, stepSize)
    if nargin == 0 % testing purposes
        patient='EZT007seiz001';
        patient ='pt1sz2';

        % window paramters
        radius = 1.5;
        winSize = 500; % 500 milliseconds
        stepSize = 500; 
        frequency_sampling = 1000; % in Hz
    end

    addpath(genpath('../fragility_library/'));
    addpath(genpath('../eeg_toolbox/'));
    addpath('../');
    perturbationTypes = ['R', 'C'];
    w_space = linspace(-radius, radius, 303);
    IS_SERVER = 1;
    setupScripts;

    %% 0: Extract Vars and Initialize Parameters
    adjDir = toSaveAdjDir;
    
    % get list of mat files
    matFile = fullfile(adjDir, strcat(patient, '_adjmats_', lower(TYPE_CONNECTIVITY), '.mat'));

    % load the adjacency matrix mat file
    data = load(matFile);
    adjmat_struct = data.adjmat_struct;

    % get the number of channels and time points
    numWins = size(adjmat_struct.adjMats, 1);
  
    %% Create Unix Command
    pbsCommand = sprintf('qsub -v numWins=%d,patient=%s,radius=%.1f,winSize=%d,stepSize=%d runPerturbation.pbs',...
                    numWins,patient, radius, winSize, stepSize);
    
    unix(pbsCommand);
end