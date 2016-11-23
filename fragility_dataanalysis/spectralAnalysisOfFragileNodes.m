%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       ex: spectralAnalysisOfFragileNodes
% function: spectralAnalysisOfFragileNodes()
%
%-----------------------------------------------------------------------------------------
%
% Description:  For a list of patients, analyzes the fragility metric vs.
% 5% significant frequency bands for the FFT spectrum of the original time
% series signal.
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
patients = {...
    'pt1sz2', 'pt1sz3', 'pt1sz4',...
    'pt2sz1' 'pt2sz3' 'pt2sz4',...
%     'pt3sz2' 'pt3sz4', ...
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1' 'pt10sz2' 'pt10sz3', ...
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

perturbationType = 'R';
threshold = 0.6;
timeRange = [60 0];
winSize = 500;
stepSize = 500;
freq = 1000;

% initialize directories
figDir = fullfile('./figures/spectralAnalysis/', perturbationType);
if ~exist(figDir, 'dir')
    mkdir(figDir);
end
dataDir = fullfile('./data/');
finalDataDir = './adj_mats_win500_step500_freq1000/R_finaldata_radius1.5/';

%% Output Spectral Map Per Patient
for iPat=1:length(patients) % loop through each patient
    % load in the fragility data
    patient = patients{iPat};
    patFragilityDir = fullfile(finalDataDir, strcat(patient, 'final_data.mat'));
    finalData = load(patFragilityDir);
    fragility = finalData.fragility_rankings; % load in fragility matrix
    
    % binarize the fragility matrix and find high fragility electrodes
    fragility(fragility>threshold) = 1;
    fragility(fragility<=threshold) = 0;
    [highFragilityRow, highFragilityCol] = find(fragility > 0);
    highFragilityIndices = find(fragility>0);
    
    % transform column (time) indices into actual times for indicing the
    % raw data
    highFragilityCol = highFragilityCol*winSize - (winSize-stepSize)*(highFragilityCol-1);
    
    % vectorized original fragility metric
    originalFragilityMetric = squeeze(finalData.fragility_rankings(highFragilityIndices));
    
    % load in the raw data
    patDataDir = fullfile(dataDir, patient, patient);
    data = load(patDataDir);
    eeg = data.data;
    seiz_start = data.seiz_start_mark;
    
    % only get the relevant time Window EEG 
    eeg = eeg(:, seiz_start-timeRange(1)*freq+1 : seiz_start-timeRange(2)*freq);
    
    % go through each channel/time window and access the significant freqs
    significant_freqs = cell(length(highFragilityRow),1);
    for iChan=1:length(highFragilityRow) % loop through each high fragility channel
        % access the channel's time/freq maximal point
        tempeeg = eeg(highFragilityRow(iChan), highFragilityCol+1 - winSize:highFragilityCol);
        freqs = abs(fft(tempeeg)); % perform the FFT on signal
        
        significant_freqs{iChan} = find(abs(freqs) > mean(abs(freqs)) + 3*std(abs(freqs)));
    end
    
    % PLOT FRAGILITY METRIC VS SIGNIFICANT FREQ BANDS
    figure;
    for iChan=1:length(significant_freqs)
        plot(repmat(originalFragilityMetric(iChan), length(significant_freqs{iChan})), significant_freqs{iChan}, 'ko')
        hold on;
    end
    title(['Fragility Metric vs. Significant Frequency Bands For ', patient]);
    xlabel('Fragility Metric');
    ylabel('Significant Freq. Bands');
    
    currfig = gcf;
    currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
    currfig.Position = [1986           1        1535        1121];
    
    %- save the figure
    print(fullfile(figDir, strcat(patient, 'FragilityVsFreq')), '-dpng', '-r0')
end

