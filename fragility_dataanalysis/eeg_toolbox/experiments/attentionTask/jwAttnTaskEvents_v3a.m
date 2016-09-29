function [events] = jwAttnTaskEvents_v2(sessLogFile, subject, sessionName, priorEvents)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  Function for extracting behavioral data from the AttentionTask %%%%
%%%%
%%%%  attentionTask_v2.4.py  --- serial word presentation asterisk before, after, none;
%%%%                             forced choice testing with word pairs using joystick
%%%%
%%%%  version v2c.m of jwATTnTaskEvents... small tweaks to propogate RT to the sample
%%%%  version v3a.m of jwAttnTaskEvents: processed free recall annotations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


eventFile = '';
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% uncomment following lines to directly run script
% clear all
% 
% rootEEGdir  = '/Users/wittigj/DataJW/AnalysisStuff/dataLocal/eeg';
% %rootEEGdir  = 'C:/Users/jDub/DataJW/eeg/';
% subject     = 'NIH022';   % EEG002  NIH016
% sessionName = 'session_1';
% 
% sessionDir  = fullfileEEG(rootEEGdir,subject,'behavioral/attentionTask',sessionName);
% sessLogFile = fullfileEEG(sessionDir,'session.log');
% eventFile   = fullfileEEG(sessionDir,'events.mat');
% priorEvents = [];
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


fid = fopen(sessLogFile,'r'); %if loops check to see that sessFile exists
if (fid==-1)
    error('Session.log not found: \n %s \n Exiting.',sessLogFile);
else
    [sessionDir,~,~] = fileparts(sessLogFile); %- used for finding annotation files
    %disp([' The session.log file is located in: '  sessLogFile]);
end

%- Convert session folder name into a number.  Should make sessions like "session_9trim" --> 9
strNumeric = find( sessionName >= '0' & sessionName <= '9');   if max(diff(strNumeric))>1, fprintf('\n ERROR: problem converting session name into a numeric.. %s --> %s', sessionName, sessionName(strNumeric)); keyboard; end;
sessNum    = str2num( sessionName(strNumeric) );               if isempty(sessNum), fprintf('\n ERROR: problem converting session name into a numeric'); keyboard;  end; %shouldn't need this catch...


UPDATE_LST_FilE = 0; %- if 1, a BLOCK_X.lst file will be created for each Free Recall period.  
%                   The updated list will contain all asterisk AND non-asterisk words from the current list (NIH018-029 only have the asterisk words)
%                   circa NIH030 the list file is constructed with none's and asterisks words (all encoded words), so no need to regenerate


if (~isempty(priorEvents))
    priorBlockCount  = max([priorEvents.blockCount])+1;
    priorEventCount  = max([priorEvents.eventCount])+1;
    priorSampleCount = max([priorEvents.sampleCount])+1;
    priorTestCount   = max([priorEvents.testCount])+1;
else
    priorBlockCount  = 0;
    priorEventCount  = 0;
    priorSampleCount = 0;
    priorTestCount   = 0;
end

%- Set some constants used in the python script
AST_BEFORE      = 1 ;
AST_AFTER       = 2 ;
AST_NONE        = 3 ;
RECOG_FOIL      = 4 ;


%- Init some state variables
newBlock        = nan;   %- used to track block increments
block           = nan;   %- set during first WORD_PRESENT
msBlockStart    = -1 ;

%newSession      = -1;      %- previously used to isolate the first SES_START in the file (should only be 1, but could be multiple if session incomplete) JW cut on 2/2015
sessionNum      = sessNum; %- defined from session folder name above
msSessStart     = -1;      %- should be set to mstime of the last "SESSION_START" event in the sesion.log file
msDuration      = nan;

% msCrossStart    = nan;
% msTextStart     = nan;
% msTextStop      = nan;
% msEventStart    = nan;
% msEventEnd      = nan;
% msEventNext     = nan;

blockCount      = priorBlockCount ;
eventCount      = priorEventCount ;  %increments for each encoded word (at cross) and each test (at cross if exists, else at test itself)
sampleCount     = nan ;
testCount       = nan ;

blockWordList   = {};  %-used for free recall annotation scoring
blockWordType   = [];

TESTING_PHASE   = 0 ; % this state variable switches between 0 and

MISSING_ANN     = 0 ; % only report the first 2 missing ANN files

%- Read session.log line-by-line and convert to events structure
events      = [];
index       = 0;
while true
    thisLine            = fgetl(fid);
    if ~ischar(thisLine); break; end
    
    
    %- Generic text scan to get time, offset, and type
    xTOT                = textscan(thisLine,'%f%d%s');
    mstime              = xTOT{1}(1);   %- must add (1) because numbers after the string in the above line cause overflow to first %f
    msoffset            = xTOT{2}(1);
    type                = xTOT{3}{1};
    
    
    %- default Parameters (details will be filled out/altered based on type)
    experiment          = 'attentionTask';
    subject             = subject   ;
    sessionName         = sessionName ;
    sessionNum          = sessionNum  ;  %- store in state var so all events are assigned a sessionNum
    mstime              = mstime    ;
    msoffset            = msoffset  ;
    type                = type      ;
    block               = block     ; 	%- store in state var so all events are assigne a block
    
    sampleListIndex     = -999      ;  	%- serial position of sample; list position of encoded word (i.e., 1st word of the list)
    testListIndex       = -999      ;  	%- serial position of test;  list position of test (i.e. 4th test of the list)
    asteriskType        = -999      ;   %- 0,1,2,4,-999:  no, before, after, fiol, n/a
    testCount           = -999      ; 	%-
    isSample            = 0         ;   %- 1 for sample words, 0 for everything else
    isTest              = 0         ;   %- 1 for test words, 0 for everything else
    isCross             = 0         ;   %- 1 for crosses during the encoding phase, 2 for cross during test phase, 0 for everything else
    isAsterisk          = 0         ;   %- 1 for *before, 2 for *aster, 0 otherwise (different than asterisk field, which indicates whether word is associated with asterisk)
    isFreeRecall        = 0         ;   %- 1 for recall meta event (contains all recall info in one), 0 otherwise
    
    textAbrev           = ''        ;   %- abbreviated string describing task for plots
    textStr             = ''        ;  	%- encoded word or test word (depends on event type)
    encodedWord         = ''        ;
    targetWord          = ''        ;
    testWordList        = ''        ;
    resultStr           = ''        ;   %- string: (n/a)not tested, (C)orrect (E)error (S)kip
    
    responseCorrect     = nan       ; 	%- 0-error, 1=correct, -1=skipped, -999=n/a
    RT                  = -999      ;
    targetLoc           = -999      ;
    responseLoc         = -999      ;
    freelyRecalled      = nan       ;   %- (nan)-FR annotation not processed, or not an encoded word (ast or non-ast).  0=not said during FR, 1=spoken.  Applies to encoding and recog test events.
    annotateFRsaid = nan;  annotateFRastr = nan; annotateFRnone = nan;
    reportedFRsaid = nan;  reportedFRcorr = nan; 
    
    %foilWord            = ''   ;
    %foilSide            = -999 ;
    
    
    switch type
        case 'SESS_START'
            xTOT=textscan(thisLine,'%f%d%s%d'); % grab the session number
            
            %%- 2/2015 -- JW modified because NIH019 session_9b wasn't getting registered correctly
            %newSession          = xTOT{4};  %- dont use this... more accurate to use the string from the session folder (and useful for sorting later)
            %textAbrev           = sprintf('SESSION %d',newSession);
            %textStr             = sprintf('session %d',newSession);
            %resultStr           = sprintf('%d',newSession);
            
            
            textAbrev           = sprintf('SESSION %s',sessionName);
            textStr             = sprintf('session %s',sessionName);
            resultStr           = sprintf('%s',sessionName);
            
            msSessStart         = mstime;
            index=index+1;

            
        case {'START_BLOCK_PROMPT', 'START_BLOCK_SELECT'}
            TESTING_PHASE       = 0;  % state variable... encoding phase starting now
            blockWordList       = {};
            blockWordType       = [];
            
        case {'FORCED_CHOICE_4ALT_START', 'FORCED_CHOICE_0ALT_START'}
            TESTING_PHASE       = 1;  % state variable... testing phase starting now (either recognition or forced choice)
            
        case 'WORD_PRESENT'
            xTOT=textscan(thisLine,'%f%d%s%d%d%d%s');
            newBlock            = xTOT{4};
            sampleListIndex     = xTOT{5};
            asteriskType        = xTOT{6};
            encodedWord         = upper(xTOT{7}{1}); %- in spanish this word is lower case... make them all upper to match annotation
            
            isSample            = 0; % assume NOT a samle stimulus (i.e., word)
            switch encodedWord(1)
                case '?'
                    textAbrev    = '?';
                    eventCount   = eventCount+1;    % treat ? as new event so not considered run on from previous event
                    msTextStart  = mstime;
                    msCrossStart = mstime;
                    asteriskType = -999;            % astrisk not applicable to ???
                    
                case '+'
                    textAbrev    = '+';
                    %testListIndex = asteriskType;    % reassign columns for '+' during forced choice
                    eventCount   = eventCount+1;    % use '+' to mark new event (applies to encoding and new version of forced choice
                    msCrossStart = mstime;
                    if TESTING_PHASE==0, isCross = 1;
                    else                 isCross = 2; end
                    asteriskType = -999;
                    
                case '*'
                    textAbrev    = '*';
                    isAsterisk   = asteriskType;    % 1 for *before, 2 for *after.  All other stimuli get a 0
                    
                otherwise %word
                    textAbrev    = 'W';
                    isSample     = 1 ;
                    msTextStart  = mstime;
                    
                    %- save word and asterisk type to a list for judging free recall responses
                    blockWordList{end+1}=encodedWord;
                    blockWordType(end+1)=asteriskType;
                    
            end
            
            responseCorrect     = nan;
            resultStr           = 'n/a';
            msDuration          = nan;
            textStr             = encodedWord;
            index=index+1;
            
        case {'TASK_FC', 'TASK_RECOG'}
            %%- attentionTask before v2.0:   NIH 003, 005, 007, 009, 010, 011, 012
            error('Session.log is for old version of attentionTask: forced choice or recogition... not prepared to grab this data!')
            
        case 'FORCED_CHOICE'
            %%- attentionTask_v2.1 and earlier:  NIH014, 015, 016, 017;   EEG001
            %    time / offset / FORCED_CHOICE / block / encodeTrial / testTrial / asteriskVal / foilSide / test text / foil text / response correct? (0 or 1) / rxn time
            %log.logMessage('%s\t%d\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d' % ('FORCED_CHOICE',iBlock,trials[testNum],testNum,asteriskVal[testNum],foilSide[testNum],shown[testNum],foil,resp,rt[2][0]-rt[0][0]),rt[0]) # version 2.0 syntax
            
            xTOT=textscan(thisLine,'%f%d%s%d%d%d%d%d%s%s%d%d');
            newBlock            = xTOT{4};
            sampleListIndex     = xTOT{5};      % test's source index (i.e., index of encoded word)
            testListIndex       = xTOT{6};      % index of test word in this list
            asteriskType        = xTOT{7};      % asterisk status of tested word (1=before, 2=after, 3=none)
            foilSide            = xTOT{8};      % which side was the foil on? convert this to "targetLoc" before saving to eventStructure
            targetWord          = upper(xTOT{9}{1});
            foilWord            = upper(xTOT{10}{1});
            responseCorrect     = xTOT{11};
            RT                  = xTOT{12};
            if (RT==7000) responseCorrect = -1; respLoc = -1; end % add hack to correctly identify skipped trials (python code was not making this assignment)
            
            targetLoc           = 1-foilSide;
            if (responseCorrect == 0)   responseLoc  = 1 - targetLoc;              elseif (responseCorrect == 1) responseLoc  = targetLoc;                  end
            astB='';astA=''; if (asteriskType==AST_BEFORE) astB='*'; elseif (asteriskType==AST_AFTER) astA='*'; end
            if (responseCorrect == 0)   resultStr    = sprintf('%sE%s',astB,astA); elseif (responseCorrect == 1) resultStr    = sprintf('%sC%s',astB,astA); else  resultStr = sprintf('%sS%s',astB,astA);  end
            if (foilSide==0)            testWordList = {foilWord, targetWord};     else                          testWordList = {targetWord, foilWord};     end
            
            eventCount          = eventCount+1; %no +'s between test words, so increment on the forced choice
            isTest              = 1;
            msCrossStart        = nan;          %no +'s between test words
            msTextStart         = mstime;
            msDuration          = RT;
            textAbrev           = 'FC';
            textStr             = targetWord;
            index=index+1;
            
        case {'FORCED_CHOICE_4ALT', 'FORCED_CHOICE_2ALT', 'FORCED_CHOICE_0ALT'}
            %%- attentionTask_v2.4 and later:    EEG002
            %for iStim in range(1,len(thisTestList)): strStim = '%s\t%s' % (strStim, thisTestList[iStim])  # creates list of stim: left, right, up, down
            %    time / offset / FORCED_CHOICE_4ALT / block / encodeTrial / testTrial / asteriskVal / targetLoc (0-3) / target text /  respLoc (0-3) / response correct? (0 or 1) / rxn time / stimulus string (left,right,up,down)
            %log.logMessage('%s_%dALT\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%d\t%d\t%s' % ('FORCED_CHOICE', config.FC_ALTERNATIVES, iBlock, iShown[testNum], testNum, attnVal[testNum], targetLoc[testNum], target[testNum], respLoc, testResult, rxnTime, strStim), stimTime)
            
            xTOT=textscan(thisLine,'%f%d%s%d%d%d%d%d%s%d%d%d%s%s%s%s');
            newBlock            = xTOT{4};
            sampleListIndex     = xTOT{5};      % test's source index (i.e., index of encoded word)
            testListIndex       = xTOT{6};      % index of test word in this list
            asteriskType        = xTOT{7};      % asterisk status of tested word (1=before, 2=after, 3=none, -1=foil)
            targetLoc           = xTOT{8};      % what is the location (0-3) of the target?
            targetWord          = upper(xTOT{9}{1});   % target word
            responseLoc         = xTOT{10};     % response location (0-3; -1 for skip)
            responseCorrect     = xTOT{11};     % correct response?  0,1,-1 (skip = -1)
            RT                  = xTOT{12};
            testWordList        = xTOT(13:16);
            
            fcORrecog           = 'FC';         % forced-choice or recognition?
            if     strcmp(type,'FORCED_CHOICE_2ALT'),  %2ALT, cut out the empty words from the list
                %testWordList = {upper(testWordList{1:2})};
                testWordList = testWordList(1:2);
            elseif strcmp(type,'FORCED_CHOICE_0ALT'),  %0ALT=RECOGNITION, cut out the empty words from the list & remap the targetWord
                %testWordList = {upper(testWordList(1:3))};
                testWordList = testWordList(1:3);  %[seen], [unseen], [test word]
                fcORrecog    = 'R';
            end
            
            astB='';astA='';
            if     (asteriskType==AST_BEFORE) astB='*';
            elseif (asteriskType==AST_AFTER)  astA='*';
            elseif (asteriskType==RECOG_FOIL) astA='_f';  end
            if     (responseCorrect == 0) resultStr = sprintf('%sE%s',astB,astA);
            elseif (responseCorrect == 1) resultStr = sprintf('%sC%s',astB,astA);
            else                          resultStr = sprintf('%sS%s',astB,astA);  end
            
            isTest              = 1;
            msTextStart         = mstime;
            msDuration          = RT;
            textAbrev           = fcORrecog;
            textStr             = targetWord;
            index=index+1;
            
            
        case {'FREE_RECALL_START'}
            %- added free-recall to the end of each block starting with NIH016
            %
            textStr = 'FREE RECALL';
            
            xTOT=textscan(thisLine,'%f%d%s%d'); % grab the block number
            annBlock            = xTOT{4};
            msStartFR           = mstime;
            
            msCrossStart        = mstime;
            msTextStart         = mstime;
            eventCount          = eventCount+1; %- free recall prompt is an event, even if no words are spoken
            textAbrev           = 'FR';
            index=index+1;
            
            indexFRstart        = index;
            
            
            %- create an updated LST file with both asterisk and non-asterisk words (before NIH030 the list only contained asterisk words)
            if UPDATE_LST_FilE,
                lstFile   = fullfile(sessionDir,sprintf('BLOCK_%d.lst',annBlock));
                lstFileOG = fullfile(sessionDir,sprintf('BLOCK_%d_original.lst',annBlock));
                %if ~exist(lstFileOG,'file') & exist(lstFile,'file'), copyfile(lstFile,lstFileOG,'f'); end  % make a copy of the original (if a copy hasn't been made yet)
                
                fidLST = fopen(lstFile,'w');
                for iW=1:length(blockWordList),
                    cnt = fprintf(fidLST,'%s\n',blockWordList{iW});
                end
                fclose(fidLST);
            end
            
            
            %- initialize varibles for storing free recall info
            frWords = {};
            frTimes = [];
            frIsCor = [];
            
            
            %- initialize counts with nan; this is the value that will populate events file if no ann file exists
            isFreeRecall = 1;
            annotateFRsaid = nan;  annotateFRastr = nan;  annotateFRnone = nan;
            reportedFRsaid = nan;  reportedFRcorr = nan;
            
            blkWordSaid    = zeros(size(blockWordList));
            blkWordSaidCnt = blkWordSaid;
            
            
            % go through annotation file and get all the recalls here.
            annFileName  = sprintf('BLOCK_%d.ann',annBlock);
            annFile      = fullfile(sessionDir,annFileName);
            if ~exist(annFile,'file'),
                if MISSING_ANN == 0,
                    fprintf('\n >>> %s (and possibly others) were not found in %s',annFileName,sessionDir);
                end
                MISSING_ANN = MISSING_ANN + 1;
                resultStr = sprintf('ANN: no ann file found');
            
            else
                %- ann file present... process it
                
                fid2 = fopen(annFile,'r');
                if fseek(fid2,1,'bof')==-1 %annotation file is empty
                    fprintf('\n%s is empty',annFile); keyboard;
                else
                    fseek(fid2,0,'bof');
                    while true
                        tmpAnnLine=fgetl(fid2);
                        if ~ischar(tmpAnnLine);      break;    end
                        if numel(tmpAnnLine)==0;     continue; end
                        if strcmp(tmpAnnLine(1),'#');continue; end %- advance past comments and empty lines
                        
                        x2=textscan(tmpAnnLine,'%f%f%s');
                        thisRT = round(x2{1});
                        thisWordNum = x2{2};
                        thisRecWord = x2{3}{1};
                        
                        %- which words from this block's encoding section were said (asterisk or nones)?
                        %-    go back and tag those encoding events as being subsequently recalled
                        %-    (if from a prior list don't tag it)
                        isCorFR = 0;
                        iBlockWordNorm = find(strcmp(thisRecWord,blockWordList));
                        iBlockWordLow  = find(strcmp(lower(thisRecWord),lower(blockWordList)));
                        if length(iBlockWordNorm)<length(iBlockWordLow), fprintf('\n Weird... talk to JW. NIH030 requied "lower", but others dont'); keyboard; end
                        iBlockWord = iBlockWordNorm;
                        if length(iBlockWord)>0,
                            blkWordSaid(iBlockWord)    = 1;
                            blkWordSaidCnt(iBlockWord) = blkWordSaidCnt(iBlockWord)+1;
                            if blockWordType(iBlockWord)<3, isCorFR = 1; end
                        end
                        
                        frWords{end+1} = thisRecWord;
                        frTimes(end+1) = thisRT+mstime;
                        frIsCor(end+1) = isCorFR;
                    end
                end
                fclose(fid2);
                
                %- following lines should be valid even if ann file is empty
                annotateFRsaid = length(unique(frWords)) - sum(strcmp(unique(frWords),'<>'));  %- dont count vocalizations
                annotateFRastr = sum(blkWordSaid(find(blockWordType<3)));
                annotateFRnone = sum(blkWordSaid(find(blockWordType==3)));
                
                
                resultStr = sprintf('ANN: %d said, %d corr',annotateFRsaid,annotateFRastr);
                
            end
            
            
            
        case {'FREE_RECALL_STOP'}
%             xTOT=textscan(thisLine,'%f%d%s%d%d%d');
%             newBlock            = xTOT{4};
%             numSaid             = xTOT{5};
%             RT                  = xTOT{6};
%             
%             if (isempty(numSaid)) responseCorrect = nan; resultStr = 'n/a';  else responseCorrect = numSaid;  resultStr = sprintf('%d',numSaid);  end
%             
%             %update event created with free-recall-start
%             events(indexFRstart).resultStr       =  resultStr;                     %apply this to FREE_RECALL_START
%             events(indexFRstart).responseCorrect =  double(responseCorrect);       %apply this to FREE_RECALL_START
%             events(indexFRstart).msDuration      =  mstime - events(indexFRstart).mstime; %apply this to FREE_RECALL_START
            
            
        case {'SUMMARY_BLOCK'}
            %- 3 options:  (1) no SUMMARY_BLOCK and no free recall report [NIH014-017],  
            %              (2) just a single number [NIH018-NIH020],      > 1380206994202	0	SUMMARY_BLOCK	All: 6/6 (100.0%);	 *BEFORE: 2/2;	 *AFTER: 1/1;	 *NONE: 3/3;	 FREE-RECALL: 4
            %              (3) or number said + X/X correct [>=NIH021]    > 1383944633284	0	SUMMARY_BLOCK	All: 22/31 [+1skip]; *BEFORE: 4/4 [+0];	 *AFTER: 3/3 [+1];	 *NONE: 6/12 [+0];	 FOIL: 9/12 [+0];	 FREE-RECALL: 4(said) 1/8(corr)
            trimStr = thisLine(strfind(thisLine,'FREE-RECALL:'):end);
            
            if strfind(trimStr,'(said)'),
                xTOT=textscan(trimStr,'%s%d%s %d%c%d%s');
                reportedFRsaid = xTOT{2};
                reportedFRcorr = xTOT{4};
            elseif length(trimStr)>0,
                xTOT=textscan(trimStr,'%s%d');
                reportedFRsaid = xTOT{2};
                reportedFRcorr = xTOT{2}; %- didn't have an opportunity to report # correct, so just set this equal to number said
            end
            events(indexFRstart).FRreportedCounts = [reportedFRsaid reportedFRcorr];
            %events(indexFRstart).FRsummary(3:4)   = [reportedFRsaid reportedFRcorr]; 
                
        case {'BLANK'}
            events(index).msDuration = mstime - events(index).mstime;  % not accurate text duration when FEEDBACK_TRIAL is blanked for 500 ms and not recorded in session log (but is in video.vidlog)
            
            
        case {'EXTEND_CHOICE', 'FEEDBACK_TRIAL', 'BLANK_FB'}
            % feedback to user, don't bother logging as event
            % ... but when FEEDBACK_TRIAL is ommitted user actually gets additional 500 ms blank time before "BLANK" starts in session log (circa attnTask_v2.9e and earlier)
            % ... with v2.9e the additional blank time is labeled 'BLANK_FB'
        case {'START', 'PROB', 'STOP'}
            % math problems.  don't look at physio and don't log events
        case {'B','SESSION_PARAMS','SESSION_PARAMS1','SESSION_PARAMS2','SESSION_PARAMS3','SESSION_PARAMS4',...
                'SESS_END', 'SESS_DURATION', 'SESS_DURATION_ACTIVE', 'SESS_DURATION_TOTAL',...
                'SUMMARY_TOTAL','SUMMARY_PRCNT','SUMMARY_PRCNT_A','SUMMARY_PRCNT_B','SUMMARY_EXCELL','E'}
            % experimenter feedback. do nothing
        otherwise
            if strncmp(type,'FEEDBACK_FREE_RECALL',20),
                %fprintf('what up')
                %do something
            else
                fprintf('warning: session.log entry not parsed: %s\n', type)
            end
    end
    
    
    %- asign values to events array
    if index>length(events),
        
        %keyboard
        if newBlock ~= block,
            msBlockStart    = mstime ;
            block           = newBlock ;
            if ~isnan(newBlock),
                blockCount      = blockCount+1;
            end
        end
        
        %- create dummy event structure that is upddated below based on type
        clear thisEvent
        thisEvent.experiment        = experiment  ;
        thisEvent.subject           = subject     ;
        thisEvent.sessionName       = sessionName ;
        thisEvent.sessionNum        = sessionNum  ;   % store in state var so all events are assigned a sessionNum  %% JW updated 2/2015
        thisEvent.block             = double(block) ; % store in state var so all events are assigned a block
        thisEvent.type              = type        ;
        thisEvent.msoffset          = msoffset    ;
        thisEvent.mstime            = mstime      ;
        thisEvent.mstimeEnd         = mstime + msDuration ;
        thisEvent.msDuration        = msDuration  ;   %- this ms time to following blank time
        
        %- event identity
        thisEvent.isSample          = isSample        ;   %- 1 or 0
        thisEvent.isTest            = isTest          ;   %- 1 or 0
        thisEvent.isCross	        = isCross         ;   %- 1 for encoding cross, 2 for test cross, 0 for everything else
        thisEvent.isAsterisk        = isAsterisk      ;   %- 1 for *before, 2 for *after, 0 for everything else
        thisEvent.asteriskType      = asteriskType    ;   %- applies to sample and test; (1=before, 2=after, 3=none, -1=foil, -999=n/a)
        thisEvent.sampleListIndex   = sampleListIndex ;   %- serial position of sample (if test, this is the position of the sample that the test matches)
        thisEvent.testListIndex     = testListIndex   ;   %- serial position of test
        
        %- event counters
        thisEvent.blockCount        = blockCount  ;
        thisEvent.eventCount        = eventCount  ;   %- increments for + or word, depending on task version.  Used to link events for sampleCount and testCount
        thisEvent.sampleCount       = sampleCount ;   %- set to nan here... updated after all events are created so same count is applied to linked events (e.g., +,*,word)
        thisEvent.testCount         = testCount   ;   %- set to nan here... updated after all events are created so same count is applied to linked events (e.g., +,*,word)
        
        %- test/response characteristics
        thisEvent.targetLoc         = targetLoc   ;
        thisEvent.responseLoc       = responseLoc ;
        thisEvent.responseCorrect   = double(responseCorrect) ;  %- 0-error, 1=correct, -1=skipped, -999=n/a    % force double so NaN's can be found using bracket notations (e.g., isnan([events.responseCorrect])
        thisEvent.RT                = RT          ;
        thisEvent.freelyRecalled    = freelyRecalled ;  %
        
        %- strings
        thisEvent.textAbrev         = textAbrev   ;    %- encoded word or target word (depending on event)
        thisEvent.textStr           = textStr     ;    %- encoded word or target word (depending on event)
        thisEvent.encodedWord       = encodedWord ;
        thisEvent.targetWord        = targetWord  ;
        thisEvent.testWordList      = testWordList ;   %- left/right/up/down... words presented during forced choice
        thisEvent.resultStr         = resultStr   ;
        
        %- timing relative to local time points
        thisEvent.msSessStart       = msSessStart  ;
        thisEvent.msBlockStart      = msBlockStart ;
        
        
        %- free recall event: for now just a special single event with a list attached
        thisEvent.isFreeRecall      = isFreeRecall ;
        if isFreeRecall==0, frWords = {}; frTimes=[]; end
        thisEvent.FRwordList        = frWords;
        thisEvent.FRwordTimes       = frTimes;
        thisEvent.FRannotateCounts  = [annotateFRsaid annotateFRastr annotateFRnone];
        thisEvent.FRreportedCounts  = [reportedFRsaid reportedFRcorr];
        %thisEvent.FRsummary         = [sessionNum block reportedFRsaid reportedFRcorr recordedFRsaid recordedFRastr recordedFRnone];
        
        %- if this is a test, propogate the result to the encoding event (if foil for recogition sampleListIndex==-1 and don't propogate
        if (testListIndex>=0 & isTest==1 & sampleListIndex>=0)
            iSrc = find([events.sampleListIndex]==sampleListIndex & [events.block]==block & [events.isSample]==1);
            events(iSrc).responseCorrect = double(responseCorrect) ;  % need to force double here so NaN's can be found using bracket notations (e.g., isnan([event%%%s.responseCorrect])
            events(iSrc).resultStr       = resultStr ;
            events(iSrc).RT              = RT ; %propogate the reaction time back to the samples so sample events can easily be sorted by reaction time
        end
        
        %- if free recall is annotated, propogate recall results to the encoding and test events (only events associated with ast and none words, not foils)
        if (isFreeRecall==1 & ~isnan(annotateFRsaid) & length(blockWordList)>0),
            cleanFRlist = unique(frWords);
            %keyboard
            
            for iW = 1:length(blockWordList), %blockWordList contains all asterisk and non-asterisk words from encoding period
                thisBword = blockWordList{iW};
                % thisEvent.freelyRecalled    = freelyRecalled ;  % %- (nan)-FR annotation not processed, or not an encoded word (ast or non-ast).  0=not said during FR, 1=spoken.  Applies to encoding and recog test events.
                if sum(strcmp(thisBword,cleanFRlist))>0, freelyRecalled = 1; else freelyRecalled = 0; end
                
                iSrc = find([events.block]==block & strcmp({events.encodedWord},thisBword) & [events.isSample]==1);
                events(iSrc).freelyRecalled = freelyRecalled;
                iSrc = find([events.block]==block & strcmp({events.targetWord},thisBword) & [events.isTest]==1);
                if length(iSrc)==1, events(iSrc).freelyRecalled = freelyRecalled; 
                else fprintf('\nWarning: missing a test for %s in block %d (OK if not all non-ast were tested)',thisBword,block);  end
            end
            %iSrc = find([events.sampleListIndex]==sampleListIndex & [events.block]==block & [events.isSample]==1);
            %events(iSrc).responseCorrect = double(responseCorrect) ;  % need to force double here so NaN's can be found using bracket notations (e.g., isnan([events.responseCorrect])
            %events(iSrc).resultStr       = resultStr ;
            %events(iSrc).RT              = RT ; %propogate the reaction time back to the samples so sample events can easily be sorted by reaction time
        end
        
        if (index==1)
            events        = thisEvent; %- before events defined must convert to structure
        else
            events(index) = thisEvent;
        end
    end
    
end
fclose(fid);  % close session.log


%%- identify all members of the "metaEvent" (e.g., +, *, and Word) and make sure their fields are consistent
sampleCount = priorSampleCount;
testCount   = priorTestCount;
for evCnt=min([events.eventCount]):max([events.eventCount]),
    
    %- find events with common event count --> the meta events
    iEvCnt = find([events.eventCount]==evCnt);
    
    %- set sample counter and test counter for this meta-event
    if sum([events(iEvCnt).isSample])>0, sampleCount = sampleCount+1; isSamp = sampleCount; else isSamp = nan; end
    if sum([events(iEvCnt).isTest]  )>0, testCount   = testCount+1  ; isTest = testCount;   else isTest = nan; end
    
    %- determine correct resopnse for this meta-event (whether encoding or test)
    thisRespCorr = unique([events(iEvCnt).responseCorrect]);
    thisRespCorr = thisRespCorr( find( isfinite(thisRespCorr) ) );
    if length(thisRespCorr) == 0, thisRespCorr = nan;
    elseif length(thisRespCorr) > 1, fprintf('warning: more than one response type for linked events'); disp(thisRespCorr); keyboard; end
    
    %- determine response time (RT) for this meta-event (whether encoding or test)
    thisRT = unique([events(iEvCnt).RT]);
    thisRT = thisRT( find( thisRT~=-999 & isfinite(thisRT) ) );
    if length(thisRT) == 0, thisRT = -999;
    elseif length(thisRT) > 1, fprintf('warning: more than one valid RT for linked events'); disp(thisRT); keyboard; end
    
    %- determine asterisk type for this meta-event (before, after, or none)
    thisAsterisk = unique([events(iEvCnt).asteriskType]);
    thisAsterisk = thisAsterisk( find( thisAsterisk~=-999 ) );
    if length(thisAsterisk) == 0, thisAsterisk = -999;
    elseif length(thisAsterisk) > 1, fprintf('warning: more than one asterisk type for linked events'); disp(thisAsterisk); keyboard; end
    
    %- determine whether sample or test text is present, and if so, when
    thisMsTextOn = nan;    thisMsTextOff = nan;
    iText = find([events(iEvCnt).isSample]==1 | [events(iEvCnt).isTest]==1);
    if length(iText)==1,
        thisMsTextOn  = events(iEvCnt(iText)).mstime;
        thisMsTextOff = events(iEvCnt(iText)).mstime+events(iEvCnt(iText)).msDuration;   %- not accurate text duration for test events because session.log doesn't record 500 ms blank when FEEDBACK is ommitted -- oops!
    elseif length(iText) > 1, fprintf('warning: more than one text event identified for linked events'); disp(iText); keyboard; end
    
    %- determine whether asterisk is present, and if so, when
    thisMsAsteriskOn = nan;   thisMsAsteriskOff = nan;
    iAsterisk = find([events(iEvCnt).isAsterisk]>0);
    if length(iAsterisk)==1,
        thisMsAsteriskOn  = events(iEvCnt(iAsterisk)).mstime;
        thisMsAsteriskOff = events(iEvCnt(iAsterisk)).mstime+events(iEvCnt(iAsterisk)).msDuration;
    elseif length(iAsterisk) > 1, fprintf('warning: more than one asterisk identified for linked events'); disp(iAsterisk); keyboard; end
    
    %- determine whether fixation cross is present... if so, when
    thisMsCrossOn = nan;  thisMsCrossOff = nan;
    iCross = find([events(iEvCnt).isCross]>0);
    if length(iCross)==1,
        thisMsCrossOn  = events(iEvCnt(iCross)).mstime;
        thisMsCrossOff = events(iEvCnt(iCross)).mstime+events(iEvCnt(iCross)).msDuration;
    elseif length(iCross) > 1, fprintf('warning: more than one cross type for linked events'); disp(iCross); keyboard; end
    
    %-determine time points usefull for plotting and alignment.
    thisMsMetaEventStart = min([events(iEvCnt).mstime]); % catches start of non-text events too, like free-recall-start
    thisMsMetaEventEnd   = max([events(iEvCnt).mstime]+[events(iEvCnt).msDuration]);
    if max(iEvCnt)<length(events), thisMsMetaEventNext  = events(max(iEvCnt)+1).mstime;
    else                           thisMsMetaEventNext  = thisMsMetaEventEnd; end
    
    
    for iE = iEvCnt,
        events(iE).sampleCount     = isSamp;
        events(iE).testCount       = isTest;
        events(iE).responseCorrect = thisRespCorr;
        events(iE).RT              = thisRT;
        events(iE).asteriskType    = thisAsterisk;
        
        events(iE).msTextStart     = thisMsTextOn;       %- this corrects text start assignment for crosses that appeared before text
        events(iE).msTextStop      = thisMsTextOff;      %-
        events(iE).msAsteriskStart = thisMsAsteriskOn;   %- timing of asterisk onset in this meta-event.   if no asterisk, will be nan
        events(iE).msAsteriskStop  = thisMsAsteriskOff;  %- timing of asterisk offset in this meta-event.  if no asterisk, will be nan
        events(iE).msCrossStart    = thisMsCrossOn;      %- timing of cross onset in this meta-event.      if no cross, will be nan
        events(iE).msCrossStop     = thisMsCrossOff;     %- timing of cross offset in this meta-event.     if no cross, will be nan
        
        events(iE).msMetaEventStart = thisMsMetaEventStart;   %- start of meta event
        events(iE).msMetaEventEnd   = thisMsMetaEventEnd;     %- end of meta event
        events(iE).msMetaEventNext  = thisMsMetaEventNext;    %- beginning of next meta event
    end
end


%%- create asteriskStr entry so easy to decipher asterisk condition
for evCnt=1:length(events),
    thisAsterisk = events(evCnt).asteriskType;
    
    switch thisAsterisk,
        case 1,     thisAstriskStr = '*before';
        case 2,     thisAstriskStr = '*after';
        case 3,     thisAstriskStr = '*none';
        case 4,     thisAstriskStr = 'foil';
        case -999,  thisAstriskStr = 'n/a';
        otherwise,  fprintf('warning: unexpected asteriskType entry'); keyboard;
    end
    
    events(evCnt).asteriskStr = thisAstriskStr;
    
end


%%- only should be executed when running as script (not as function)
if length(eventFile)>0,
    fprintf('\nrunning jwAttnTaskEvents directly: \n --> extracted %d events to %s\n', length(events), sessionDir);
    save(eventFile,'events');
    
    
    %- create matrix with free recall data
    iFR = find([events.isFreeRecall]==1);
    DcolStr = {'sessionNum' 'block'  'rep.numWordSaid' 'rep.numAstrSaid' 'ann.numWordSaid' 'ann.numAstrSaid' 'ann.numNoneSaid'};
    Dall=[[events(iFR).sessionNum]' [events(iFR).block]' double(cell2mat({events(iFR).FRreportedCounts}')) double(cell2mat({events(iFR).FRannotateCounts}'))]; %use double otherwise converts to int32 and nans are lost
    Dall
    
    %- recognition and recall counts
    cntAstrRec1    = length(find([events.isSample]==1 & [events.responseCorrect]==1 & [events.asteriskType]<3));  %- asteriskType = applies to sample and test; (1=before, 2=after, 3=none, -1=foil, -999=n/a)
    cntAstrRec0    = length(find([events.isSample]==1 & [events.responseCorrect]==0 & [events.asteriskType]<3));
    cntAstrFRnan   = length(find([events.isSample]==1 & isnan([events.freelyRecalled])  & [events.asteriskType]<3));
    cntAstrFR1     = length(find([events.isSample]==1 & [events.freelyRecalled]==1  & [events.asteriskType]<3));  %- asteriskType = applies to sample and test; (1=before, 2=after, 3=none, -1=foil, -999=n/a)
    cntAstrFR0     = length(find([events.isSample]==1 & [events.freelyRecalled]==0  & [events.asteriskType]<3));
    cntAstrFR1Rec1 = length(find([events.isSample]==1 & [events.freelyRecalled]==1  & [events.responseCorrect]==1 & [events.asteriskType]<3));  %- asteriskType = applies to sample and test; (1=before, 2=after, 3=none, -1=foil, -999=n/a)
    cntAstrFR1Rec0 = length(find([events.isSample]==1 & [events.freelyRecalled]==1  & [events.responseCorrect]==0 & [events.asteriskType]<3));
    cntAstrFR0Rec1 = length(find([events.isSample]==1 & [events.freelyRecalled]==0  & [events.responseCorrect]==1 & [events.asteriskType]<3));  %- asteriskType = applies to sample and test; (1=before, 2=after, 3=none, -1=foil, -999=n/a)
    cntAstrFR0Rec0 = length(find([events.isSample]==1 & [events.freelyRecalled]==0  & [events.responseCorrect]==0 & [events.asteriskType]<3));
    cntNoneFR1  = length(find([events.isSample]==1 & [events.freelyRecalled]==1  & [events.asteriskType]==3));  %- asteriskType = applies to sample and test; (1=before, 2=after, 3=none, -1=foil, -999=n/a)
    cntNoneFR0  = length(find([events.isSample]==1 & [events.freelyRecalled]==0  & [events.asteriskType]==3));
    
    
end
