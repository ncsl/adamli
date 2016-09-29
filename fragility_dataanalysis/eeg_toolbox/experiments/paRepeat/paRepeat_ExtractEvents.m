%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  Temp Function for extracting behavioral data.... Doesnt actually extract anything yet! %%%%
%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [events] = paRepeat_ExtractEvents(sessLogFile, subject, session)


fprintf('WARNING: paRepeat extract events just a skelaton... no events actually extracted\n');

fid = fopen(sessLogFile,'r'); %if loops check to see that sessFile exists
if (fid==-1) 
    error('Session.log not found: \n %s/%s \n Exiting.',pwd,sessLogFile); 
else
    %disp([' The session.log file is located in: '  sessLogFile]);
end

index = 1;
while true
    thisLine = fgetl(fid);
    if ~ischar(thisLine);return;end
    
    xTOT=textscan(thisLine,'%f%d%s');
    mstime = xTOT{1}(1); %must add (1) because numberics after the string cause overflow to first %f
    msoffset = xTOT{2};
    type = xTOT{3}{1};
    switch type
        case 'STUDY_START'
            xTOT=textscan(thisLine,'%f%d%s%d');
            events(index).experiment = 'paRepeat';
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
      
        case 'STUDY_START'
            xTOT=textscan(thisLine,'%f%d%s');
            events(index).experiment = 'paRepeat';
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


