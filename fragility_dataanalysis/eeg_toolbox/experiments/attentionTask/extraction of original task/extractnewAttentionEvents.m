function events=extractnewAttentionEvents(subject,expDir,session)
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
          events(index).recognizedWord=-999;
          events(index).confidenceLevel=-999;
          events(index).confidence=-999;
          events(index).confidenceSpec=-999;
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
          events(index).recognizedWord=-999;
          events(index).confidenceLevel=-999;
          events(index).confidence=-999;
          events(index).confidenceSpec=-999;
          events(index).recognizedWordCorrect=-999;
          events(index).foilSide=-999;
          events(index).presentedWord=-999;
          events(index).RT=-999;
          index=index+1;
  
         
      case 'FORCED_CHOICE'
          xTOT=textscan(thisLine,'%f%d%s%d%d%d%d%d%s%s%d%d');
          foilSide = xTOT{8}; testTrial=xTOT{6};
          confidenceNum=xTOT{11}; block=xTOT{4};
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
          events(index).RT=RT;
          
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
          events(index).recognizedWord=-999;
          events(index).confidenceLevel=-999;
          events(index).confidence=-999;
          events(index).confidenceSpec=-999;
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


  