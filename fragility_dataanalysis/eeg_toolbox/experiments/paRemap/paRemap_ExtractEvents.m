function [events] = paRemap_ExtractEvents(sessLogFile, subject, sessionName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  Function for extracting behavioral data from paRemap %%%%
%
%
%   extraction designed for paRemap v4.2, which is implemented in pyEPL and was used for NIH030 and beyond
%           (earlier versions were implemented in psychoPy) and were used for NIH028 and 029... those session logs will need some tweaking to use with this extraction
%
%   training section NOT saved to session log... for earlier versions this MUST BE DELETED from the session log
%
%
%
%%%%%   create an event for every presented word and every response (no words from the training sections should be included)
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% uncomment following lines to directly run script
% clear all
%
% rootEEGdir  = '/Users/wittigj/DataJW/AnalysisStuff/dataLocal/eeg';
% rootEEGdir  = '/Volumes/Shares/FRNU/dataWorking/eeg';
% subject     = 'NIH031';   % EEG002  NIH016
% sessionName = 'session_1';
%
% sessionDir  = fullfileEEG(rootEEGdir,subject,'behavioral/paRemap',sessionName);
% sessLogFile = fullfileEEG(sessionDir,'session.log');
% eventFile   = fullfileEEG(sessionDir,'events.mat');
% priorEvents = [];
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%- For NIH028 and NIH029, copy the session log and add the correct msoffset
sessFolderPath  = sessLogFile(1:strfind(sessLogFile,sessionName)+length(sessionName));
paRemap2Sesslog = [sessFolderPath 'paRemap2_session.log'];
    
if exist(paRemap2Sesslog,'file'), % ~exist(sessLogFile,'file') 
        
    
    dateStrPsycho = sessionName(strfind(sessionName,'2015'):end);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % convert psycho date/time into pyEPL date/time which comes from javaSDF
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %- imports required to convert "epoch time" saved by pyepl into real date
    import java.lang.System;
    import java.text.SimpleDateFormat;
    import java.util.Date;
    javaSDF = SimpleDateFormat('MM/dd/yyyy HH:mm:ss.SS');  %this java object is used for mstime to date conversion
    
    %- grab the date from the excell file
    dateNumPsycho  = datenum(dateStrPsycho, 'yyyy_mmm_dd_HHMM');
    dateStrPsycho2 = datestr(dateNumPsycho, 'mm/dd/yy HH:MM PM');  %%- attempting to match format of mac info
    
    %- convert matlab datenum into milisecond number used by javaSDF
    % javaSDF.format(Date(0))              --> '12/31/1969 19:00:00.00'
    % javaSDF.format(Date(60000))          --> '12/31/1969 19:01:00.00'     % 60000 is increment of 1 minute in javatime (javatime is in miliseconds, starting at 12/31/1969  1 min = 60000 microsec)
    % javaSDF.format(Date(1424183683378))  --> '02/17/2015 09:34:43.378'    % example mstime from pyepl session.log
    dateNum0java   = datenum(char(cell(javaSDF.format(Date(0)))));     % this magic conversion relies on java 'Date' and 'SimpleDateFormat' imports at the top of the page
    dayJava        = 24 * 60 * 60 * 1000;                                 % number of miliseconds in a day
    dayMatlab      = datenum('01/02/01 1:00')-datenum('01/01/01 1:00');   % number of days in a matlab date num (should be exactly 1)
    daysToAdd      = (dateNumPsycho-dateNum0java)/dayMatlab;
    msStartPyEPL   = round(dayJava*daysToAdd);
    dateNumMSstart = datenum(char(cell(javaSDF.format(Date(msStartPyEPL)))));  % this magic conversion relies on java 'Date' and 'SimpleDateFormat' imports at the top of the page
    dateStrMSstart = datestr(dateNumMSstart, 'mm/dd/yy HH:MM PM');  % this magic conversion relies on java 'Date' and 'SimpleDateFormat' imports at the top of the page
    %fprintf('\n >> converting to pyepl time reference: msoffset %d = %s  (should match psychoPy xls date = %s) << ', msStartPyEPL, dateStrMSstart, dateStrPsycho2);  %- uncomment to confirm date conversion is working
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %- copy the psychopy session log with msoffset shifted based on folder name/date
    fidRead  = fopen(paRemap2Sesslog,'r');
    fidWrite = fopen(sessLogFile,'w+'); 
    while true
        thisLine = fgetl(fidRead);
        if ~ischar(thisLine); break; end
        [msTime,pos] = textscan(thisLine,'%f',1);
        fprintf(fidWrite,'%d%s\n',msTime{1}+msStartPyEPL,thisLine(pos:end));
    end
    fclose(fidWrite);    
    fclose(fidRead);  
    
   
    %- copy the psychopy session log
    paRemap2eeglog = [sessFolderPath 'paRemap2_eeg.eeglog'];
    standardeeglog = [sessFolderPath 'eeg.eeglog'];

    fidRead  = fopen(paRemap2eeglog,'r'); 
    fidWrite = fopen(standardeeglog,'w+'); 
    while true
        thisLine = fgetl(fidRead);
        if ~ischar(thisLine); break; end
        [msTime,pos] = textscan(thisLine,'%f',1);
        fprintf(fidWrite,'%d%s\n',msTime{1}+msStartPyEPL,thisLine(pos:end));
    end
    fclose(fidWrite);    
    fclose(fidRead);  
    fprintf('\n New copies of session.log and eeg.eeglog were created in %s ',  sessFolderPath);
    
    
    %- Old version, just make the sure copy the first number copy the psychopy session log
    %[SUCCESS,MESSAGE,MESSAGEID] = copyfile(paRemap2Sesslog,sessLogFile);
    
    %[SUCCESS,MESSAGE,MESSAGEID] = copyfile(paRemap2eeglog,standardeeglog);
    
    %fprintf('\n\n Update the new copy of session.log and eeg.eeglog in %s \n --->  REPLACE FIRST TIME POINT WITH % s\n HIT return when done or break with shift F5.',  sessFolderPath, num2str(msStartPyEPL));
    %keyboard
  

end


fid    = fopen(sessLogFile,'r'); %if loops check to see that sessFile exists
if (fid==-1)
    error('Session.log not found: \n %s \n Exiting.',sessLogFile);
else
    [sessionDir,~,~] = fileparts(sessLogFile); %- used for finding annotation files
    %disp([' The session.log file is located in: '  sessLogFile]);
end

%- Convert session folder name into a number.  Should make sessions like "session_9trim" --> 9
strNumeric = find( sessionName >= '0' & sessionName <= '9');
if max(diff(strNumeric))>1, iKeep=[1:find(diff(strNumeric)>1,1,'first')]; fprintf('\n Possible issue converting session name into a numeric.. %s --> %s; use %s', sessionName, sessionName(strNumeric), sessionName(strNumeric(iKeep))); strNumeric=strNumeric(iKeep); end;
sessionNum = str2num( sessionName(strNumeric) );               if isempty(sessionNum), fprintf('\n ERROR: problem converting session name into a numeric'); keyboard;  end; %shouldn't need this catch...



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
    experiment          = 'paRemap';
    subject             = subject   ;
    sessionName         = sessionName ;
    sessionNum          = sessionNum  ;  %- store in state var so all events are assigned a sessionNum
    mstime              = mstime    ;
    msoffset            = msoffset  ;
    type                = type      ;
    
    isProbe             = 0;
    isResponse          = 0;
    isCorrect           = nan;
    
    
    switch type
        
        case {'PROBEWORD_ON'}
            isProbe    = 1;
            xTOT=textscan(thisLine,'%f%d%s%s%s%s%s'); % grab the block number
            probeWord   = xTOT{4}{1};
            targetWord  = xTOT{6}{1};
            %thisAnnFile = xTOT{7}{1};  %- one version has an annotation file associated with each word, eventually that was jettisoned.  
            index=index+1;
            
            %         case {'REC_START'}
            %             isResponse = 1;
            %             % go through annotation file and get all the recalls here.
            %             annFileName  = sprintf('%s.ann',targetAnn);
            %             annFile      = fullfile(sessionDir,annFileName);
            %             if ~exist(annFile,'file'),
            %                 if MISSING_ANN == 0,
            %                     fprintf('\n >>> %s (and possibly others) were not found in %s',annFileName,sessionDir);
            %                 end
            %                 MISSING_ANN = MISSING_ANN + 1;
            %                 resultStr = sprintf('ANN: no ann file found');
            %
            %             else
            %                 %- ann file present... process it
            %                 fid2 = fopen(annFile,'r');
            %                 if fseek(fid2,1,'bof')==-1 %annotation file is empty
            %                     fprintf('\n%s is empty',annFile); keyboard;
            %                 else
            %                     fseek(fid2,0,'bof');
            %                     while true
            %                         tmpAnnLine=fgetl(fid2);
            %                         if ~ischar(tmpAnnLine);      break;    end
            %                         if numel(tmpAnnLine)==0;     continue; end
            %                         if strcmp(tmpAnnLine(1),'#');continue; end %- advance past comments and empty lines
            %
            %                         x2=textscan(tmpAnnLine,'%f%f%s');
            %                         thisRT = round(x2{1});
            %                         thisWordNum = x2{2};
            %                         thisRecWord = x2{3}{1};
            %
            %                         isCorrect = strcmp(thisRecWord,targetWord);
            %
            %                         %% in case multilpe words spoken
            %                         responseWord{end+1}  = thisRecWord;
            %                         responseTimes(end+1) = thisRT+mstime;
            %                         responseIsCor(end+1) = isCorrect;
            %                     end
            %                 end
            %                 fclose(fid2);
            %
            %             end
    end
    
    
    %- asign values to events array
    if index>length(events),
        
        
        %- create dummy event structure that is upddated below based on type
        clear thisEvent
        thisEvent.experiment        = experiment  ;
        thisEvent.subject           = subject     ;
        thisEvent.sessionName       = sessionName ;
        thisEvent.sessionNum        = sessionNum  ;   % store in state var so all events are assigned a sessionNum  %% JW updated 2/2015
        thisEvent.type              = type        ;
        thisEvent.msoffset          = msoffset    ;
        thisEvent.mstime            = mstime      ;
        
        
        %- event identity
        thisEvent.isProbe           = isProbe        ;   %- 1 or 0
        thisEvent.isResponce        = isResponse     ;   %- 1 or 0
        
        thisEvent.probeWord         = probeWord     ;
        thisEvent.targetWord        = targetWord    ;
        thisEvent.isCorrect         = isCorrect     ;
        
        
        if (index==1)
            events        = thisEvent; %- before events defined must convert to structure
        else
            events(index) = thisEvent;
        end
    end
    
end
fclose(fid);  % close session.log

