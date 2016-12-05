%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       ex: analyzeECG
% function: analyzeECG()
%
%-----------------------------------------------------------------------------------------
%
% Description:  For a list of patients, analyzes the ECG signals of a
% patient
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
    'pt1aw1', 'pt1aw2', ...
    'pt1aslp1', 'pt1aslp2', ...
    'pt2aw1', 'pt2aw2', ...
    'pt2aslp1', ...
    'pt2aslp2', ...
    'pt3aw1', ...
    'pt3aslp1', 'pt3aslp2', ...
    'pt1sz2', 'pt1sz3', 'pt1sz4',...
    'pt2sz1' 'pt2sz3' 'pt2sz4', ...
    'pt3sz2' 'pt3sz4', ...
    'pt8sz1' 'pt8sz2' 'pt8sz3',...
    'pt10sz1' 'pt10sz2' 'pt10sz3', ...
};

addpath(genpath('./fragility_library/'));

figDir = fullfile('./figures/ecg/');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end
adjMat = './adj_mats_win500_step500_freq1000/';

dataDir = './data/';
winSize = 500;            % 500 milliseconds
stepSize = 500; 
frequency_sampling = 1000; % in Hz
IS_SERVER = 0;
ECG = 1;
FONTSIZE = 18;

for iPat=1:length(patients)
    close all
    patient = patients{iPat};
    setupScripts; % run scripts to get all data
    index = strfind(labels, 'EKG');
    index = find(not(cellfun('isempty', index)));
    
    % extract the ekg data
    ekgdata = eeg(index,:); 
    if seizureStart == size(eeg,2)
        timeRange = [size(eeg,2) - 20000:size(eeg,2)];
    else
        timeRange = [seizureStart-10000:seizureStart+10000];
    end
    % plotting of ekg data
    figure;
    for i=1:size(ekgdata,1)
        subplot(size(ekgdata,1), 1, i);
        plot(timeRange-seizureStart, ekgdata(i, timeRange), 'k'); hold on;
        axes = gca;
        titleStr = ['EKG Data Trace for ', patient, ' Locked To Seizure'];
        ylabelStr = 'EKG Voltage (mV)';
        xlabelStr = 'Time (msec)';
        labelBasicAxes(axes, titleStr, ylabelStr, xlabelStr, FONTSIZE);
    end
    filename = strcat(patient, '_ekgtraces');
    
    currfig = gcf;
    currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
    currfig.Position = [1986           1        1535        1121]; %workstation
    
    print(fullfile(figDir, filename), '-dpng', '-r0');
end
