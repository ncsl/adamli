function [uniqueEegFilePaths] = changeEventsEegFile( subj, rootEEGdir, oldphrase, newphrase )
%
% changeEventsEegFile.m
%
% Changes all the eegfile fields for all events of a given subject to have the appropriate path.  
% Reports the number of instances changed and/or not changed.
% Saves list of warnings and resultant file paths (as printed to command line) to subject/behavioral/eventEegFilePaths.txt
%
% Input Args:
%   subj          subject string                     e.g.)  'NIH018'
%   rootEEGdir    directory to root subject folder,  e.g.)  '/Volumes/shares/FRNU/data/eeg/';
%   oldphrase     The phrase in the events.eegfile you want to replace e.g.) 'dataworking' or 'noreref'
%   newphrase     The replacement phrase e.g.) 'data' or 'reref'
%
%   note: set oldphrase == newphrase (same string, or both empty strings, etc) to only check the existing eegfile paths
%
% Output Args:
%   returnUniquePaths  cell array listing resultant unique eegfile paths... if length >1 events.mat probably need to be tweaked
%   
%
% Example usage:
%  changeEventsEegFile('NIH018', 'C:/Users/jDub/DataJW/eeg/', '', '');                                                       % to check the eegfile pointers for this subject
%  changeEventsEegFile('NIH018', 'C:/Users/jDub/DataJW/eeg/', 'C:/Users/jDub/DataJW/eeg', '/Volumes/shares/FRNU/data/eeg');  % to map local copy to server copy
%  changeEventsEegFile('NIH018', '/Volumes/shares/FRNU/data/eeg', 'eeg.noreref', 'eeg.reref');                               % to map from noreref to reref 
%


strOut = sprintf('\n\n---------------------------------------------------------------------------------------\n');
strOut = sprintf(  '%s---------------------------------   %s   ------------------------------------------\n', strOut,subj);

% check to see whether oldphrase == newphrase... if so, just output unique eegfile paths
if strcmp(oldphrase, newphrase), 
    JUST_CHECK_PATHS = 1;
    strOut = sprintf('%s--- reading all events.eegfile pointers using "changeEventsEegFile.m"\n', strOut);
else
    JUST_CHECK_PATHS = 0; 
    strOut = sprintf('%s--- changing all events.eegfile pointers:\n\tfrom [oldphrase] ''%s'' \n\t  to [newphrase] ''%s''\n', strOut,oldphrase, newphrase);
end


% Set directories
subjDir = fullfileEEG(rootEEGdir, subj);
behDir  = fullfileEEG(rootEEGdir, subj, 'behavioral');


% Open text file that will log the results of this run
outText = fullfileEEG(behDir, 'eventEegFilePathsTemp.txt');
fid     = fopen(outText, 'w+');
if fid==-1, error('ERROR: cannot open %s', outText); end
fprintf(fid,'%s\n',strOut);
fprintf(    '%s\n',strOut);

% Find what experiments were performed for this subject
behDirs = dir(behDir);
behDirs = filterStruct(behDirs,'~strcmp(name,''.'')&~strcmp(name,''..'')&isdir');
if isempty(behDirs)
    fprintf('No experiments in %s. Exiting.\n', behDir);
    return
end


% initialize variables to guide save decision when path is missing... these will be modified below based on user selection
ANY_PATH_ERROR     = 0;
SAVE_INVALID_PATHS = 0;
NO_CHANGE_WARNING  = 0;
numEventsMAT_saved = 0;
eegFilePathCombineSubj = {};
eegFilePathResultSubj  = {};
eegFileResultSubj   = {};
events = []; %must initialize events here so compiler knows we are talking about a variable and not the built in function events()

% loop through experiment directories and look for events.mat to modify
for bd=1:length(behDirs)
    
    % Set this experiment as the directory
    expDir = fullfileEEG(behDir, behDirs(bd).name);
    fprintf(     '\n--- searching %s\n', expDir);
    fprintf(fid, '\n--- searching %s\n', expDir);
    
    % Find what sessions were performed for this subject
    sessDirs = dir(fullfileEEG(expDir, 'session_*'));
    if isempty(sessDirs)
        fprintf(     ' WARNING: missing experimental session directories in %s \n', behDirs(bd).name);
        fprintf(fid, ' WARNING: missing experimental session directories in %s \n', behDirs(bd).name);
    end
    
    % initialize counters
    eegFilePathCombineExp = {};
    eegFilePathResultExp  = {};
    eegFileResultExp  = {};
    
    % loop through each session + look at the root experiment directory
    for sd=1:length(sessDirs)+1
        
        % select session or root experiment event.mat
        if sd<=length(sessDirs),
            evFile = fullfileEEG(expDir,sessDirs(sd).name,'events.mat');   % session-by-session events.mat
            expStr = fullfileEEG(behDirs(bd).name, sessDirs(sd).name);     % for reporting errors and/or total counts
        else
            evFile = fullfileEEG(expDir,'events.mat');                     % experiment's root events.mat file (concatenated from each session)
            expStr = sprintf('root: %s', fullfileEEG(behDirs(bd).name));   % for reporting errors and/or total counts
        end
        
        
        % check for existance of event.mat... if found, modify it
        if ~exist(evFile, 'file'),
            fprintf(' missing events.mat in %s \n', expStr);
            
        else
            load(evFile)
            
            numEvents       = length(events);
            numFieldEmpty   = 0;
            numNoChange     = 0;
            
            % check for eegfile field, if missing, report error, else attempt to modify it
            if ~isfield(events,'eegfile')
                fprintf(     '  missing eegfile field in %s events.mat \n', expStr);
                fprintf(fid, '  missing eegfile field in %s events.mat \n', expStr);
                
                resultStr = 'NONE MODIFIED because eegfile field is MISSING!';
                
            else
                
                % loop through each event...
                eegFileOldAll = {};
                eegFileNewAll = {};
                eegFilePathOldAll = {};
                eegFilePathNewAll = {};
                evs=events;
                for i=1:length(events),
                    
                    % modify the eegfile string
                    evs(i).eegfile       = regexprep(events(i).eegfile,oldphrase,newphrase);
                    
                    % save the result (new and old string)
                    eegFileOldAll{i} = events(i).eegfile;
                    eegFileNewAll{i} = evs(i).eegfile;
                    eegFilePathOldAll{i} = eegFileOldAll{i}(1:max(find(eegFileOldAll{i}=='\' | eegFileOldAll{i}=='/')));
                    eegFilePathNewAll{i} = eegFileNewAll{i}(1:max(find(eegFileNewAll{i}=='\' | eegFileNewAll{i}=='/')));
                    %eegFilePathOldAll{i} = fileparts(events(i).eegfile);  %misses error when last dash is forwards vs backward (mac vs pc)
                    %eegFilePathNewAll{i} = fileparts(evs(i).eegfile);
                    
                    % save a string that combines old and new paths
                    strModNC = ' ';
                    if     strcmp(eegFileOldAll{i},''),               strMod = '[empty field] ';        strModNC = strMod;
                    elseif strcmp(eegFileOldAll{i},eegFileNewAll{i}), strMod = '[missing oldphrase] ';  strModNC = 'set to ';
                    else                                              strMod = '[contained oldphrase] ';  end
                    if JUST_CHECK_PATHS, eegFilePathCombineExp{end+1} = sprintf('%s''%s''', strModNC, eegFilePathOldAll{i});
                    else                 eegFilePathCombineExp{end+1} = sprintf('%s''%s'' --> ''%s''', strMod, eegFilePathOldAll{i}, eegFilePathNewAll{i}); end 
                    eegFilePathCombineSubj{end+1} = eegFilePathCombineExp{end};
                end
                events=evs;
                
                
                % no change means the oldphrase was not found... field empty means the original eegfile was empty,
                numFieldEmpty = sum( strcmp(eegFileOldAll, ''               ) );
                numNoChange   = sum( strcmp(eegFileOldAll, eegFileNewAll) );
                numChanged    = sum( ~strcmp(eegFileOldAll, eegFileNewAll) );
                
                
                % give user a chance to bail early if oldphrase string is wrong
                if numChanged==0 & NO_CHANGE_WARNING==0 & JUST_CHECK_PATHS==0,
                    eegFileOldUnique = unique(eegFileOldAll) ;
                    strOut = sprintf('\nWARNING: didnt find oldphrase string ''%s'' in any of the following eegfile fields:\n',  oldphrase); %not necessarily correct old->new pairing, but probably (should only be 1 pair)
                    for iPath=1:length(eegFileOldUnique), strOut = sprintf('%s   %s\n', strOut, eegFileOldUnique{iPath}); end
                    fprintf(    '%s',strOut);
                    reply = input(' Do you want to [C]ontinue checking the other experiments and/or sessions, or [A]bort?  Type C or A [A]: ', 's');
                    if isempty(reply), reply = 'A';  end
                    if upper(reply(1))=='A',
                        fprintf(fid,'%s',strOut);
                        fprintf(fid, '\n USER elected to abort event rereferencing because oldphrase string was not found in eegfile fields');
                        fclose(fid);
                        error(' ABORTED changeEventsEegFile because oldphrase wasnt found');
                    end
                    fprintf(    '\n');
                end
                NO_CHANGE_WARNING = 1; %only can get the warning if the very first events.mat file does not match up... otherwise at least 1 file has contained the oldphrase
                    
                    
                
                % confirm new eegfile path exists, give user options if it doesn't
                eegFilePathNewUnique = unique(eegFilePathNewAll(~strcmp(eegFilePathOldAll, eegFilePathNewAll))) ;  % unique new file paths (excluding empty eegfile entries)
                INVALID_PATH_FOUND = 0;
                for iPath=1:length(eegFilePathNewUnique),
                    if ~exist(eegFilePathNewUnique{iPath},'dir'),
                        INVALID_PATH_FOUND = 1;
                        
                        %only do this check once
                        if ANY_PATH_ERROR==0,
                            ANY_PATH_ERROR = 1;
                            
                            eegFilePathOldUnique = unique(eegFilePathOldAll(~strcmp(eegFilePathOldAll, eegFilePathNewAll))) ;
                            strOut = sprintf('\nWARNING: attempting to change path from ''%s'' \n', eegFilePathOldUnique{iPath} ); %not necessarily correct old->new pairing, but probably (should only be 1 pair)
                            strOut = sprintf('%sWARNING:                             to ''%s'' \n', strOut, eegFilePathNewUnique{iPath} ); %not necessarily correct old->new pairing, but probably (should only be 1 pair)
                            strOut = sprintf('%sWARNING:  but target eegfile path does not exist on this computer! \n', strOut);
                            fprintf(    '%s',strOut);
                            reply = input('   Do you want to [S]ave modified path(s) anyway, [C]ontinue checking without saving, or [A]bort?  Type S, C, or A [A]: ', 's');
                            if isempty(reply), reply = 'A';  end
                            if upper(reply(1))=='S',
                                SAVE_INVALID_PATHS = 1;  % assume user selects Continue
                            elseif upper(reply(1))~='C',
                                fprintf(fid,'%s',strOut);
                                fprintf(fid, '\n USER elected to abort event rereferencing because target path does not exist on this computer');
                                fclose(fid);
                                error(' ABORTED changeEventsEegFile before saving events.mat');
                            end
                            fprintf(    '\n');
                        end
                    end
                end
                
                
                % save (or don't save) modified events.mat
                if numChanged>0 & (INVALID_PATH_FOUND==0 || SAVE_INVALID_PATHS==1),
                    saveStr = 'SAVED';
                    save(evFile, 'events');
                    numEventsMAT_saved = numEventsMAT_saved+1;
                    eegFilePathResultExp(end+1:end+length(eegFilePathNewAll))  = eegFilePathNewAll;
                    eegFilePathResultSubj(end+1:end+length(eegFilePathNewAll)) = eegFilePathNewAll;
                    eegFileResultExp(end+1:end+length(eegFileNewAll))          = eegFileNewAll;
                    eegFileResultSubj(end+1:end+length(eegFileNewAll))         = eegFileNewAll;
                else
                    saveStr = 'NOT saved';
                    eegFilePathResultExp(end+1:end+length(eegFilePathOldAll))  = eegFilePathOldAll;
                    eegFilePathResultSubj(end+1:end+length(eegFilePathOldAll)) = eegFilePathOldAll;
                    eegFileResultExp(end+1:end+length(eegFileOldAll))          = eegFileOldAll;
                    eegFileResultSubj(end+1:end+length(eegFileOldAll))         = eegFileOldAll;
                end
                resultStr = sprintf('%d contained oldphrase, %d did not (%d fields were empty);  [modified events.mat %s]', numChanged, numNoChange, numFieldEmpty, saveStr);
                
            end
          
            
            % if rereferencing then output the number of events changed, unchanged, and empty
            if JUST_CHECK_PATHS==0,
                strOut = sprintf(' %s: %d events found', expStr, numEvents);
                strOut(end+1:45) = ' '; %buffer out string so result strings line up
                strOut = sprintf('%s--> %s \n', strOut, resultStr);
                fprintf('%s',strOut);
            end    
            
            % if empty fields exist note it in the text file and possible on screen
            if numFieldEmpty>0,
                if sd<=length(sessDirs),
                    strOut = sprintf('warning: %s events.mat has %d eegfile fields empty... modify session.log (based on session.log.align) and re-extract!\n', expStr, numFieldEmpty);
                else
                    strOut = sprintf('warning: %s events.mat has %d eegfile fields empty... re-combine session events.mat files after correcting erroneous session logs\n', expStr, numFieldEmpty);
                end
                fprintf(fid,'%s',strOut);
                if JUST_CHECK_PATHS==1, fprintf(    '%s',strOut); end
            end
            
        end
    end
    
    
    % count number of unique new-old pairs from the experiment
    uniqueSet = unique(eegFilePathCombineExp);
    strResult = '';
    for iPaths=1:length(uniqueSet),
        numOc = length(find(strcmp(eegFilePathCombineExp,uniqueSet{iPaths})));
        strResult = sprintf('%s*  %d eegfile paths %s\n', strResult, numOc, uniqueSet{iPaths});
    end
    fprintf(     '%s',strResult);
    
    % count number of unique resultant file paths from the experiment
    uniqueSet = unique(eegFilePathResultExp);
    strResult = '';
    for iPaths=1:length(uniqueSet),
        numOc = length(find(strcmp(eegFilePathResultExp,uniqueSet{iPaths})));
        strResult = sprintf('%s*  %d eegfile paths set to ''%s''\n', strResult, numOc, uniqueSet{iPaths});
    end
    fprintf(fid, '%s',strResult);
    
    % list unique resultant complete file paths (including eegfile stems) from the subject (what is currently in the events.mat)
    uniqueSet = unique(eegFileResultExp,'sorted');
    strResult = '';
    for iPaths=1:length(uniqueSet),
        numOc = length(find(strcmp(eegFileResultSubj,uniqueSet{iPaths})));
        thisResult = sprintf('-  %d eegfile entries set to:', numOc);
        thisResult(end+1:32) = ' ';
        strResult = sprintf('%s%s ''%s''\n', strResult, thisResult, uniqueSet{iPaths});
    end
    fprintf(fid, '%s',strResult);
    %fprintf(     '%s',strResult);  
end



% list unique resultant complete file paths (including eegfile stems) from the subject (what is currently in the events.mat)
uniqueSet = unique(eegFileResultSubj,'sorted');
strResult = sprintf('\n\n--- SUMMARY: %d unique eegfile entries in events.mat files across all experiments:\n', length(uniqueSet));
for iPaths=1:length(uniqueSet),
    numOc = length(find(strcmp(eegFileResultSubj,uniqueSet{iPaths})));
    thisResult = sprintf('-  %d eegfile entries set to:', numOc);
    thisResult(end+1:32) = ' '; 
    strResult = sprintf('%s%s ''%s''\n', strResult, thisResult, uniqueSet{iPaths});
end
fprintf(fid, '\n%s',strResult);
fprintf(     '%s',strResult);


% summary output combines results from all experiments
strResult = sprintf('\n\n--- SUMMARY: %d events.mat files MODIFIED and SAVED by changeEventsEegFile.m \n', numEventsMAT_saved);
if JUST_CHECK_PATHS==0,  fprintf(     '%s',strResult); end
%fprintf(fid, '%s',strResult);


% count number of unique resultant file paths from the subject (what is currently in the events.mat)
uniqueSet = unique(eegFilePathResultSubj);
strResult = sprintf('\n--- SUMMARY: %d unique eegfile paths in events.mat files across all experiments (should be exactly 1):\n', length(uniqueSet));
for iPaths=1:length(uniqueSet),
    numOc = length(find(strcmp(eegFilePathResultSubj,uniqueSet{iPaths})));
    thisResult = sprintf('*  %d eegfile paths set to:', numOc);
    thisResult(end+1:32) = ' '; 
    strResult = sprintf('%s%s ''%s''\n', strResult, thisResult, uniqueSet{iPaths});
end
fprintf(fid, '\n%s',strResult);
fprintf(     '%s',strResult);
uniqueEegFilePaths = uniqueSet;


%- final banner
strOut = sprintf('\n---------------------------------   %s   ------------------------------------------\n',subj);
strOut = sprintf('%s---------------------------------------------------------------------------------------\n',strOut);
fprintf(strOut)


%-close the temp file and move it to the target location
fclose(fid);
outText2 = fullfileEEG(behDir, 'eventEegFilePaths.txt');
if movefile(outText,outText2,'f'), fprintf('Path info saved to %s \n\n', outText2); else fprintf('Path info saved to %s \n\n', outText); end 

