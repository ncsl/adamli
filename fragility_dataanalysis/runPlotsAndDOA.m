% function runPlotsAndDOA(frequency_sampling, winSize, stepSize, radius)
% settings to run
patients = {,...,
%      'pt1aw1', 'pt1aw2', ...
%     'pt1aslp1', 'pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', ...
%     'pt2aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
%     'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1' 'pt2sz3' 'pt2sz4', ...
%     'pt3sz2' 'pt3sz4', ...
%     'pt6sz3', 'pt6sz4', 'pt6sz5',...
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1' 'pt10sz2' 'pt10sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
    'pt14sz1' 'pt14sz2' 'pt14sz3' 'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
    'pt16sz1' 'pt16sz2' 'pt16sz3',...
    'pt17sz1' 'pt17sz2',...
%     'JH101sz1' 'JH101sz2' 'JH102sz3' 'JH102sz4',...
% 	'JH102sz1' 'JH102sz2' 'JH102sz3' 'JH102sz4' 'JH102sz5' 'JH102sz6',...
% 	'JH103sz1' 'JH102sz2' 'JH102sz3',...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
% 	'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
% 	'JH106sz1' 'JH106sz2' 'JH106sz3' 'JH106sz4' 'JH106sz5' 'JH106sz6',...
% 	'JH107sz1' 'JH107sz2' 'JH107sz3' 'JH107sz4' 'JH107sz5' 'JH107sz6' 'JH107sz7' 'JH107sz8' 'JH107sz8',...
%    'JH108sz1', 'JH108sz2', 'JH108sz3', 'JH108sz4', 'JH108sz5', 'JH108sz6', 'JH108sz7',...
%     'EZT030seiz001', 'EZT030seiz002', 
%       'EZT037seiz001', 'EZT037seiz002',...
%     'EZT045seiz001', 'EZT045seiz002',...
% 	'EZT070seiz001', 'EZT070seiz002', 'EZT005seiz001', 'EZT005seiz002', 'EZT007seiz001', 'EZT007seiz002', ...
%     'EZT019seiz001', 'EZT019seiz002',
% 'EZT090seiz002', 'EZT090seiz003' ...
    };

perturbationTypes = ['R', 'C'];
w_space = linspace(-1, 1, 101);
threshold = 0.8;          % threshold on fragility metric

radius = 1.5;             % spectral radius
winSize = 500;            % 500 milliseconds
stepSize = 500; 
frequency_sampling = 1000; % in Hz
IS_SERVER = 0;
timeRange = [60 0];
figDir = './figures/';

% add libraries of functions
addpath(genpath('./fragility_library/'));
addpath(genpath('/Users/adam2392/Dropbox/eeg_toolbox'));
addpath(genpath('/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/eeg_toolbox/'));

%%- Begin Loop Through Different Patients Here
for p=1:length(patients)
    patient = patients{p};
   
    setupScripts;
    adjMat = './serverdata/adj_mats_win';       % get the new data place
    
    %%- Extract an example
    finalDataDir = fullfile(strcat(adjMat, num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), strcat('R', '_perturbations', ...
            '_radius', num2str(radius)));
    try
        final_data = load(fullfile(finalDataDir, strcat(patient, ...
            '_', 'R', 'perturbation_', lower(TYPE_CONNECTIVITY), '.mat')));
        final_data = final_data.perturbation_struct;
    catch e
        disp(e)
        final_data = load(fullfile(finalDataDir, strcat(patient, ...
            '_', 'R', 'perturbation_', lower(TYPE_CONNECTIVITY), ...
            '_radius', num2str(radius), '.mat')));
        final_data = final_data.perturbation_struct;
    end
    % set data to local variables
    minPerturb_time_chan = final_data.minNormPertMat;
    fragility_rankings = final_data.fragility_rankings;
    timePoints = final_data.timePoints;
    info = final_data.info;
    num_channels = size(minPerturb_time_chan,1);
    
    %%- Get Indices for All Clinical Annotations
    included_labels = labels(included_channels);
    ezone_indices = findElectrodeIndices(ezone_labels, included_labels);
    earlyspread_indices = findElectrodeIndices(earlyspread_labels, included_labels);
    latespread_indices = findElectrodeIndices(latespread_labels, included_labels);

    allYTicks = 1:num_channels; 
    y_indices = setdiff(allYTicks, [ezone_indices; earlyspread_indices]);
    if sum(latespread_indices > 0)
        latespread_indices(latespread_indices ==0) = [];
        y_indices = setdiff(allYTicks, [ezone_indices; earlyspread_indices; latespread_indices]);
    end
    y_ezoneindices = sort(ezone_indices);
    y_earlyspreadindices = sort(earlyspread_indices);
    y_latespreadindices = sort(latespread_indices);

    % create struct for clinical indices
    clinicalIndices.all_indices = y_indices;
    clinicalIndices.ezone_indices = y_ezoneindices;
    clinicalIndices.earlyspread_indices = y_earlyspreadindices;
    clinicalIndices.latespread_indices = y_latespreadindices;
    clinicalIndices.included_labels = included_labels;
    
    %% PLOT PERTURBATION RESULTS
    for j=1:length(perturbationTypes)
        perturbationType = perturbationTypes(j);
        
        %- initialize directories to save things and where to get
        %- perturbation structs
        toSaveFinalDataDir = fullfile(strcat(adjMat, num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), strcat(perturbationType, '_perturbations', ...
            '_radius', num2str(radius)))
        toSaveFigDir = fullfile(figDir, perturbationType, strcat(patient, '_win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)))
        if ~exist(toSaveFigDir, 'dir')
            mkdir(toSaveFigDir);
        end
        toSaveWeightsDir = fullfile(figDir, strcat(perturbationType, '_electrode_weights'), strcat(patient, num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)))
        if ~exist(toSaveWeightsDir, 'dir')
            mkdir(toSaveWeightsDir);
        end
           
         %%- Extract an example
        finalDataDir = toSaveFinalDataDir;
        try
            final_data = load(fullfile(finalDataDir, strcat(patient, ...
                '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), '.mat')));
            final_data = final_data.perturbation_struct;
        catch e
            disp(e)
            final_data = load(fullfile(finalDataDir, strcat(patient, ...
                '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), ...
                '_radius', num2str(radius), '.mat')));
            final_data = final_data.perturbation_struct;
        end
        % set data to local variables
        minPerturb_time_chan = final_data.minNormPertMat;
        fragility_rankings = final_data.fragility_rankings;
        info = final_data.info;
        
        %% 1: Extract Processed Data and Begin Plotting and Save in finalDataDir
        %%- initialize plotting args
        FONTSIZE = 20;
        PLOTARGS = struct();
        PLOTARGS.SAVEFIG = 1;
        PLOTARGS.toSaveFigFile = fullfile(toSaveFigDir, strcat(patient, '_minPerturbation_alldata'));
        PLOTARGS.YAXFontSize = 9;
        PLOTARGS.FONTSIZE = FONTSIZE;
        PLOTARGS.xlabelStr = 'Time (sec)';
        PLOTARGS.colorbarStr = 'Minimum 2-Induced Norm Perturbation';
        PLOTARGS.ylabelStr = 'Electrode Channels';
        PLOTARGS.xTickStep = 10*winSize/stepSize;
        PLOTARGS.titleStr = {['Minimum Norm Perturbation (', patient, ')'], ...
            [perturbationType, ' perturbation: ', ' Time Locked to Seizure']};
        seizureStart = info.seizure_start;
        seizureEnd = info.seizure_end;
        if seizureStart == size(eeg,2)
            timeStart = 1;
            timeEnd = timePoints(size(minPerturb_time_chan,2),1) / frequency_sampling;
        else
            % find index of seizureStart
            timeIndex = find(seizureStart<timePoints(:,2),1) - 1;
            timeStart = timeIndex - 60 - timeIndex; 
            timeEnd = timeIndex - timeIndex;
            
            seizureIndex = timeIndex;
            seizureEndIndex = find(seizureEnd < timePoints(:,2),1) + 1;
            seizureTime = timePoints(find(seizureStart<timePoints(:,2),1) - 1) / frequency_sampling;
            timeStart = 1;
            timeEnd = timePoints(size(minPerturb_time_chan,2),1) / frequency_sampling;
            PLOTARGS.seizureIndex = seizureIndex;
            PLOTARGS.seizureEnd = seizureEndIndex;
%             minPerturb_time_chan = minPerturb_time_chan(:, timeIndex-60:timeIndex);
%             fragility_rankings = fragility_rankings(:, timeIndex-60:timeIndex);
        end
        
        %% 2. Plot Min 2-Induced Norm Perturbation and Fragility Ranking
        plotMinimumPerturbation(minPerturb_time_chan, clinicalIndices, timeStart, timeEnd, PLOTARGS);
        
        PLOTARGS.toSaveFigFile = fullfile(toSaveFigDir, strcat(patient, '_fragilityMetric_alldata'));
        PLOTARGS.colorbarStr = 'Fragility Metric';
        PLOTARGS.titleStr = {['Fragility Metric (', patient, ')'], ...
            [perturbationType, ' perturbation: ', ' Time Locked to Seizure']};
        plotFragilityMetric(fragility_rankings, clinicalIndices, timeStart, timeEnd, PLOTARGS);
        
        close all
%         analyzePerturbations(patient_id, seizure_id, plot_args, clinicalLabels);
    end
end