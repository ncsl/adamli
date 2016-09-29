function touchAnnFiles(sessionDir,numBlocks,numTrials)
%This function is used after PennTotalRecall to touch the files that have
%no annotations.
%INPUT:
% sessionDir = the directory of the session where the annotation files are
% numBlocks = total number of blocks
% numTrials = number of trials in each block


%%- JW: is this directory change really required?  If so, should set back to pwd after... let just try cutting tho.
startDir = pwd;
if exist(sessionDir,'dir')
    cd(sessionDir);
else
    error('No such directory.');
end

for currentBlock=0:numBlocks-1
    for currentTrial=0:numTrials-1
        currentFile = sprintf('%d_%d.ann',currentBlock,currentTrial);
        currentFile = [sessionDir '/' currentFile]; 
        if ~exist(currentFile,'file')
            disp(['Making file: ' currentFile]);
            unix(sprintf('touch %s',currentFile));
        end
    end
end

chdir(startDir)        