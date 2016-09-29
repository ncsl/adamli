function events=extractAttentionEvents(subject,expDir,session)
% subject = 'Jian'
% session = 0
% expDir = '/Users/ellenbogenrl/Rachel/data/eeg/NIH011/behavioral/attentionTask/'
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
          events(index).block = -999;
          events(index).trial = -999;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};         
          index=index+1;
      case 'CUE'
          xTOT=textscan(thisLine,'%f%d%s%s%s');
          [foo, block] = strread(xTOT{4}{1},'%s %d','delimiter','_');
          [foo, trial] = strread(xTOT{5}{1},'%s %d','delimiter','_');
          events(index).experiment = 'attentionTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).block = block;
          events(index).trial = trial;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};
          index=index+1;
          
      case 'ARROW'
          xTOT=textscan(thisLine,'%f%d%s%d');
          arrow = xTOT{4};
          events(index).experiment = 'attentionTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).block = block;
          events(index).trial = trial;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};
          events(index).arrow = arrow;
          index=index+1;
          
      case 'WORDS'
          xTOT=textscan(thisLine,'%f%d%s%s%d%s%d%s%s');
          topWord = xTOT{4}{1}; topWordLiving = xTOT{5};
          bottomWord = xTOT{6}{1}; bottomWordLiving = xTOT{7};
          [foo, contrast] = strread(xTOT{8}{1},'%s %03f','delimiter','_');
          [foo, livingResponse] = strread(xTOT{9}{1},'%s %d','delimiter','_');
          events(index).experiment = 'attentionTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).block = block;
          events(index).trial = trial;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};
          events(index).arrow = arrow;
          events(index).contrast = contrast;
          events(index).topWord = topWord;
          events(index).bottomWord = bottomWord;
          
          if arrow==0
              events(index).attendedWord = topWord;
              events(index).livingAnswer = topWordLiving;
          else
              events(index).attendedWord = bottomWord;
              events(index).livingAnswer = bottomWordLiving;
          end
          
          events(index).livingResponse = livingResponse;
          if events(index).livingAnswer==2
            events(index).livingCorrectResponse = 1; 
          elseif events(index).livingAnswer==0 & events(index).livingResponse==0
              events(index).livingCorrectResponse = 1;
          elseif events(index).livingAnswer==1 & events(index).livingResponse==1
              events(index).livingCorrectResponse = 1;
          else
              events(index).livingCorrectResponse = 0;
          end
          index=index+1;
          
      case 'TASK_FC'
          xTOT=textscan(thisLine,'%f%d%s%s%s%s%s%s%s');
          [foo, taskTrial] = strread(xTOT{5}{1},'%s %d','delimiter','_');
          [foo, testTrial] = strread(xTOT{6}{1},'%s %d','delimiter','_');
          [foo, foilSide] = strread(xTOT{7}{1},'%s %d','delimiter','_');
          [foo, foilWord] = strread(xTOT{8}{1},'%s %s','delimiter','_');
          foilWord=foilWord{1};
          [attendedUnattended, presentedWord] = strread(xTOT{9}{1},'%s %s','delimiter','_');
          attendedUnattended=attendedUnattended{1}; presentedWord=presentedWord{1};
          annFileName = sprintf('%d_%d.ann',block,testTrial);
          annFile = fullfile(expDir,['session_' num2str(session)],annFileName);
          if ~exist(annFile,'file')
              error('%s was not found',annFile)
          end
          fid2=fopen(annFile,'r');
          if fseek(fid2,1,'bof')==-1
              confidenceNum=0;
              RT=0;
          else
              fclose(fid2);
              fid2=fopen(annFile,'r');
              while true
                  tmpAnnLine=fgetl(fid2);
                  if ~ischar(tmpAnnLine);break;end
                  if numel(tmpAnnLine)==0;continue;end
                  if strcmp(tmpAnnLine(1),'#');continue;end
                  Line=textscan(tmpAnnLine,'%f%f%s');
                  RT = round(Line{1});
                  confidenceNum = Line{3}{1}; confidenceNum=str2double(confidenceNum);
              end
          end
          fclose(fid2);
          events(index).experiment = 'attentionTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).block = block;
          events(index).trial = taskTrial;
          events(index).testTrial = testTrial;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};
          events(index).foilWord = foilWord;
          events(index).presentedWord = presentedWord;
          events(index).presentedWordType = attendedUnattended;
          
          if foilSide==0
              switch confidenceNum

                  case 1
                      events(index).foilSide = foilSide;
                      events(index).recognizedWord = foilWord;
                      events(index).confidenceLevel = 'high';
                      events(index).confidence = confidenceNum;
                      events(index).confidenceSpec = 1;
                  case 2
                      events(index).foilSide = foilSide;
                      events(index).recognizedWord = foilWord;
                      events(index).confidenceLevel = 'medium';
                      events(index).confidence = confidenceNum;
                      events(index).confidenceSpec = 2;
                  case 3
                      events(index).foilSide = foilSide;
                      events(index).recognizedWord = foilWord;
                      events(index).confidenceLevel = 'low';
                      events(index).confidence = confidenceNum;
                      events(index).confidenceSpec = 3;
                  case 4
                      events(index).foilSide = foilSide;
                      events(index).recognizedWord = presentedWord;
                      events(index).confidenceLevel = 'low';
                      events(index).confidence = confidenceNum;
                      events(index).confidenceSpec = 4;
                  case 5
                      events(index).foilSide = foilSide;
                      events(index).recognizedWord = presentedWord;
                      events(index).confidenceLevel = 'medium';
                      events(index).confidence = confidenceNum;
                      events(index).confidenceSpec = 5;
                  case 6
                      events(index).foilSide = foilSide;
                      events(index).recognizedWord = presentedWord;
                      events(index).confidenceLevel = 'high';
                      events(index).confidence = confidenceNum;
                      events(index).confidenceSpec = 6;
                  case 0
                      events(index).foilSide = foilSide;
                      events(index).recognizedWord = '';
                      events(index).confidenceLevel = 'n/a';
                      events(index).confidence = 0;
                      events(index).confidenceSpec=0;
                  otherwise
                      error('This should not happen. Error 1');
              end
          elseif foilSide==1
              switch confidenceNum
                  case 1
                      events(index).foilSide = foilSide;
                      events(index).recognizedWord = presentedWord;
                      events(index).confidenceLevel = 'high';
                      events(index).confidence = confidenceNum;
                      events(index).confidenceSpec = 6;
                  case 2
                      events(index).foilSide = foilSide;
                      events(index).recognizedWord = presentedWord;
                      events(index).confidenceLevel = 'medium';
                      events(index).confidence = confidenceNum;
                      events(index).confidenceSpec = 5;
                  case 3
                      events(index).foilSide = foilSide;
                      events(index).recognizedWord = presentedWord;
                      events(index).confidenceLevel = 'low';
                      events(index).confidence = confidenceNum;
                      events(index).confidenceSpec = 4;
                  case 4
                      events(index).foilSide = foilSide;
                      events(index).recognizedWord = foilWord;
                      events(index).confidenceLevel = 'low';
                      events(index).confidence = confidenceNum;
                      events(index).confidenceSpec = 3;
                  case 5
                      events(index).foilSide = foilSide;
                      events(index).recognizedWord = foilWord;
                      events(index).confidenceLevel = 'medium';
                      events(index).confidence = confidenceNum;
                      events(index).confidenceSpec = 2;
                  case 6
                      events(index).foilSide = foilSide;
                      events(index).recognizedWord = foilWord;
                      events(index).confidenceLevel = 'high';
                      events(index).confidence = confidenceNum;
                      events(index).confidenceSpec = 1;
                  case 0
                      events(index).foilSide = foilSide;
                      events(index).recognizedWord = 0;
                      events(index).confidenceLevel = 'n/a';
                      events(index).confidence = 0;
                      events(index).confidenceSpec = 0;
                  otherwise
                      error('This should not happen. Error 2');
              end
          end
          if strcmpi(events(index).recognizedWord, events(index).presentedWord)
              events(index).recognizedWordCorrect = 1;
          else strcmpi(events(index).recognizedWord, events(index).foilWord) 
              events(index).recognizedWordCorrect = 0;
          end
          
          contrastLocation=find(([events.block] == block) & ([events.trial]==taskTrial) & strcmp({events.type},'WORDS'));
          if length(contrastLocation)~=1; error('other than 1 contrastLocation');end;
          events(index).contrast=events(contrastLocation).contrast;
          livingCorrectLocation=find(([events.block] == block) & ([events.trial] == taskTrial) & strcmp({events.type},'WORDS'));
          if length(livingCorrectLocation)~=1; error('other than 1 livingCorrectLocation');end;
          events(index).livingCorrectResponse=events(livingCorrectLocation).livingCorrectResponse;
          index=index+1;

      case 'TASK_RECOG'
          xTOT=textscan(thisLine,'%f%d%s%s%s%s%s');
          [foo, taskTrial] = strread(xTOT{5}{1},'%s %d','delimiter','_');
          [foo, testTrial] = strread(xTOT{6}{1},'%s %d','delimiter','_');
          [presentedWordType, presentedWord] = strread(xTOT{7}{1},'%s %s','delimiter','_');
          presentedWordType=presentedWordType{1}; presentedWord=presentedWord{1};
          annFileName = sprintf('%d_%d.ann',block,testTrial);
          annFile = fullfile(expDir,['session_' num2str(session)],annFileName);
          if ~exist(annFile,'file')
              error('%s was not found',annFile)
          end
          
          fid3=fopen(annFile,'r');
          if fseek(fid3,1,'bof')==-1
              confidenceNum=0;
              RT=0;
          else
              fclose(fid3);
              fid3=fopen(annFile,'r');
              while true
                  tmpAnnLine=fgetl(fid3);
                  if ~ischar(tmpAnnLine);break;end
                  if numel(tmpAnnLine)==0;continue;end
                  if strcmp(tmpAnnLine(1),'#');continue;end
                  Line=textscan(tmpAnnLine,'%f%f%s');
                  RT = round(Line{1});
                  confidenceNum = Line{3}{1}; confidenceNum=str2double(confidenceNum);
              end
          end
          
          fclose(fid3);
          events(index).experiment = 'attentionTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).block = block;
          events(index).trial = taskTrial;
          events(index).testTrial=testTrial;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};
          events(index).presentedWord = presentedWord;
          events(index).presentedWordType = presentedWordType;
          events(index).confidence = confidenceNum;
          
          % the following if loop establishes the confidenceLevel field
          if events(index).confidence == 1 || events(index).confidence == 6
              events(index).confidenceLevel='high';
          elseif events(index).confidence == 2 || events(index).confidence == 5
              events(index).confidenceLevel='medium';
          elseif events(index).confidence == 3 || events(index).confidence == 4
              events(index).confidenceLevel='low';
          end
          
          if strcmpi(events(index).presentedWordType, 'UNATTENDED') || strcmpi(events(index).presentedWordType, 'ATTENDED')
              if events(index).confidence == 4 || events(index).confidence == 5 || events(index).confidence == 6
                  events(index).recognizedWordCorrect = 1;
              else
                  events(index).recognizedWordCorrect = 0;
              end
          elseif strcmpi(events(index).presentedWordType, 'FOIL')
              if events(index).confidence == 1 || events(index).confidence == 2 || events(index).confidence == 3
                  events(index).recognizedWordCorrect = 1;
              else
                  events(index).recognizedWordCorrect = 0;
              end
          else
              error('Another condition other than Foil, Unattended, Attended.')
          end
          
          contrastLocation=find(([events.block] == block) & ([events.trial] == taskTrial) & strcmp({events.type},'WORDS'));
          if taskTrial == -1; 
              events(index).contrast=-1;
              events(index).livingCorrectResponse=-1;
          else
              if length(contrastLocation)>1; error('other than 1 contrastLocation');end; 
              events(index).contrast=events(contrastLocation).contrast;
                  
              livingCorrectLocation=find(([events.block] == block) & ([events.trial] == taskTrial) & strcmp({events.type},'WORDS'));
              if length(livingCorrectLocation)~=1; error('other than 1 livingCorrectLocation');end;
              events(index).livingCorrectResponse=events(livingCorrectLocation).livingCorrectResponse;
          end
          index=index+1;
          
      case 'RECORD_START'
          events(index).experiment = 'attentionTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).block = block;
          events(index).trial = taskTrial;
          events(index).testTrial=testTrial;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};
          index=index+1;


      case 'RECORD_STOP'
          if strcmpi(events(index-2).type,'TASK_FC') || strcmpi(events(index-2).type,'TASK_RECOG')
              events(index)=events(index-2);
              events(index).mstime=events(index-2).mstime+RT;
              events(index).RT=RT;
              events(index).type=[events(index-2).type '_RESPONSE'];
%               contrastLocation=find(([events.block] == block) & ([events.testTrial] == testTrial) & strcmp({events.type},'WORDS'));
%               if length(contrastLocation)~=1; error('other than 1 contrastLocation');end;
%               events(index).contrast=events(contrastLocation).contrast; 
%               livingCorrectLocation=find(([events.block] == block) & ([events.testTrial] == testTrial) & strcmp({events.type},'WORDS'));
%               if length(livingCorrectLocation)~=1; error('other than 1 livingCorrectLocation');end;
%               events(index).livingCorrectResponse=events(livingCorrectLocation).livingCorrectResponse;
          else
              error('Unexpected Task.');
          end
          index=index+1;
          
          
          events(index).experiment = 'attentionTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).block = block;
          events(index).trial = taskTrial;
          events(index).testTrial=testTrial;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};
          index=index+1;
          
      case 'SESS_END'
          events(index).experiment = 'attentionTask';
          events(index).subject = subject;
          events(index).session = session;
          events(index).block = -999;
          events(index).trial = -999;
          events(index).msoffset = msoffset;
          events(index).mstime = xTOT{1};
          events(index).type = xTOT{3}{1};
          index=index+1;         
  end
end
disp('done')

  