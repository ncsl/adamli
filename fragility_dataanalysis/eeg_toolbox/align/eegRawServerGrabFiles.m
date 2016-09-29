function eegRawServerGrabFiles( subj, rootEEGdir, rawFilePrefix, rawFileList, typeListOptional )
% function eegRawServerGrabFiles( subj, rootEEGdir, rawFilePrefix, rawFileList )
%   NOTE: ONLY WORKS IF YOU HAVE ACCESS TO '/Volumes/shares/EEG/LTVEEG_DATA/nkt/EEG2100'... confirm this first!
%
%
%   INPUTS:
%      -subject 'NIH024'
%      -rootEEGdir '/Volumes/Shares/FRNU/dataWorking/eeg'
%      -rawFileNaPrefix -- 'DA8662'
%      -rawFileNameList -- cell array of strings that complete the prefix:  e.g.  {?JD?,?JS?,?JW?} will grab DA8662JD.21E DA8662JD.EEG DA8662JD.LOG,  and DA8662JS.21E...
%      -typeListOptional -- optional cell array of strings defining the file types to grab. If not passed , grab {'21E','EEG','LOG'}
%
%
%   OUTPUTS:
%      - copies .21E, .EEG, and .LOG to the subjects raw directory
%
%
%   example call:   eegRawServerGrabFiles('NIH025', '/Volumes/Shares/FRNU/dataWorking/eeg', 'DA8662', {'GH','GI','GY','H2','H6'}, {'21E','EEG','LOG'});
%


if nargin==5 && length(typeListOptional)>0,
    typeList = typeListOptional;
else
    typeList = {'21E','EEG','LOG'};  %- the file types that will be copied.  Log is only used for stimulation, but easier to get it for all of them
end


% sometimes this code hangs/crashes, probably due to slow interaction with the server.  Forcing all files closed seems to help
fclose all;

%%- directory should be the same on all computers in Kareem's lab...
%nktdir = '/Volumes/Shares/EEG/LTVEEG_DATA/Archive2/NKT/EEG2100'; %- use this for old archived files
nktdir = '/Volumes/Shares-1/EEG/LTVEEG_DATA/nkt/EEG2100';
if ~exist(nktdir,'dir'),  error(' ERROR: cant see EEG folder on server. Might need different login credentials (ask KZ or JW) '); end


%%- destination directory: in subjects/raw/_grabbed
dest = sprintf('%s/%s/raw/_grabbed/', rootEEGdir, subj);
        
if ~exist(dest,'dir'), mkdir(dest); end
if ~exist(dest,'dir'), error(sprintf(' ERROR: destination directory cant be created '));  end



tryCopy = 0;
numCopy = 0;
for iRaw = 1:length(rawFileList),
    
    for iType=1:length(typeList),
        
        sourceName = sprintf('%s%s.%s', rawFilePrefix, rawFileList{iRaw},typeList{iType});
        source = sprintf('%s/%s', nktdir, sourceName);
        
        
        fprintf('\n copying: %s ', sourceName); tic;
        [status,message,messageid] = copyfile(source,dest,'f');
        fprintf('%s [%.1f s]',message, toc);
        
        tryCopy = tryCopy+1;
        numCopy = numCopy+status;
        
    end
    fprintf('\n');
    
end

fprintf('\n  %d of %d files successfully copied to %s \n', numCopy, tryCopy, dest); 