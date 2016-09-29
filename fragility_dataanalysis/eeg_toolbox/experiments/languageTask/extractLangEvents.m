function events = extractLangEvents(subject,behDir,session)
% subject = 'Jian'
% session = 0
sessFile = fullfile(behDir,['session_' num2str(session)],'session.log');
% sessFile = '/Users/dongj3/Jian/data/dbs/NIH000/behavioral/session_0/session.log'
fid = fopen(sessFile,'r'); %if loops check to see that sessFile exists

if fid==-1
  fprintf('no session file in %s\n',sessFile);   
  fprintf('EXITING\n\n');
  return
else 
    %disp(['The session.log file is located in: '  sessFile])
end

index = 1;
while true
  thisLine = fgetl(fid);
  if ~ischar(thisLine);break;end

  xTOT=textscan(thisLine,'%f%d%s');
  mstime = xTOT{1};
  msoffset = xTOT{2};
  type = xTOT{3}{1};
  
  if ~isempty(strfind(type,'DESCRIPTION'))
      type = 'AUDIO';
  end
  switch type
      case 'B'
          xTOT=textscan(thisLine,'%f%d%s');
          events(index).experiment = 'languageTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};
          events(index).condition = xTOT{3}{1};
          events(index).rt = -999;
          events(index).sentenceIndex = -999;
          events(index).wordIndex = -999;          
          index=index+1;
          
      case 'SESS_START'
          xTOT=textscan(thisLine,'%f%d%s%d');
          sess = xTOT{4};
          if sess ~= session
              error('Input session and session.log session # mismatch.');
          end
          events(index).experiment = 'languageTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};
          events(index).condition = xTOT{3}{1};
          events(index).rt = -999;
          events(index).sentenceIndex = -999;
          events(index).wordIndex = -999;          
          index=index+1;
          
     case 'CUE'
          xTOT=textscan(thisLine,'%f%d%s');
          events(index).experiment = 'languageTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};
          events(index).condition = xTOT{3}{1};
          events(index).rt = -999;
          events(index).sentenceIndex = -999;
          events(index).wordIndex = -999;          
          index=index+1;
          
     case 'BLANK'
          xTOT=textscan(thisLine,'%f%d%s');
          events(index).experiment = 'languageTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};
          events(index).condition = xTOT{3}{1};
          events(index).rt = -999;
          events(index).sentenceIndex = -999;
          events(index).wordIndex = -999;          
          index=index+1;
	
	case 'COMPREHENSION'
          xTOT=textscan(thisLine,'%f%d%s%s%s%d%d');
          events(index).experiment = 'languageTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};
          events(index).block = -999;
          events(index).condition = lower(xTOT{4}{1});
          events(index).comprehension = xTOT{6};
          events(index).rt = xTOT{7};
          events(index).sentenceIndex = -999;
          events(index).wordIndex = -999; 
          index=index+1;

          
     case 'SESS_END'
          xTOT=textscan(thisLine,'%f%d%s');
          events(index).experiment = 'languageTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};
          events(index).condition = xTOT{3}{1};
          events(index).rt = -999;
          events(index).sentenceIndex = -999;
          events(index).wordIndex = -999;          
          index=index+1;
          
      case 'E'
          xTOT=textscan(thisLine,'%f%d%s');
          events(index).experiment = 'languageTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};
          events(index).condition = xTOT{3}{1};
          events(index).rt = -999;
          events(index).sentenceIndex = -999;
          events(index).wordIndex = -999;
          index=index+1;
      case 'AUDIO'
          
      otherwise
          %keyboard
          xTOT=textscan(thisLine,'%f%d%s%s%d%d');
          word = xTOT{4};
          events(index).experiment = 'languageTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          [trial, condition] = regexp(xTOT{3}{1},'\d','match','split');  %- split the "condition-trial" string into parts: e.g. Fable3 --> 3, Fable
          events(index).type = lower(condition{1});
          events(index).condition = lower(condition{1});
          events(index).block = str2double(trial{1});
          events(index).word = word;
          events(index).rt = -999;
          events(index).sentenceIndex = xTOT{5};
          events(index).wordIndex = xTOT{6};
          index=index+1;
  end
end

% events=reviseLangEvents(events);
% save(fullfile(behDir,['session_' num2str(session)],'events.mat'),'events');
% disp(['events.mat is saved in: '  fullfile(expDir,subject,'behavioral','languageTask',['session_' num2str(session)])]);