function serverSetupAdjComputation(patient, radius, winSize, stepSize)
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

    % apply included channels to eeg and labels
    if ~isempty(included_channels)
        eeg = eeg(included_channels, :);
        labels = labels(included_channels);
    end
    
    %- compute number of windows there are based on length of eeg,
    %- winSize and stepSize
    numWins = size(eeg,2) / stepSize - 1;
    unix('echo "Hi"');
    %% Create Unix Command
    pbsCommand = sprintf('qsub -v numWins=%d,patient=%s,radius=%.1f,winSize=%d,stepSize=%d runConnectivity.pbs',...
                    numWins, patient, radius, winSize, stepSize);
    

    unix(pbsCommand);
end