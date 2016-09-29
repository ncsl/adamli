%Extracts Data from attentionTask.py, organizes it in a events.m format
%that can later be analyzed for behavioral and physio data. Needs to be
%saved, e.g.  save('/Users/ellenbogenrl/Rachel/data/eeg/NIHXXX/behavioral/attentionTask/session_0/events.mat', 'events');

%For forced choice (2 words) joystick task (NIH014, NIH015, NIH016, NIH017,
%EEG001, 

function events=extractnewAttentionEventsjoy(subject,expDir,session)
% subject = 'Jian'
% session = 0
% expDir ='/Users/ellenbogenrl/Rachel/data/eeg/TEST/'
sessFile = fullfile(expDir,['session_' num2str(session)],'session.log');
% sessFile = '/Users/dongj3/Jian/data/dbs/DBS000/behavioral/session_0/session.log'
fid = fopen(sessFile,'r'); %if loops check to see that sessFile exists
if fid==-1
  fprintf('no session file in %s\n',sessFile);   
  fprintf('EXITING\n\n');
  return
else 
    disp(['The session.log file is located in: '  sessFile])
end

index = 1;
while true
  thisLine = fgetl(fid);
  if ~ischar(thisLine);return;end

  xTOT=textscan(thisLine,'%f%d%s');
  mstime = xTOT{1};
  msoffset = xTOT{2};
  type = xTOT{3}{1};
  switch type
      case 'SESS_START'
          xTOT=textscan(thisLine,'%f%d%s%d');
          events(index).experiment = 'attentionTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).block = xTOT{4};
          events(index).trial = -999;
          events(index).type=xTOT{3}{1};
          events(index).msoffset = msoffset;
          events(index).mstime = mstime;
          events(index).asterick=-999;
          events(index).text=-999;
          events(index).testTrial=-999;
          events(index).foilWord=-999;
          events(index).recognizedWordCorrect=-999;
          events(index).foilSide=-999;
          events(index).presentedWord=-999;
          events(index).RT=-999;
          index=index+1;
          
      case 'WORD_PRESENT'
          xTOT=textscan(thisLine,'%f%d%s%d%d%d%s');
          block=xTOT{4}; trial=xTOT{5}; asterick=xTOT{6};
          text=xTOT{7}{1}; type=xTOT{3}{1};
          events(index).experiment = 'attentionTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).block =block;
          events(index).trial =trial;
          events(index).msoffset = xTOT{2};
          events(index).mstime = xTOT{1};
          events(index).type = type;
          events(index).asterick=asterick;
          events(index).text=text;
          events(index).testTrial=-999;
          events(index).foilWord=-999;
          events(index).presentedWord=-999;
          events(index).recognizedWordCorrect=-999;
          events(index).foilSide=-999;
          events(index).RT=-999;
          index=index+1;
  
         
      case 'FORCED_CHOICE'
          xTOT=textscan(thisLine,'%f%d%s%d%d%d%d%d%s%s%d%d');
          foilSide = xTOT{8}; testTrial=xTOT{6};
          recognizedWordCorrect=xTOT{11}; block=xTOT{4};
          presentedWord=xTOT{9}{1}; trial=xTOT{5};
          foilWord=xTOT{10}{1}; asterick=xTOT{7}; RT=xTOT{12};
          events(index).experiment = 'attentionTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).block = block;
          events(index).trial = trial;
          events(index).testTrial = testTrial;
          events(index).msoffset = xTOT{2};
          events(index).mstime= xTOT{1};
          events(index).type= xTOT{3}{1};
          events(index).text=text;
          events(index).asterick=asterick;
          events(index).foilWord = foilWord;
          events(index).presentedWord = presentedWord;
          events(index).recognizedWordCorrect=recognizedWordCorrect;
          events(index).foilSide=foilSide;
          events(index).RT=RT;
          index=index+1;
        
     case 'BLANK'
          xTOT=textscan(thisLine,'%f%d%s');
          events(index).experiment = 'attentionTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type=xTOT{3}{1};
          events(index).asterick=-999;
          events(index).text=-999;
          events(index).testTrial=-999;
          events(index).foilWord=-999;
          events(index).persentedWord=-999;
          events(index).recognizedWordCorrect=-999;
          events(index).foilSide=-999;
          events(index).presentedWord=-999;
          events(index).RT=-999;
          index=index+1;
          
      case 'SESS_END'
          xTOT=textscan(thisLine,'%f%d%s');
          events(index).experiment = 'attentionTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).block = -999;
          events(index).trial = -999;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          index=index+1;
                
  end
end


  