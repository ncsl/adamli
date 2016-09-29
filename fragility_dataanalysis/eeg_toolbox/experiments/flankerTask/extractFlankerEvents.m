function events=extractFlankerEvents(subject,expDir,session)
% subject = 'Jian'
% session = 0
% expDir = '/Users/dongj3/Jian/data/dbs/'
sessFile = fullfile(expDir,['session_' session],'session.log');
% sessFile = '/Users/dongj3/Jian/data/dbs/DBS000/behavioral/session_0/session.log'
fid = fopen(sessFile,'r'); %if loops check to see that sessFile exists
if fid==-1
  fprintf('session %d..no session.log file found.\n',session);   
  fprintf('EXITING\n\n');
  return
else 
    disp(['The session.log file is located in: '  sessFile])
end

index = 0;
maxRT = 4000 %set used to ID any trials where player did not make a response
while true
  thisLine = fgetl(fid);
  if ~ischar(thisLine);return;end
  index=index+1;
    % get the third string before the underscore
  xTOT=textscan(thisLine,'%f%d%s');
  mstime = xTOT{1};
  msoffset = xTOT{2};
  type = xTOT{3}{1};
  
  if msoffset == 0
      events(index).msoffset = msoffset;
      events(index).mstime = mstime;
      events(index).type = type;
      events(index).direction = '';
      events(index).response = '';
      events(index).correct = -999;
      events(index).conflict = '';
      events(index).RT = -999;
      events(index).numFlankers = -999;
        
  else
      xTOT=textscan(thisLine,'%f%d%s%s%s%d%d');
      direction = xTOT{3}{1};
      response = xTOT{4}{1};
      conflict = xTOT{5}{1};
      RT = xTOT{6};
      if strcmp(direction,response)
          correct=1;
      else
          correct=0;
      end
      
      numFlankers = xTOT{7};
      events(index).msoffset = msoffset;
      if mstime == maxRT
          events(index).mstime = -999;
      else
          events(index).mstime = mstime;
      end;
      events(index).type = 'flankevent';
      events(index).direction = direction;
      events(index).response = response;
      events(index).correct = correct;
      events(index).conflict = conflict;
      events(index).RT = RT;
      events(index).numFlankers = numFlankers;
  end
end
disp('done')
  