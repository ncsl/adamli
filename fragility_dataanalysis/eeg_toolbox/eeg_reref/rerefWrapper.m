function [stemsChecked, stemsRerefed] = rerefWrapper(subj,eegDir)
% Function rerefWrapper(subj,eegDir)
%
%   Description: This function implements both bipolar and average
%   re-referencing schemes. It gets gridLayout and
%   missingElecs from the electrodes.m file to be created in the patient's docs directory.
%
%   Input:
%         --subj=subject name (ex. 'NIH001')
%         --eegDir=directory where data is held
%                  (ex. '/Users/damerasr/Sri/data/eeg/')
%   Output:
%         -- number of EEG stems checked, and number of those rereferenced
%

% sets up input and output directories
subjDir    = fullfile(eegDir,subj); % where subject data is located
taldir     = fullfile(subjDir,'tal'); % where tailrach info is located
noRerefDir = fullfile(subjDir,'eeg.noreref'); % where no-reref data is located
rerefDir   = fullfile(subjDir,'eeg.reref'); % where reref data will be saved to

%if the reref direcetory does not exist it is now made
if ~exist(rerefDir,'dir')
    mkdir(rerefDir)
end


% gets unique fileStems from the files in the no-reref direcetory (must have channel .001 for this to work)
allFiles      = dir(noRerefDir);
allFilesNames = getStructField(allFiles,'name');
idx           = strfind(allFilesNames,'.001');   % only look for files ending in .001
idx           = ~cellfun(@isempty,idx);
allFilesNames = allFilesNames(idx);
fileStems     = unique(cellfun(@removeChanTag,allFilesNames,'UniformOutput',false));

allFiles2     = dir(rerefDir);
allFilesNames2 = getStructField(allFiles2,'name');

rerefCount = 0;

% for each fileStem run bipolar and 'laplacian' re-referencing schemes and save out the data
for i = 1:length(fileStems)
    eegFilestem = fileStems{i};
    idx2 = strfind(allFilesNames2,eegFilestem);
    idx2 = ~cellfun(@isempty,idx2);
    if ~sum(idx2) % if filestem hasn't already been rereferenced then do it now
        % bipolar rereferencing
        grids = reref_Bipolarity(subjDir,eegFilestem);
            
        % global weighted average rerefrencing
        fileroots = {fullfile(subjDir,'eeg.noreref',eegFilestem)};
        reref(fileroots,grids,rerefDir,taldir);
        
        rerefCount = rerefCount + 1;
    end
end


stemsChecked = length(fileStems);
stemsRerefed = rerefCount;