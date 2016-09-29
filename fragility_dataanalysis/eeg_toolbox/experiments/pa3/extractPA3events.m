function events=extractPA3eventsTMP(subject,expDir,sessionNum,sessionDir)
%
% FUNCTION:
%  events=extractPA3events(subject,expDir,session).
%
% DESCRIPTION:
%  extracts the events associated with pa3.
%
% INPUTS:
%   subject='Aug10Test1';
%   expDir='/Users/dongj3/Jian/data/eeg/Aug10Test1/behavioral';
%   sessionNum=0;
%   sessionDir= '/Users/dongj3/Jian/data/eeg/Aug10Test1/behavioral/pa3/session_0';
%
% OUTPUTS:
%  events=the events structure
%
% CORRECT FIELD:
%  the study orientation, study pair, test orientation,
%  and test pair all contain information whther the item
%  is successfully recalled or not.  If the item was
%  successfully recalled, then the item recalled as well
%  as the reaction time also will appear in all four of
%  these fields
%
% INTRUSION FIELD:
%  0 if the word was correct, was a vocalization, or was a 'pass'.
%  -1 if it was an XLI.  PLI have a number.  The XLI/PLI
%  information is taken from the .ann file.
%
% ISTRIGGER FIELD: Depends on feedback condidtione
%   'none': always -999
%   'STIM': a trial during which stim was delivered.  NOTE that stim is
%           delivered for a set duration.  The recalled events
%           during a stim trial will all have isTrigger=1, but
%           if took a long time for the participant to respond,
%           they vocalozations may have occured after the stim
%           was turned off.
%   'REAL_TIME': a trial in which word presentation was triggered
%           of a measured oscilation.
%
%
% OTHER NOTES:
%  (1) Written by jfburke 4/11 (john.fred.burke@gmail.com)
%  (2) 5/11 (jfb): added all the fields (correct, resp_word, etc) to the
%  orient events so a user can easily filter the orient period for
%  correct vs. incorrect recalls
%  (3) 5/11: added all the fields (correct, resp_word, etc) to stim
%  events
%  (4) changed the way intrusions are scored (5/12/11)
%

%initializes these global variables
global SUBJECT SESSION events
SUBJECT = subject;
SESSION = sessionNum;
thisSessDir = sessionDir;
sessFile    = fullfile(thisSessDir,'session.log');

fid = fopen(sessFile,'r'); %if loops check to see that sessFile exists
if fid==-1
    fprintf('session %d..no session.log file found.\n',SESSION);
    sessFile
    fprintf('EXITING\n\n');
    return
end

% get experimental variables
LL        = getExpInfo_local(expDir,'NUM_PAIRS');
numTrials = getExpInfo_local(expDir,'NUM_TRIALS');
NOUNPOOL  = getNounPool_local(expDir);

% STIM_DURATION     = -999;
% THIS_CURRENT      = -999;
% THIS_ELEC_NUM     = -999;
% STIMTYPE          = -999;

evCounter         = 0;
pairCounterOVRAL  = 0;
probeCounterOVRAL = 0;
trialCounterOVRAL = 0;
events            = [];
% THE_STIM_IS_ON    = -999;
startedASession   = false;

while true
    thisLine = fgetl(fid);
    if ~ischar(thisLine);return;end
    
    % get the third string before the underscore
    xTOT=textscan(thisLine,'%f%d%s');
    thisTYPEall = xTOT{3}{1};
    thisMSTIME  = xTOT{1};
    thisMSOFF   = xTOT{2};
    usIndFoo    = regexp(thisTYPEall,'_');
    if ~isempty(usIndFoo)
        thisTYPE = thisTYPEall(1:usIndFoo(1)-1);
    else
        thisTYPE = thisTYPEall;
    end
    
    % based on the type write different fields for this event
    switch upper(thisTYPE) %switches cases depending on thisTYPE
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'B' %first line of session.log file
            % make the event
            evCounter = evCounter + 1;
            if ~startedASession
                startedASession = true;
            end
            mkNewEvent_local(evCounter,thisMSTIME,thisMSOFF);
            appendNewEvent_local(evCounter,'type',thisTYPE);
            
            % case 'TRIAL'
            
            %     % start/increment counters
            %     pairCounterThisList  = 0;
            %     probeCounterThisList = 0;
            %     trialCounterOVRAL = trialCounterOVRAL + 1;
            
            %     if trialCounterOVRAL>numTrials
            %         error('too many trials')
            %     end
            
            %     % Extract more information from this line
            %     x=textscan(thisLine,'%f%f%s%s');
            %     trialStr = x{3}{1}; tInd = regexp(trialStr,'_');
            %     stimStr  = x{4}{1}; sInd  = regexp(stimStr,'_');
            %     thisTRIALnum_STR = str2double(trialStr(tInd+1:end));
            %     thisSTIMbool = strcmp(upper(stimStr(sInd+1:end)),'TRUE');
            %     if thisTRIALnum_STR+1~=trialCounterOVRAL
            %         error('trials out of order?')
            %     end
            
            
            
            %     % make the event
            %     evCounter = evCounter + 1;
            %     mkNewEvent_local(evCounter,thisMSTIME,thisMSOFF)
            %     appendNewEvent_local(evCounter,'type','TRIAL_START');
            %     appendNewEvent_local(evCounter,'list',trialCounterOVRAL);
            
            
        case 'STUDY'
            % make the event
            evCounter = evCounter + 1;
            mkNewEvent_local(evCounter,thisMSTIME,thisMSOFF)
            
            % Extract more information from this line
            if length(usIndFoo)==1
                studyType = thisTYPEall(usIndFoo(1)+1:end);
            elseif length(usIndFoo)==2
                studyType  = thisTYPEall(usIndFoo(1)+1:usIndFoo(2)-1);
                pairNUMBER_STR = str2double(thisTYPEall(usIndFoo(2)+1:end));
            else
                error('bad number of underscores in %s', thisLine)
            end
            
            % if this is a presentation event (i.e. 'STUDY_PAIR_XX')
            if strcmp(upper(studyType),'START')
                % start/increment counters
                pairCounterThisList  = 0;
                probeCounterThisList = 0;
                trialCounterOVRAL = trialCounterOVRAL + 1;
                
                if trialCounterOVRAL>numTrials
                    error('too many trials')
                end
                
                % Extract more information from this line
                x=textscan(thisLine,'%f%f%s%s');
                trialStr = x{4}{1}; tInd = regexp(trialStr,'_');
                thisTRIALnum_STR = str2double(trialStr(tInd+1:end));
                if thisTRIALnum_STR+1~=trialCounterOVRAL
                    error('trials out of order?')
                end
                
                % append the event
                appendNewEvent_local(evCounter,'type','TRIAL_START');
                appendNewEvent_local(evCounter,'list',trialCounterOVRAL);
                
            elseif strcmp(upper(studyType),'PAIR')
                
                % read the data again to extract the trial number and words
                x=textscan(thisLine,'%f%f%s%s%s%s');
                trialStr =x{4}{1}; tInd   = regexp(trialStr,'_');
                wordStr_1=x{5}{1}; wInd_1 = regexp(wordStr_1,'_');
                wordStr_2=x{6}{1}; wInd_2 = regexp(wordStr_2,'_');
                thisTRIALnum_STR = str2double(trialStr(tInd+1:end));
                word_1=wordStr_1(wInd_1(1)+1:end);
                word_2=wordStr_2(wInd_2(1)+1:end);
                
                % check if the trial number is what we expect
                if thisTRIALnum_STR+1~=trialCounterOVRAL
                    error('trials out of order?')
                end
                
                % check if the pair number in the string is what we expect
                % do this diffrenly depending on whether you know the list
                % length or not
                
                if pairNUMBER_STR+1~=LL*(trialCounterOVRAL-1)+pairCounterThisList
                    error('pairs out of order?')
                end
                
                % now append
                appendNewEvent_local(evCounter,'serialpos',pairCounterThisList);
                appendNewEvent_local(evCounter,'study_1',word_1);
                appendNewEvent_local(evCounter,'study_2',word_2);
                appendNewEvent_local(evCounter,'type',thisTYPEall(1:usIndFoo(2)-1));
                
                % go back and fill in this events orient
                thisListInd  = [events.list]==trialCounterOVRAL;
                thisStudyPairInd = [events.serialpos]==pairCounterThisList;
                thisOrientInd = strcmp({events.type},'STUDY_ORIENT');
                thisStudyOreintInd = find(thisListInd&thisStudyPairInd&thisOrientInd);
                appendNewEvent_local(thisStudyOreintInd,'study_1',word_1);
                appendNewEvent_local(thisStudyOreintInd,'study_2',word_2);
                
                
            elseif strcmp(upper(studyType),'ORIENT')
                % increment the pair counter
                pairCounterThisList = pairCounterThisList + 1;
                appendNewEvent_local(evCounter,'type',thisTYPEall);
                appendNewEvent_local(evCounter,'serialpos',pairCounterThisList);
            else
                appendNewEvent_local(evCounter,'type',thisTYPEall);
            end
            
            % add fields.. add these for all 'STUDY' events
            appendNewEvent_local(evCounter,'list',trialCounterOVRAL);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'TEST'
            
            % Extract more information from this line
            if length(usIndFoo)==1
                testType = thisTYPEall(usIndFoo(1)+1:end);
            elseif length(usIndFoo)==2
                testType  = thisTYPEall(usIndFoo(1)+1:usIndFoo(2)-1);
                probeNUMBER_STR = str2double(thisTYPEall(usIndFoo(2)+1:end));
            else
                error('bad number of underscores in %s', thisLine)
            end
            
            evCounter = evCounter + 1;
            mkNewEvent_local(evCounter,thisMSTIME,thisMSOFF)
            appendNewEvent_local(evCounter,'list',trialCounterOVRAL);
            
            % if this is a probe presentation ...
            if strcmp(upper(testType),'PROBE')
                
                % extract more info (trial num, probe, direction)
                x=textscan(thisLine,'%f%f%s%s%s%s%s');
                trialStr =x{4}{1}; tInd = regexp(trialStr,'\d');
                probeStr =x{5}{1}; pInd = regexp(probeStr,'_');
                expectStr=x{6}{1}; eInd = regexp(expectStr,'_');
                directStr=x{7}{1}; dInd = regexp(directStr,'_');
                thisTRIALnum_STR = str2double(trialStr(tInd:end));
                probe = probeStr(pInd(1)+1:end);
                expect=expectStr(eInd(1)+1:end);
                direct=str2double(directStr(dInd(1)+1:end));
                
                % check if the trial number is what we expect
                if thisTRIALnum_STR+1~=trialCounterOVRAL
                    error('trials out of order?')
                end
                
                % get the serial position during presentation
                thisList_tmp = [events.list]==trialCounterOVRAL;
                thisStudyPair_tmp=strcmp({events.type},'STUDY_PAIR');
                thisStudyOrient_tmp=strcmp({events.type},'STUDY_ORIENT');
                thisStudyStim_tmp=strcmp({events.type},'STUDY_STIM');
                thisProbeOrient_tmp=strcmp({events.type},'TEST_ORIENT');
                
                probeCounter_tmp=[events.probepos]==probeCounterThisList;
                if direct==0
                    studyCounter_tmp=strcmp({events.study_1},probe);
                elseif direct==1
                    studyCounter_tmp=strcmp({events.study_2},probe);
                else
                    error('bad direction value')
                end
                thisItemStudyInd   = find(thisList_tmp&thisStudyPair_tmp&studyCounter_tmp);
                thisOrientStudyInd = find(thisList_tmp&thisStudyOrient_tmp&studyCounter_tmp);
                thisStimStudyInd   = find(thisList_tmp&thisStudyStim_tmp&studyCounter_tmp);
                thisOrientProbeInd = find(thisList_tmp&thisProbeOrient_tmp&probeCounter_tmp);
                
                if isempty(thisItemStudyInd);error('item not found');end
                if length(thisItemStudyInd)>1;error('too many items');end
                if isempty(thisOrientStudyInd);error('item not found');end
                if length(thisOrientStudyInd)>1;error('too many items');end
                if isempty(thisOrientProbeInd);error('item not found');end
                if length(thisOrientProbeInd)>1;error('too many items');end
                serialPos = events(thisItemStudyInd).serialpos;
                
                % check if the probe number in the string matches the studies
                % serial position
                if probeNUMBER_STR+1~=LL*(trialCounterOVRAL-1)+serialPos
                    error('probe does not match serial position')
                end
                
                % get the lag between the words
                lag = (LL-serialPos)+probeCounterThisList;
                
                % add info to current event
                appendNewEvent_local(evCounter,'probepos',probeCounterThisList);
                appendNewEvent_local(evCounter,'probe_word',probe);
                appendNewEvent_local(evCounter,'cue_direction',direct);
                appendNewEvent_local(evCounter,'serialpos',serialPos);
                appendNewEvent_local(evCounter,'lag',lag);
                appendNewEvent_local(evCounter,'type',thisTYPEall(1:usIndFoo(2)-1));
                appendNewEvent_local(evCounter,'study_1',events(thisItemStudyInd).study_1);
                appendNewEvent_local(evCounter,'study_2',events(thisItemStudyInd).study_2);
                
                % add info to the probe ORIENT event
                appendNewEvent_local(thisOrientProbeInd,'probe_word',probe);
                appendNewEvent_local(thisOrientProbeInd,'cue_direction',direct);
                appendNewEvent_local(thisOrientProbeInd,'serialpos',serialPos);
                appendNewEvent_local(thisOrientProbeInd,'lag',lag);
                appendNewEvent_local(thisOrientProbeInd,'study_1',events(thisItemStudyInd).study_1);
                appendNewEvent_local(thisOrientProbeInd,'study_2',events(thisItemStudyInd).study_2);
                
                % add some fileds to the study (based on what happened during test)
                appendNewEvent_local(thisItemStudyInd,'lag',lag);
                appendNewEvent_local(thisItemStudyInd,'probepos',probeCounterThisList);
                appendNewEvent_local(thisItemStudyInd,'cue_direction',direct);
                appendNewEvent_local(thisItemStudyInd,'probe_word',probe);
                
                % also add some info to the ORIENT
                appendNewEvent_local(thisOrientStudyInd,'lag',lag);
                appendNewEvent_local(thisOrientStudyInd,'probepos',probeCounterThisList);
                appendNewEvent_local(thisOrientStudyInd,'cue_direction',direct);
                appendNewEvent_local(thisOrientStudyInd,'probe_word',probe);
                
                
            elseif strcmp(upper(testType),'ORIENT')
                % increment the probe counter for this list
                probeCounterThisList = probeCounterThisList + 1;
                appendNewEvent_local(evCounter,'probepos',probeCounterThisList);
                appendNewEvent_local(evCounter,'type',thisTYPEall);
            elseif strcmp(upper(testType),'START')
                appendNewEvent_local(evCounter,'type',thisTYPEall);
            else
                error('should never happen')
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'REC'
            
            % get the characters after the underscore (3rd string)
            testType = thisTYPEall(usIndFoo(1)+1:end);
            
            switch upper(testType)
                case 'START'
                    % go through and get all the recalls here.. the
                    % 'serialPos' is unchanged from the last time we got it in
                    % the 'TEST_PROBE' condidtion
                    annFileName  = sprintf('%d_%d.ann',trialCounterOVRAL-1,serialPos-1);
                    annFile      = fullfile(thisSessDir,annFileName);
                    if ~exist(annFile)
                        error('%s was not found',annFile)
                    end
                    fid2=fopen(annFile,'r');
                    if fseek(fid2,1,'bof')==-1 %annotation file is empty
                        correct=0;
                        isVOC=0;
                        isPass=1;
                        intrusion=0;
                        thisRecWord='';
                        thisRT=NaN;
                        
                        evCounter = evCounter + 1;
                        mkNewEvent_local(evCounter,thisMSTIME+thisRT,20)
                        appendNewEvent_local(evCounter,'type','REC_EVENT');
                        appendNewEvent_local(evCounter,'list',trialCounterOVRAL);
                        appendNewEvent_local(evCounter,'probepos',probeCounterThisList);
                        appendNewEvent_local(evCounter,'probe_word',probe);
                        appendNewEvent_local(evCounter,'cue_direction',direct);
                        appendNewEvent_local(evCounter,'serialpos',serialPos);
                        appendNewEvent_local(evCounter,'lag',lag);
                        appendNewEvent_local(evCounter,'RT',thisRT);
                        appendNewEvent_local(evCounter,'correct',correct);
                        appendNewEvent_local(evCounter,'pass',isPass);
                        appendNewEvent_local(evCounter,'vocalization',isVOC);
                        appendNewEvent_local(evCounter,'intrusion',intrusion);
                        appendNewEvent_local(evCounter,'resp_word',thisRecWord);
                        appendNewEvent_local(evCounter,'study_1',events(thisItemStudyInd).study_1);
                        appendNewEvent_local(evCounter,'study_2',events(thisItemStudyInd).study_2);
                    else
                        fclose(fid2);
                        fid2=fopen(annFile,'r');
                        while true
                            tmpAnnLine=fgetl(fid2);
                            if ~ischar(tmpAnnLine);break;end
                            if numel(tmpAnnLine)==0;continue;end
                            if strcmp(tmpAnnLine(1),'#');continue;end
                            x2=textscan(tmpAnnLine,'%f%f%s');
                            thisRT = round(x2{1});
                            thisWordNum = x2{2};
                            thisRecWord = x2{3}{1};
                            correct  = strcmp(thisRecWord,expect);
                            isVOC    =  strcmp(upper(thisRecWord),'<>') ...
                                | strcmp(upper(thisRecWord),probe);
                            isPass   = strcmp(upper(thisRecWord),'PASS');
                            
                            if ~correct&~isVOC&~isPass
                                intrusion=thisWordNum;
                            else
                                intrusion=0;
                            end
                            
                            if  (~isVOC & ~isPass & ~intrusion) && ...
                                    ~strcmp(NOUNPOOL{thisWordNum},thisRecWord)
                                error('this should never happpen... something is wrong')
                            end
                            if (isPass | isVOC | intrusion) & correct
                                error('this should never happpen... something is wrong')
                            end
                            
                            % make the event for the recalled event
                            evCounter = evCounter + 1;
                            mkNewEvent_local(evCounter,thisMSTIME+thisRT,20)
                            appendNewEvent_local(evCounter,'type','REC_EVENT');
                            appendNewEvent_local(evCounter,'list',trialCounterOVRAL);
                            appendNewEvent_local(evCounter,'probepos',probeCounterThisList);
                            appendNewEvent_local(evCounter,'probe_word',probe);
                            appendNewEvent_local(evCounter,'cue_direction',direct);
                            appendNewEvent_local(evCounter,'serialpos',serialPos);
                            appendNewEvent_local(evCounter,'lag',lag);
                            appendNewEvent_local(evCounter,'RT',thisRT);
                            appendNewEvent_local(evCounter,'correct',correct);
                            appendNewEvent_local(evCounter,'pass',isPass);
                            appendNewEvent_local(evCounter,'vocalization',isVOC);
                            appendNewEvent_local(evCounter,'intrusion',intrusion);
                            appendNewEvent_local(evCounter,'resp_word',thisRecWord);
                            appendNewEvent_local(evCounter,'study_1',events(thisItemStudyInd).study_1);
                            appendNewEvent_local(evCounter,'study_2',events(thisItemStudyInd).study_2);
                            
                        end
                    end
                    
                    fclose(fid2);
                    
                    % Find the index of the study and probe for this rec event
                    thisList_tmp        = [events.list]==trialCounterOVRAL;
                    thisStudyPair_tmp   = strcmp({events.type},'STUDY_PAIR');
                    thisStudyOrient_tmp = strcmp({events.type},'STUDY_ORIENT');
                    thisProbePair_tmp   = strcmp({events.type},'TEST_PROBE');
                    thisProbeOrient_tmp = strcmp({events.type},'TEST_ORIENT');
                    thisSerPos_tmp      = [events.serialpos]==serialPos;
                    thisCorrect_tmp     = [events.correct]==true;
                    thisIntrusion_tmp   = [events.intrusion]~=0;
                    thisPass_tmp        = [events.pass]==1;
                    thisRec_tmp         = strcmp({events.type},'REC_EVENT');
                    
                    thisItemStudyPairInd   = find(thisList_tmp&thisStudyPair_tmp&thisSerPos_tmp);
                    thisItemStudyOrientInd = find(thisList_tmp&thisStudyOrient_tmp&thisSerPos_tmp);
                    thisItemProbePairInd   = find(thisList_tmp&thisProbePair_tmp&thisSerPos_tmp);
                    thisItemProbeOrientInd = find(thisList_tmp&thisProbeOrient_tmp&thisSerPos_tmp);
                    
                    if isempty(thisItemStudyPairInd);error('item not found');end
                    if length(thisItemStudyPairInd)>1;error('too many items');end
                    if isempty(thisItemProbePairInd);error('item not found');end
                    if length(thisItemProbePairInd)>1;error('too many items');end
                    if isempty(thisItemStudyOrientInd);error('item not found');end
                    if length(thisItemStudyOrientInd)>1;error('too many items');end
                    if isempty(thisItemProbeOrientInd);error('item not found');end
                    if length(thisItemProbeOrientInd)>1;error('too many items');end
                    
                    % Go back and fill in info for the study and probe events
                    % based on how they performed during recall
                    allCorr = [events(thisList_tmp&thisRec_tmp&thisSerPos_tmp).correct];
                    anyCorr = sum(allCorr)>0;
                    
                    allInt = [events(thisList_tmp&thisRec_tmp&thisSerPos_tmp).intrusion];
                    anyInt = any(allInt);
                    
                    allPass = [events(thisList_tmp&thisRec_tmp&thisSerPos_tmp).pass];
                    anyPass = sum(allPass)>0;
                    
                    allVoc = [events(thisList_tmp&thisRec_tmp&thisSerPos_tmp).vocalization];
                    anyVoc = sum(allVoc)>0;
                    
                    
                    appendNewEvent_local(thisItemStudyPairInd,'correct',anyCorr);
                    appendNewEvent_local(thisItemProbePairInd,'correct',anyCorr);
                    appendNewEvent_local(thisItemStudyOrientInd,'correct',anyCorr);
                    appendNewEvent_local(thisItemProbeOrientInd,'correct',anyCorr);
                    
                    if anyCorr
                        cInd_tmp=find(thisList_tmp&thisRec_tmp&thisSerPos_tmp&thisCorrect_tmp);
                        if isempty(cInd_tmp);error('item not found');end
                        if length(cInd_tmp)>1;cInd_tmp=cInd_tmp(1);;end
                        thisCorrWord=events(cInd_tmp).resp_word;
                        thisCorrRT=events(cInd_tmp).RT;
                        appendNewEvent_local(thisItemStudyPairInd,'resp_word',thisCorrWord);
                        appendNewEvent_local(thisItemStudyPairInd,'RT',thisCorrRT);
                        appendNewEvent_local(thisItemProbePairInd,'resp_word',thisCorrWord);
                        appendNewEvent_local(thisItemProbePairInd,'RT',thisCorrRT);
                        appendNewEvent_local(thisItemStudyOrientInd,'resp_word',thisCorrWord);
                        appendNewEvent_local(thisItemStudyOrientInd,'RT',thisCorrRT);
                        appendNewEvent_local(thisItemProbeOrientInd,'resp_word',thisCorrWord);
                        appendNewEvent_local(thisItemProbeOrientInd,'RT',thisCorrRT);
                        
                        
                        appendNewEvent_local(thisItemStudyPairInd,'intrusion',0);
                        appendNewEvent_local(thisItemProbePairInd,'intrusion',0);
                        appendNewEvent_local(thisItemStudyOrientInd,'intrusion',0);
                        appendNewEvent_local(thisItemProbeOrientInd,'intrusion',0);
                        appendNewEvent_local(thisItemStudyPairInd,'pass',0);
                        appendNewEvent_local(thisItemProbePairInd,'pass',0);
                        appendNewEvent_local(thisItemStudyOrientInd,'pass',0);
                        appendNewEvent_local(thisItemProbeOrientInd,'pass',0);
                        appendNewEvent_local(thisItemStudyPairInd,'vocalization',0);
                        appendNewEvent_local(thisItemProbePairInd,'vocalization',0);
                        appendNewEvent_local(thisItemStudyOrientInd,'vocalization',0);
                        appendNewEvent_local(thisItemProbeOrientInd,'vocalization',0);
                        
                    elseif anyInt
                        
                        appendNewEvent_local(thisItemStudyPairInd,'intrusion',intrusion);
                        appendNewEvent_local(thisItemProbePairInd,'intrusion',intrusion);
                        appendNewEvent_local(thisItemStudyOrientInd,'intrusion',intrusion);
                        appendNewEvent_local(thisItemProbeOrientInd,'intrusion',intrusion);
                        
                        cInd_tmp=find(thisList_tmp&thisRec_tmp&thisSerPos_tmp&thisIntrusion_tmp);
                        if isempty(cInd_tmp);error('item not found');end
                        if length(cInd_tmp)>1;cInd_tmp=cInd_tmp(1);;end
                        thisIntWord=events(cInd_tmp).resp_word;
                        thisIntRT=events(cInd_tmp).RT;
                        appendNewEvent_local(thisItemStudyPairInd,'resp_word',thisIntWord);
                        appendNewEvent_local(thisItemStudyPairInd,'RT',thisIntRT);
                        appendNewEvent_local(thisItemProbePairInd,'resp_word',thisIntWord);
                        appendNewEvent_local(thisItemProbePairInd,'RT',thisIntRT);
                        appendNewEvent_local(thisItemStudyOrientInd,'resp_word',thisIntWord);
                        appendNewEvent_local(thisItemStudyOrientInd,'RT',thisIntRT);
                        appendNewEvent_local(thisItemProbeOrientInd,'resp_word',thisIntWord);
                        appendNewEvent_local(thisItemProbeOrientInd,'RT',thisIntRT);
                        
                        appendNewEvent_local(thisItemStudyPairInd,'pass',0);
                        appendNewEvent_local(thisItemProbePairInd,'pass',0);
                        appendNewEvent_local(thisItemStudyOrientInd,'pass',0);
                        appendNewEvent_local(thisItemProbeOrientInd,'pass',0);
                        appendNewEvent_local(thisItemStudyPairInd,'vocalization',0);
                        appendNewEvent_local(thisItemProbePairInd,'vocalization',0);
                        appendNewEvent_local(thisItemStudyOrientInd,'vocalization',0);
                        appendNewEvent_local(thisItemProbeOrientInd,'vocalization',0);
                        
                    else
                        
                        isPass=1;
                        appendNewEvent_local(thisItemStudyPairInd,'pass',isPass);
                        appendNewEvent_local(thisItemProbePairInd,'pass',isPass);
                        appendNewEvent_local(thisItemStudyOrientInd,'pass',isPass);
                        appendNewEvent_local(thisItemProbeOrientInd,'pass',isPass);
                        
                        appendNewEvent_local(thisItemStudyPairInd,'vocalization',isVOC);
                        appendNewEvent_local(thisItemProbePairInd,'vocalization',isVOC);
                        appendNewEvent_local(thisItemStudyOrientInd,'vocalization',isVOC);
                        appendNewEvent_local(thisItemProbeOrientInd,'vocalization',isVOC);
                        
                        appendNewEvent_local(thisItemStudyPairInd,'intrusion',intrusion);
                        appendNewEvent_local(thisItemProbePairInd,'intrusion',intrusion);
                        appendNewEvent_local(thisItemStudyOrientInd,'intrusion',intrusion);
                        appendNewEvent_local(thisItemProbeOrientInd,'intrusion',intrusion);
                        
                        
                        cInd_tmp=find(thisList_tmp&thisRec_tmp&thisSerPos_tmp&thisPass_tmp);
                        if isempty(cInd_tmp);
                            thisPassRT = NaN;
                            thisPassWord = '';
                        else
                            thisPassWord=events(cInd_tmp).resp_word;
                            thisPassRT=events(cInd_tmp).RT;
                        end
                        if length(cInd_tmp)>1;cInd_tmp=cInd_tmp(1);;end
                        
                        appendNewEvent_local(thisItemStudyPairInd,'resp_word',thisPassWord);
                        appendNewEvent_local(thisItemStudyPairInd,'RT',thisPassRT);
                        appendNewEvent_local(thisItemProbePairInd,'resp_word',thisPassWord);
                        appendNewEvent_local(thisItemProbePairInd,'RT',thisPassRT);
                        appendNewEvent_local(thisItemStudyOrientInd,'resp_word',thisPassWord);
                        appendNewEvent_local(thisItemStudyOrientInd,'RT',thisPassRT);
                        appendNewEvent_local(thisItemProbeOrientInd,'resp_word',thisPassWord);
                        appendNewEvent_local(thisItemProbeOrientInd,'RT',thisPassRT);
                        
                        
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                case 'END'
                    
                    % do not add this event
            end
    end
end

save('events.mat','ans')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mkNewEvent_local(evCounter,mstime,msoffset)
global SUBJECT SESSION events

events(evCounter).subject       = SUBJECT;
events(evCounter).session       = SESSION;
%events(evCounter).feedback      = STIMTYPE;
events(evCounter).type          = -999;
events(evCounter).list          = -999;
events(evCounter).serialpos     = -999;
events(evCounter).probepos      = -999;
events(evCounter).study_1       = -999;
events(evCounter).study_2       = -999;
events(evCounter).cue_direction = -999;
events(evCounter).probe_word    = -999;
events(evCounter).resp_word     = -999;
events(evCounter).lag           = -999;
events(evCounter).correct       = -999;
events(evCounter).intrusion     = -999;
events(evCounter).pass          = -999;
events(evCounter).vocalization  = -999;
events(evCounter).RT            = -999;
events(evCounter).mstime        = mstime;
events(evCounter).msoffset      = msoffset;

function appendNewEvent_local(evCounter,varargin)
global events
nVar = length(varargin)/2;
for v=1:nVar
    thisVarField = varargin{2*(v-1)+1};
    thisVarData  = varargin{2*(v-1)+2};
    events(evCounter)=setfield(events(evCounter),thisVarField,thisVarData);
end

function [out] = getExpInfo_local(expDir,str2get);
fid_foo1 = fopen(fullfile(expDir,'config.py'),'r');
while true
    thisLine = fgetl(fid_foo1);
    if ~ischar(thisLine);break;end
    if numel(thisLine)==0;continue;end
    if strcmp(thisLine(1),'#');continue;end
    possible_str=textscan(thisLine,'%s%f','Delimiter','=');
    if strcmp(possible_str{1}{1},str2get)
        out=possible_str{2};
        break
    end
end
fclose (fid_foo1);

function [words] = getNounPool_local(expDir);
fid_foo1 = fopen(fullfile(expDir,'nounpool.txt'),'r');
X=textscan(fid_foo1,'%s');
words=X{1};
fclose (fid_foo1);
if ismember(upper('pass'),words)
    error('pass is in the nounpool!')
end