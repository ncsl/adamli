function behavioralProcessing(subject,eegDir,taskType,altBehDir)
%
% BehavioralProcessing.m€™ extracts events for each task.
%
% Input: 
%      subject = 'NIHXXX', 
%      eegDir = ~/data/eeg', 
%      taskType = 'languageTask'
%      altBehDir = 'behavioral_preOp', 'behavioral_postOp', 'behavioral'  < optional parameter, just pass first 3 to use default 'behaioral' directory
% Output: 
%      saves out event.mat to behavioral session directories
%


% optional input arguement to all for preOp and postOp behavioral directory analysis
if nargin==3,  behFolder = 'behavioral';
else            behFolder = altBehDir;   
    if ~strcmp(behFolder(1:10),'behavioral'),  %- full string should be: 'behavioral', 'behavioral_preOp', 'behavioral_postOp'
        fprintf('\n Uh oh, alternate behavioral folder (%s) may not be specified correctly', altBehDir);
    end
end



subjDir  = fullfileEEG(eegDir,subject);
behDir   = fullfileEEG(subjDir,behFolder,taskType);  % 'behavioral', but could also have 'behavioral_preOp' or 'behavioral_postOp' here
sessions = dir(fullfileEEG(behDir,'session_*'));

    


fprintf('\n\nAttempting to create event.mat files in %d sessions of: %s\n', length(sessions), behDir);

if length(sessions)==0,
    if strcmp(taskType,'stimMapping'),
        fprintf('Must Extract files first...\n');
        eegStimPrep_v3a( subject, eegDir );
        sessions = dir(fullfileEEG(behDir,'session_*'));
    else
    return; 
    end
end

%%- quick loop through sessions to correctly order double digit session numbers (else 10 comes after 1 and before 2)
for iSess = 1:length(sessions),
    sessName    = sessions(iSess).name;
    strNumeric  = find( sessName >= '0' & sessName <= '9');  % following conditional statement pulls out the first chunk of numbers and assumes that is the session number
    if max(diff(strNumeric))>1, iKeep=[1:find(diff(strNumeric)>1,1,'first')]; fprintf('\n Possible issue converting session name into a numeric.. %s --> %s; use %s', sessName, sessName(strNumeric), sessName(strNumeric(iKeep))); strNumeric=strNumeric(iKeep); end;
    sessNum     = str2num( sessName(strNumeric) );  if isempty(sessNum), sessNum=iSess; end; %shouldn't need this catch...
    sessNumAr(iSess) = sessNum;
end
if length(sessions)>0,
    [sortVal sortInd] = sort(sessNumAr);
    sessions = sessions(sortInd);
    sessNumAr = sortVal;
end

if length(sessNumAr)>length(unique(sessNumAr)), 
    fprintf('\n Warning: at least two session folders with same numeric value found in behavioral processing;\n');
    %fprintf('       "session numbers" will be modified to reflect index into session array\n');  sessNumAr=[1:length(sessions)]; 
end
%%- loop through sessions, create events file for each session, then master events.mat in root dir
allEvents = [];
for iSess = 1:length(sessions)
    
    %- construct strings or session numbers from "sessions" to pass to individual extraction functions
    sessName    = sessions(iSess).name;
    sessNum     = sessNumAr(iSess);
    %sessNum     = str2num( sessName(find(sessName=='_')+1:end) );  
    %if isempty(sessNum), sessNum=iSess-1; fprintf('\n Warning: %s getting assigned session number %d \n',sessName, sessNum); end; %shouldn't need this catch... but in case session_1 directory renamed session_1trim
    sessionDir  = fullfileEEG(behDir,sessions(iSess).name);
    sessFileStr = fullfileEEG(behDir,sessions(iSess).name,'session.log');
    eventfile   = fullfileEEG(sessionDir,'events.mat');
    events = [];
    switch taskType
        case 'attentionTask'
            if (strcmp(subject(1:3),'NIH') & str2num(subject(4:6))>=14) | strcmp(subject(1:3),'BEH'),
                events    = jwAttnTaskEvents_v3a(sessFileStr, subject, sessName, allEvents);  % version 3a extracts free recall info
            else
                events    = extractAttentionEvents_v2(subject, behDir, sessNum);  % this *may* not work for all subj < NIH016...
            end
            
        case 'auditoryLexicalDecision'
            events    = extractAudLexEvents(subject,behDir, sessNum);
            
        case 'auditoryVowels'
            events    = extractAudVowEvents(subject,behDir, sessNum);
            
        case 'languageTask'
            if strcmp(subject(1:3),'NIH') & str2num(subject(4:6))<20,
                events    = extractLangEvents_v1(subject,behDir,sessNum);
            else
                events    = extractLangEvents(subject,behDir,sessNum);   %- seems to have problems with NIH025 and NIH026...
            end
        case 'moveTask'
            events    = extractMoveTask(subject,behDir,sessNum);
            
        case 'pa3'
            numBlocks = 15;
            numTrials = 4;
            %touchAnnFiles(sessionDir,numBlocks,numTrials);  %- creates fake (empty) annotation files if ann not found... dont do this! better to wait for annotation!
            try
                events    = extractPA3events(subject,behDir,sessNum,sessionDir);
            catch err
                disp(getReport(err,'extended'));
                events    = [];
            end
            
        case 'paRepeat'
            events    = paRepeat_ExtractEvents(sessFileStr, subject, sessionDir);
            
        case {'palRam','palRamStim'}
            events    = RAM_PAL_CreateTASKEvents(subject,behDir, sessNum, sessName);
            %[eventsMath MATHcfg] = RAM_PAL_CreateMATHEvents(subject,behDir, sessNum);  %- just throw this in for now... not actually using
            %events = [events, eventsMath];
          
        case 'paRemap'
            events    = paRemap_ExtractEvents(sessFileStr, subject, sessName);
          
        case 'playPass'
            events    = extractPlayPassEvents(subject,behDir, sessNum);

        case 'stimMapping'
            events    = createStimEvents_v3a(sessFileStr, subject, sessName, sessNum,eegDir);
            
        case 'goAntiGo'
            events    = extractGoAntiGoEvents(subject,behDir,num2str(sessNum)); % extract the events from the session.log file
        
        case 'SequenceMem'
            events    = extractSequenceMemEvents(subject,behDir,num2str(sessNum)); % extract the events from the session.log file
            
        case 'SerialRT'
            events    = extractSerialRTEvents(subject,behDir,num2str(sessNum));

            
    end
    
    fprintf('\n%d) extracted %d events from %s', iSess, length(events), sessFileStr);
    if length(events)>0,   save(eventfile,'events', '-v7');  %- version 7 file format is compact... only need version 7.3 if >2GB
    else fprintf(' -- NO events, so not creating events.mat');  end
    
    allEvents=[allEvents, events];
end


%%- Confirm success and save new MASTER matfile at root
if isempty(allEvents)
    fprintf('\nNo events for %s. Exiting without creating master events.mat.', taskType);
else
    % Change name and save to root events.mat
    events=allEvents;
    rootevntFileStr = sprintf('%s/events.mat',behDir);
    save(rootevntFileStr, 'events', '-v7');  %- version 7 file format is compact... only need version 7.3 if >2GB
    fprintf('\n --- %d events saved in %s ---\n', length(events), rootevntFileStr);
end

