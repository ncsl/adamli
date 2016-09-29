function [events MATHcfg]=RAM_FR_CreateMATHEvents(subject,expDir,session,forceSESSION)
%
% FUNCTION:
%   [events MATHcfg]=RAM_FR_CreateMATHEvents(subject,expDir,session,forceSESSION)
% 
% DESCRIPTION:
%   extracts the math events associated with pyFR.
%
% INPUTS:
%   subject......... 'FR200'
%   expDir.......... '/data/eeg/FR200/behavioral/pyFR/'
%   session......... 0 = searches 'session_0' in expDir
%   forceSESSION.... [optional] 1 = forces session to this number
%
% OUTPUTS:
%   events....... the events structure
%   MATHcfg...... cfg params for mat events
%
% NOTES:
%   (1) written by jfburke on 03/2012 (john.fred.burke@gmail.com)
%
%

clear global
global SUBJECT SESSION LIST events LIST TEST ANSWER ISCORRECT RECTIME
SUBJECT     = subject;
SESSION     = session;
thisSessDir = sprintf('session_%d',SESSION);
mathFile    = fullfile(expDir,thisSessDir,'math.log');
fid=checkIfITExists(mathFile,'math.log',true);

% you can change the session
if exist('forceSESSION','var') && ~isempty(forceSESSION)
  SESSION=forceSESSION;
end

% get math CONFIG variables
MATHcfg.numVars = 3;%              = getExpInfo_local(expDir,'MATH_numVars','%s%f');
% MATHcfg.maxNum               = getExpInfo_local(expDir,'MATH_maxNum','%s%f');
% MATHcfg.minNum               = getExpInfo_local(expDir,'MATH_minNum','%s%f');
% MATHcfg.maxProbs             = getExpInfo_local(expDir,'MATH_maxProbs','%s%f');
% MATHcfg.plusAndMinus         = getExpInfo_local(expDir,'MATH_plusAndMinus','%s%s');
% MATHcfg.minDuration          = getExpInfo_local(expDir,'MATH_minDuration','%s%f');
% MATHcfg.textSize             = getExpInfo_local(expDir,'MATH_textSize','%s%f');
% MATHcfg.correctBeepDur       = getExpInfo_local(expDir,'MATH_correctBeepDur','%s%f');
% MATHcfg.correctBeepFreq      = getExpInfo_local(expDir,'MATH_correctBeepFreq','%s%f');
% MATHcfg.correctBeepRF        = getExpInfo_local(expDir,'MATH_correctBeepRF','%s%f');
% MATHcfg.correctSndFile       = getExpInfo_local(expDir,'MATH_correctSndFile','%s%s');
% MATHcfg.incorrectBeepDur     = getExpInfo_local(expDir,'MATH_incorrectBeepDur','%s%f');
% MATHcfg.incorrectBeepFreq    = getExpInfo_local(expDir,'MATH_incorrectBeepFreq','%s%f');
% MATHcfg.incorrectBeepRF      = getExpInfo_local(expDir,'MATH_incorrectBeepRF','%s%f');
% MATHcfg.incorrectSndFile     = getExpInfo_local(expDir,'MATH_incorrectSndFile','%s%s');
% MATHcfg.minDuration_Practice = getExpInfo_local(expDir,'MATH_minDuration_Practice','%s%f');

% make events
evCounter         = 0;
events            = [];
listCounter       = 0; 

while true
  thisLine = fgetl(fid);
  if ~ischar(thisLine);break;end

  % get the third string before the underscore
  xTOT=textscan(thisLine,'%f%f%s');
  thisTYPE    = xTOT{3}{1};

  % based on the type write different fields for this event
  switch upper(thisTYPE)    
   %-------------------------------------------------------------------
   case {'B','E'}
    x=textscan(thisLine,'%f%f%s%s');
    LIST       = -999;
    TEST       = -999*ones(MATHcfg.numVars,1);
    ANSWER     = -999;
    ISCORRECT  = -999;
    RECTIME    = -999;
    evCounter = evCounter + 1;
    mkNewEvent_local(evCounter,x{1},x{2});  
    appendNewEvent_local(evCounter,'type',x{3}{1});      
    %-------------------------------------------------------------------
   case {'START','STOP'}
    x=textscan(thisLine,'%f%f%s');
    evCounter = evCounter + 1;
    if strcmp(upper(thisTYPE),'START')
      listCounter = listCounter +1;
    end
    LIST       = listCounter;
    TEST       = -999*ones(MATHcfg.numVars,1);
    ANSWER     = -999;
    ISCORRECT  = -999;
    RECTIME    = -999;
    mkNewEvent_local(evCounter,x{1},x{2});  
    appendNewEvent_local(evCounter,'type',x{3}{1});      
   %-------------------------------------------------------------------
   case 'PROB'
    x=textscan(thisLine,'%f%f%s%s%s%d%d%d','delimiter','\t');
    LIST       = listCounter;
    TEST       = getTestItem_local(x{4}{1},MATHcfg.numVars);
    ANSWER     = str2double(regexprep(x{5}{1},'''',''));
    ISCORRECT  = double(x{6});
    RECTIME    = double(x{7});
    if ISCORRECT~=isequal(ANSWER,sum(TEST))
      error('should never happen')
    end
    if isnan(ANSWER); error('answer should always be a number');end
    if isnan(ISCORRECT)~=0&&isnan(ISCORRECT)~=1; error('0 or 1 only');end
    evCounter = evCounter + 1;
    mkNewEvent_local(evCounter,x{1},x{2});  
    appendNewEvent_local(evCounter,'type',x{3}{1});
   %-------------------------------------------------------------------
   otherwise
    error(sprintf('bad event type %s',thisTYPE))
  end  
end

function out = getTestItem_local(str,N);
  out = [];
  count=0;
  while true
    count=count+1;
    thisNUM = str2double(str(count));
    if ~isnan(thisNUM)
      out = cat(1,out,thisNUM);
    end
    if strcmp(str(count),'=')
      break
    end
    if count>50
      error('somehting is wrong.  avoiding an infinite loop')
    end
  end
  if size(out,1)~=N;error('wrog number of integers');end
  
%------------------------------------------------------------
function mkNewEvent_local(evCounter,mstime,msoffset)
global SUBJECT SESSION LIST events LIST TEST ANSWER ISCORRECT RECTIME

events(evCounter).subject       = SUBJECT;
events(evCounter).session       = SESSION;
events(evCounter).type          = '';
events(evCounter).list          = LIST;
events(evCounter).test          = TEST;
events(evCounter).answer        = ANSWER;
events(evCounter).iscorrect     = ISCORRECT;
events(evCounter).rectime       = RECTIME;
events(evCounter).mstime        = mstime;
events(evCounter).msoffset      = msoffset;

function fid = checkIfITExists(file,str,outputFile)
  global SUBJECT SESSION
  fid = fopen(file,'r');
  if fid==-1
    fprintf('session %d..no %s file found.\n',SESSION,str);   
    fprintf('EXITING\n\n');
    return
  end
  if outputFile
    return
  else
    fclose(fid);
  end

function appendNewEvent_local(evCounter,varargin)
global events
nVar = length(varargin)/2;
for v=1:nVar
  thisVarField = varargin{2*(v-1)+1};
  thisVarData  = varargin{2*(v-1)+2};
  events(evCounter)=setfield(events(evCounter),thisVarField,thisVarData);
end

function [out] = getExpInfo_local(expDir,str2get,val);
expDir = fullfile(expDir,'../..');
fid_foo1 = fopen(fullfile(expDir,'config.py'),'r');
while true
  thisLine = fgetl(fid_foo1);
  if ~ischar(thisLine);break;end
  if numel(thisLine)==0;continue;end
  if strcmp(thisLine(1),'#');continue;end
  possible_str=textscan(thisLine,val,'Delimiter','=');
  X = regexprep(possible_str{1}{1},' ','');
  if strcmp(X,str2get)
    out=possible_str{2};
    break
  end
end
fclose (fid_foo1);

function [X] = getNounPool_local(expDir);
%fid_foo1 = fopen(fullfile(expDir,'word-pool.txt'),'r')
[X]   = textread(fullfile(expDir,'word-pool.txt'), '%s');
%X=textread('word-pool.txt','%s');
%fclose (fid_foo1);
%if ismember(upper('pass'),X)
%  error('pass is in the nounpool!')
%end
