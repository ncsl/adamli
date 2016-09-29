function events=extractEpilepsyEvents(subject,expDir,session)
% subject = 'Jian'
% session = 0
% expDir = '/Users/dongj3/Jian/data/dbs/'
sessFile = fullfile(expDir,['session_' num2str(session)],'session.log');
% sessFile = '/Users/dongj3/Jian/data/dbs/DBS000/behavioral/session_0/session.log'
fid = fopen(sessFile,'r'); %if loops check to see that sessFile exists
if fid==-1
  fprintf('session %d..no session.log file found.\n',session);   
  fprintf('EXITING\n\n');
  return
else 
   % disp(['The session.log file is located in: '  sessFile])
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
          session = xTOT{4};
          events(index).session = session;
          events(index).type = 'SESS_START';
          events(index).trial = -999;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).direction = -999;
          index=index+1;

      case 'TRIAL'
          xTOT=textscan(thisLine,'%f%d%s%d');
          currentTrial = xTOT{4};
          events(index).session = session;
          events(index).type = 'TRIAL_START';
          events(index).trial = currentTrial;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).direction = -999;
          index=index+1;

      case 'Direction'
          xTOT=textscan(thisLine,'%f%d%s%d');
          currentDirection = xTOT{4};
          events(index).session = session;
          events(index).type = 'Direction_Cue';
          events(index).trial = currentTrial;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).direction = currentDirection;
          index=index+1;

      case 'Green_light'
          events(index).session = session;
          events(index).type = 'GreenLight';
          events(index).trial = currentTrial;
          events(index).msoffset = msoffset;
          events(index).mstime = mstime;
          events(index).direction = currentDirection;
          index=index+1;

      case 'Red_light'
          events(index).session = session;
          events(index).type = 'RedLight';
          events(index).trial = currentTrial;
          events(index).msoffset = msoffset;
          events(index).mstime = mstime;
          events(index).direction = currentDirection;
          index=index+1;

      case 'Baseline'
          events(index).session = session;
          events(index).type = 'Baseline';
          events(index).trial = -999;
          events(index).msoffset = msoffset;
          events(index).mstime = mstime;
          events(index).direction = -999;
          index=index+1;
      case 'SESS_END'
          events(index).session = session;
          events(index).type = 'SESS_END';
          events(index).trial = -999;
          events(index).msoffset = msoffset;
          events(index).mstime = mstime;
          events(index).direction = -999;
  end
end
disp('done')

  