function events=RAM_PAL_CreateTASKEvents(subject,expDir,session,sessionDir,forceSESSION, startingElec)
%
% FUNCTION:
%  extractPA3events.m
%
% DESCRIPTION:
%  extracts the events associated with pa3.
%
% INPUTS:
%  subject.......... 'UP020'
%  expDir........... '/data/eeg/UP020/behavioral/pa3/'
%  session.......... 0
%  forceSESSIONS.... [optional] 1 = forces session to this number
%  startingElec..... [optional] for systems with recording systems that
%                    start at 0, enter 0. Defaults to 1.
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
% ISTRIGGER FIELD: Depends on feedback condition
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


clear global
global SUBJECT SESSION STIMTRIAL STIMTYPE STIMLOC events versionNum stimParams currParamSet
SUBJECT = subject;
SESSION = session;
STIMTYPE='';
STIMTRIAL=nan;
currParamSet = 0;
versionNum = '';
%thisSessDir = sprintf('session_%d',SESSION);  % 
thisSessDir = sessionDir;  % NINDS allows for text suffix to session folder (e.g. session_1a, for a broken up session)
sessFile    = fullfile(expDir,thisSessDir,'session.log');

fid = fopen(sessFile,'r');
if fid==-1
    fprintf('session %d..no session.log file found.\n',SESSION);
    fprintf('EXITING\n\n');
    return
end

% you can change the session
if exist('forceSESSION','var') && ~isempty(forceSESSION)
    SESSION=forceSESSION;
end
if ~exist('startingElec','var') || isempty(startingElec)
    startingElec = 1;
end

% get experimental variables
% NOUNPOOL  = getNounPool_local(expDir);

evCounter    = 0;
trialCounter = 0;
events       = [];

while true
    thisLine = fgetl(fid);
    if ~ischar(thisLine);return;end
    
    % get the third string before the underscore
    xTOT=textscan(thisLine,'%f\t%f\t%s');
    if isempty(xTOT{1})
        xTOT= textscan(thisLine, '(%fL, %f)\t%*s\t%s','delimiter','\t');
    end
    thisTYPE = xTOT{3}{1};
    thisMSTIME  = xTOT{1}(1);
    thisMSOFF   = xTOT{2};
    
    % based on the type write different fields for this event
    switch upper(thisTYPE)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case {'E','B','STIM_ON','MATH_START','MATH_END','REC_END','FORCED_BREAK'}
            % make the event
            evCounter = evCounter + 1;
            mkNewEvent_local(evCounter,thisMSTIME,thisMSOFF);
            appendNewEvent_local(evCounter,'type',thisTYPE);
            if strcmp(thisTYPE,'STIM_ON')
                appendNewEvent_local(evCounter,'serialpos',pairCounterThisList);
            end
            if strcmp(thisTYPE,'E') && trialCounter>0
                 trialCounter = trialCounter -1 ;
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'STIM_PARAMS'
            %keyboard
            x=textscan(thisLine,'%f%f%s%d%s%s%s%s%s%f');
            ParamSet = x{4}+1;
            AnodeStr = x{6}{1};
            CathodeStr = x{8}{1};
                
            [AnodeNum, AnodeTag, CathodeNum, CathodeTag] = getStimParams(expDir, subject, AnodeStr, CathodeStr, startingElec);

            stimParams(ParamSet).Anode = AnodeNum;
            stimParams(ParamSet).AnodeTag = AnodeTag;
            stimParams(ParamSet).Cathode = CathodeNum;
            stimParams(ParamSet).CathodeTag = CathodeTag;
            stimParams(ParamSet).Amp = x{10};        
        case 'SESS_START'
            x=textscan(thisLine,'%f%f%s%d%s%s');
            thisSess  = x{4};
            if (thisSess-1)~=session
              %error('sessions dont match');
              fprintf('\nWARNING: SESS_START doesnt match session folder'); keyboard;
            end
            versionNum = x{6}{1};
            evCounter = evCounter + 1;
            mkNewEvent_local(evCounter,x{1},x{2});  
            appendNewEvent_local(evCounter,'type',x{3}{1}); 
            trialCounter = false;
        case {'TEST_START','STUDY_START'}
            
            % start/increment counters
            pairCounterThisList  = 0;
            probeCounterThisList = 0;
            if strcmp(thisTYPE,'STUDY_START') && trialCounter~=false
                trialCounter = trialCounter + 1;
            end
            
%             if trialCounter>numTrials
%                 error('too many trials')
%             end
            
            % Extract more information from this line
            x=textscan(thisLine,'%f%f%s%s%s%s');
            if isempty(x{1})
                x = textscan(thisLine,'(%fL, %f)\t%*s\t%s%s%s%s','delimiter','\t');
            end
            thisTrial = str2double(lastPart(x{4}{1}))+1;
            if isempty(x{6})
                STIMTYPE = upper(lastPart(x{5}{1}));
            else
                STIMTYPE = upper(x{6}{1});          
            end

            STIMTRIAL = ~strcmp(STIMTYPE,'NONE');
            
            if STIMTRIAL
                currParamSet = 1;
            else
                currParamSet = 0;
            end
            
            if thisTrial~=trialCounter && trialCounter~=false
                error('trials out of order?')
            elseif trialCounter==false
                trialCounter=thisTrial;
            end
            
            % make the event
            evCounter = evCounter + 1;
            mkNewEvent_local(evCounter,thisMSTIME,thisMSOFF)
            appendNewEvent_local(evCounter,'type',thisTYPE);
            appendNewEvent_local(evCounter,'list',trialCounter);

            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
        case {'STUDY_ORIENT'}
            evCounter = evCounter+ 1;
            mkNewEvent_local(evCounter, thisMSTIME, thisMSOFF);
            
            
            x = textscan(thisLine, '%f%f%s%d%s%s');
            

            pairCounterThisList = pairCounterThisList + 1;
            serialPos = x{4}+1;

            
            
            
            trialNum = str2double(lastPart(x{5}{1}))+1;
            isStim = strcmp(x{6}{1},'STIM');
            
            if trialNum~=trialCounter
                error('trials out of order?')
            end
            
            if serialPos~=pairCounterThisList
                error('Pairs out of order?')
            end
            
            appendNewEvent_local(evCounter,'type',thisTYPE);
            appendNewEvent_local(evCounter,'serialpos',pairCounterThisList);
            appendNewEvent_local(evCounter,'list',trialCounter)
            appendNewEvent_local(evCounter,'isStim',isStim);
            
        case {'TEST_ORIENT'}
            evCounter = evCounter+ 1;
            mkNewEvent_local(evCounter, thisMSTIME, thisMSOFF);
            
            
            x = textscan(thisLine, '%f%f%s%d%s%s%s');

            probePos = x{4}+1;
            probeCounterThisList = probeCounterThisList + 1; 
            
            
            serialPos = str2double(lastPart(x{5}{1}))+1;
            trialNum = str2double(lastPart(x{6}{1}))+1;
            isStim = strcmp(x{7}{1},'STIM');
            
            if trialNum~=trialCounter
                error('trials out of order?')
            end
            
            if probePos~=probeCounterThisList 
                error('Pairs out of order?')
            end
            
            appendNewEvent_local(evCounter,'type',thisTYPE);
            appendNewEvent_local(evCounter,'serialpos',pairCounterThisList);
            appendNewEvent_local(evCounter,'probepos',probeCounterThisList);
            appendNewEvent_local(evCounter,'list',trialCounter)
            appendNewEvent_local(evCounter,'isStim',isStim);
            
                        
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'STUDY_PAIR'
            % make the event
            evCounter = evCounter + 1;
            mkNewEvent_local(evCounter,thisMSTIME,thisMSOFF)
            
            % read the data again to extract the trial number and words
            x=textscan(thisLine,'%f%f%s%d%s%s%s%s');
            
            serialPos = x{4}+1;
            trialNum = str2double(lastPart(x{5}{1}))+1;
            word1 = lastPart(x{6}{1});
            word2 = lastPart(x{7}{1});
            isStim = strcmp(x{8}{1},'STIM');
            
            % check if the trial number is what we expect
            if trialNum~=trialCounter
                error('trials out of order?')
            end
            
            if serialPos~=pairCounterThisList
                error('Pairs out of order?')
            end
            
            % now append
            appendNewEvent_local(evCounter,'serialpos',pairCounterThisList);
            appendNewEvent_local(evCounter,'study_1',word1);
            appendNewEvent_local(evCounter,'study_2',word2);
            appendNewEvent_local(evCounter,'type',thisTYPE);
            appendNewEvent_local(evCounter,'list',trialNum);
            appendNewEvent_local(evCounter,'isStim',isStim);
            
            % go back and fill in this events oreient
            thisPair = [events.list]==trialNum & ...
                [events.serialpos]==serialPos;
            thisOrient = thisPair & strcmp({events.type},'STUDY_ORIENT');
            appendNewEvent_local(thisOrient,'study_1',word1);
            appendNewEvent_local(thisOrient,'study_2',word2);
            
            % if there was a stim, fill that in too
            thisStim = thisPair & strcmp({events.type},'STIM_ON');
            if any(thisStim)
                appendNewEvent_local(thisStim,'study_1',word_1);
                appendNewEvent_local(thisStim,'study_2',word_2);
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
        case 'TEST_PROBE'
            % make the event
            evCounter = evCounter + 1;
            mkNewEvent_local(evCounter,thisMSTIME,thisMSOFF)
            
            % read the data again to extract the trial number and words
            x=textscan(thisLine,'%f%f%s%d%s%s%s%s%s%s');
            
            probePos = x{4}+1;
            serialPos = str2double(lastPart(x{5}{1}))+1;
            trialNum = str2double(lastPart(x{6}{1}))+1;
            probe = lastPart(x{7}{1});
            expecting = lastPart(x{8}{1});
            cue_direction = str2double(lastPart(x{9}{1}));
            isStim = strcmp(x{10}{1},'STIM');
            
            if trialNum~=trialCounter
                error('trials out of order?');
            end
            
            appendNewEvent_local(evCounter,'type','TEST_PROBE');
            appendNewEvent_local(evCounter,'probepos',probePos);
            appendNewEvent_local(evCounter,'serialpos',serialPos);
            appendNewEvent_local(evCounter,'list',trialNum);
            appendNewEvent_local(evCounter,'probe_word',probe);
            appendNewEvent_local(evCounter,'expecting_word',expecting);
            appendNewEvent_local(evCounter,'cue_direction',cue_direction);
            appendNewEvent_local(evCounter,'isStim',isStim);
            
            
            
            % go back and fill in this events test_oreient
            thisPair = [events.list]==trialNum & ...
                ([events.serialpos]==serialPos | ...
                 [events.probepos]==probePos);
            thisOrient = thisPair & strcmp({events.type},'TEST_ORIENT');
            appendNewEvent_local(thisOrient,'probepos',probePos);
            appendNewEvent_local(thisOrient,'serialpos',serialPos);
            appendNewEvent_local(thisOrient,'probe_word',probe);
            appendNewEvent_local(thisOrient,'expecting_word',expecting);
            appendNewEvent_local(thisOrient,'cue_direction',cue_direction);
            
            % also fill in the study_orient with the probepos
            thisOrient = thisPair & strcmp({events.type},'STUDY_ORIENT');
            appendNewEvent_local(thisOrient,'probepos',probePos);
            
            % also fill in the study_pair with the probepos
            thisStudy = thisPair & strcmp({events.type},'STUDY_PAIR');
            appendNewEvent_local(thisStudy,'probepos',probePos);
            
            % if there was a stim, fill that in too
            thisStim = thisPair & strcmp({events.type},'STIM_ON');
            if any(thisStim)
                appendNewEvent_local(thisStim,'probepos',probePos);
                appendNewEvent_local(thisStim,'serialpos',serialPos);
                appendNewEvent_local(thisStim,'probe_word',probe);
                appendNewEvent_local(thisStim,'expecting_word',expecting);
                appendNewEvent_local(thisStim,'cue_direction',cue_direction);
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'REC_START'
            evCounter = evCounter + 1 ;
            mkNewEvent_local(evCounter, thisMSTIME, thisMSOFF)
            appendNewEvent_local(evCounter, 'type', 'REC_START');
            % go through and get all the recalls here.. the
            % 'serialPos' is unchanged from the last time we got it in
            % the 'TEST_PROBE' condidtion
            annFileName  = sprintf('%d_%d.ann',trialCounter-1,probePos-1);
            annFile      = fullfile(expDir,thisSessDir,annFileName);
            if ~exist(annFile)
                error('%s was not found',annFile)
            end
            fid2=fopen(annFile,'r');
            thisRT = [];
            lastRT = -999;
            lastRecWord = -999;
            lastCorrect =  false;
            lastIsPass  =  false;
            while true
                tmpAnnLine=fgetl(fid2);
                if ~ischar(tmpAnnLine);break;end
                if numel(tmpAnnLine)==0;continue;end
                if strcmp(tmpAnnLine(1),'#');continue;end
                x2=textscan(tmpAnnLine,'%f%f%s');
                thisRT = round(x2{1});
                thisWordNum = x2{2};
                thisRecWord = x2{3}{1};
                isVOC    =  strcmpi(thisRecWord,'<>');

                
                thisRT = round(x2{1});
                thisWordNum = x2{2};            
                thisRecWord = x2{3}{1};
                correct  = strcmp(thisRecWord,expecting);
                isPass   = strcmpi(thisRecWord,'PASS');
                
                if ~isVOC
                    lastRT = thisRT;
                    lastRecWord = thisRecWord;
                    lastCorrect = correct;
                    lastIsPass  = isPass;
                end
                
                if ~correct&&~isVOC&&~isPass
                    intrusion=thisWordNum;
                else
                    intrusion=0;
                end
                
%                 if  (~isVOC && ~isPass && ~intrusion) && ...
%                         ~strcmp(NOUNPOOL{thisWordNum},thisRecWord)
%                     error('this should never happpen... something is wrong')
%                 end
                if (isPass || isVOC || intrusion) && correct
                    error('this should never happpen... something is wrong')
                end
                
                % make the event for the recalled event
                evCounter = evCounter + 1;
                mkNewEvent_local(evCounter,thisMSTIME+thisRT,20)
                appendNewEvent_local(evCounter,'type','REC_EVENT');
                appendNewEvent_local(evCounter,'list',trialCounter);
                appendNewEvent_local(evCounter,'probepos',probeCounterThisList);
                appendNewEvent_local(evCounter,'probe_word',probe);
                appendNewEvent_local(evCounter,'expecting_word',expecting);
                appendNewEvent_local(evCounter,'cue_direction',cue_direction);
                appendNewEvent_local(evCounter,'serialpos',serialPos);
                appendNewEvent_local(evCounter,'RT',thisRT);
                appendNewEvent_local(evCounter,'correct',correct);
                appendNewEvent_local(evCounter,'pass',isPass);
                appendNewEvent_local(evCounter,'vocalization',isVOC);
                appendNewEvent_local(evCounter,'intrusion',intrusion);
                appendNewEvent_local(evCounter,'resp_word',thisRecWord);
                appendNewEvent_local(evCounter,'study_1',events(thisStudy).study_1);
                appendNewEvent_local(evCounter,'study_2',events(thisStudy).study_2);
            end
            fclose(fid2);
            
            % add fields to study_pair, study_orient
            % test_probe, and test_orient
            thisPair = [events.list]==trialNum & ...
                ([events.serialpos]==serialPos | ...
                 [events.probepos]==probePos);
            theseEvents = thisPair & ...
                (strcmp({events.type},'STUDY_PAIR') | ...
                 strcmp({events.type},'STUDY_ORIENT') | ...
                 strcmp({events.type},'TEST_PROBE') | ...
                 strcmp({events.type},'TEST_ORIENT'));
            appendNewEvent_local(theseEvents,'correct',lastCorrect);
            appendNewEvent_local(theseEvents,'RT',lastRT);
            appendNewEvent_local(theseEvents,'pass',lastIsPass);
            appendNewEvent_local(theseEvents,'resp_word',lastRecWord);
                        

            
    end
end

function mkNewEvent_local(evCounter,mstime,msoffset)
global SUBJECT SESSION STIMTYPE STIMTRIAL events versionNum stimParams currParamSet

events(evCounter).subject       = SUBJECT;
events(evCounter).session       = SESSION;
events(evCounter).stimType      = STIMTYPE;
events(evCounter).stimTrial     = STIMTRIAL;
events(evCounter).type          = -999;
events(evCounter).list          = -999;
events(evCounter).serialpos     = -999;
events(evCounter).probepos      = -999;
events(evCounter).study_1       = -999;
events(evCounter).study_2       = -999;
events(evCounter).cue_direction = -999;
events(evCounter).probe_word    = -999;
events(evCounter).expecting_word = -999;
events(evCounter).resp_word     = -999;
% events(evCounter).lag           = -999;
events(evCounter).correct       = -999;
events(evCounter).intrusion     = -999;
events(evCounter).pass          = -999;
events(evCounter).vocalization  = -999;
events(evCounter).RT            = -999;
events(evCounter).mstime        = mstime;
events(evCounter).msoffset      = msoffset;
events(evCounter).isStim        = -999;
events(evCounter).expVersion    = versionNum;
if currParamSet==0
    events(evCounter).stimAnode=nan;
    events(evCounter).stimAnodeTag = '';
    events(evCounter).stimCathode=nan;
    events(evCounter).stimCathodeTag = '';
    events(evCounter).stimAmp=nan;
else
    events(evCounter).stimAnode = stimParams(currParamSet).Anode;
    events(evCounter).stimAnodeTag = stimParams(currParamSet).AnodeTag;
    events(evCounter).stimCathode = stimParams(currParamSet).Cathode;
    events(evCounter).stimCathodeTag = stimParams(currParamSet).CathodeTag;
    events(evCounter).stimAmp = stimParams(currParamSet).Amp;
end

function appendNewEvent_local(evCounter,varargin)
global events
nVar = length(varargin)/2;
for v=1:nVar
    thisVarField = varargin{2*(v-1)+1};
    thisVarData  = varargin{2*(v-1)+2};
    [events(evCounter).(thisVarField)] = deal(thisVarData);
end

function [out] = getExpInfo_local(expDir,str2get)
fid_foo1 = fopen(fullfile(expDir,'../../config.py'),'r');
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

function [words] = getNounPool_local(expDir)
fid_foo1 = fopen(fullfile(expDir,'nounpool.txt'),'r');
X=textscan(fid_foo1,'%s');
words=X{1};
fclose (fid_foo1);
if ismember(upper('pass'),words)
    error('pass is in the nounpool!')
end

function thisStr = lastPart(thisStr)
splitStr = regexp(thisStr,'_','split');
thisStr = splitStr{end};


function [AnodeNum, AnodeTag, CathodeNum, CathodeTag] = getStimParams(expDir, subject, AnodeStr, CathodeStr, startingElec)
    % Get the Tag/Num that was recorded:
    if all(isstrprop(AnodeStr,'digit')) && all(isstrprop(CathodeStr,'digit'))
        AnodeNum = str2double(AnodeStr) + (1-startingElec);
        CathodeNum = str2double(CathodeStr) + (1-startingElec);
        AnodeTag = '';
        CathodeTag = '';
        isNum = true;
        isTag = false;
    else
        AnodeTag = AnodeStr;
        CathodeTag = CathodeStr;
        AnodeNum = nan;
        CathodeNum = nan;
        isTag = true;
        isNum = false;
    end

    % Now, to assign the Tag/Num that was not recorded:

    % First, try getting the talairach structure and getting the number from there
    try
        monoTal = getBipolarSubjElecs(subject, false);
        foundTal = true;
    catch e
        foundTal = false;
        warning('could not retrieve tal struct');
    end
    
    if foundTal
        if isTag
            anodeMask = strcmp({monoTal.tagName},AnodeStr);
            cathodeMask = strcmp({monoTal.tagName},CathodeStr);
        else
            anodeMask = [monoTal.channel]==AnodeNum;
            cathodeMask = [monoTal.channel]==CathodeNum;
        end

        if any(anodeMask)
            AnodeNum = monoTal(anodeMask).channel;
            AnodeTag = monoTal(anodeMask).tagName;
        else
            warning('COULD NOT ASSIGN ANODE NUMBER. CHECK THAT STIM PARAMS ARE CORRECT');
        end

        if any(cathodeMask)
            CathodeNum = monoTal(cathodeMask).channel;
            CathodeTag = monoTal(cathodeMask).tagName;
        else
            warning('COULD NOT ASSIGN CATHODE NUMBER. CHECK THAT STIM PARAMS ARE CORRECT');
        end
    else % Otherwise, try the jacksheet
        
        jackFile    = fullfile('/data/eeg',subject,'docs','jacksheet.txt');
        subjDir = expDir(1:strfind(expDir,subject)-1);
        jackFileNIH = fullfile(subjDir,subject,'docs','jacksheetMaster.txt');  % NIH modification 
        if ~exist(jackFile,'file') & exist(jackFileNIH,'file'), 
            
            fid = fopen(jackFileNIH);
            jackOut = textscan(fid, '%d%s%s');
            fclose(fid);
            
            jackFile = fullfile(subjDir,subject,'docs','jacksheet.txt');
            fid = fopen(jackFile,'w');
            for iJack=1:length(jackOut{1}), fprintf(fid,'%d\t%s\n',jackOut{1}(iJack),jackOut{2}{iJack}); end
            fclose(fid);
        end
        if exist(jackFile,'file')
            fid = fopen(jackFile);
            jackOut = textscan(fid, '%d%s');
            nums = jackOut{1};
            tags = jackOut{2};
            if isTag
                anodeMask = strcmp(tags, AnodeStr);
                cathodeMask = strcmp(tags, CathodeStr);
            else
                anodeMask = nums==AnodeNum;
                cathodeMask = nums==CathodeNum;
            end

            if any(anodeMask)
                AnodeNum = nums(anodeMask);
                AnodeTag = tags{anodeMask};
            else
                warning('COULD NOT ASSIGN ANODE NUMBER. CHECK THAT STIM PARAMS ARE CORRECT');
            end

            if any(cathodeMask)
                CathodeNum = nums(cathodeMask);
                CathodeTag = tags{cathodeMask};
            else
                warning('COULD NOT ASSIGN CATHODE NUMBER. CHECK THAT STIM PARAMS ARE CORRECT');
            end
        else
            warning('COULD NOT GET TALAIRACH STRUCTURE OR JACKSHEET!!!!');
        end
    end


