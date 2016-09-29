function events=extractSerialRTEvents(subject,expDir,session)
% subject = 'Zar'
% session = 2
% expDir = '/Volumes/shares/FRNU/dataworking/dbs/DBS021/behavioral/GoAntiGo'
sessdirect = fullfile(expDir,['session_' session]);
sessdirect_files=dir(sessdirect);
sessdirect_filenames={sessdirect_files.name};
targetfileindex=find(~cellfun('isempty', regexp(sessdirect_filenames, ['orig_\d\d\d\d_\w\w\w_\d\d_\d\d\d\d_session.log']))); %search for the session.log file
if ~isempty(targetfileindex);
    sessFile=fullfile(sessdirect, sessdirect_filenames{targetfileindex});
    dateStrPsycho=regexp(sessdirect_filenames{targetfileindex},'\d\d\d\d_\w\w\w_\d\d_\d\d\d\d', 'match');
    logdatastruct=tdfread(sessFile, '\t');
    logdataheaders=fieldnames(logdatastruct);

    % get the data in the same format as if you read data from excel. Future extract.m files for psychopy tasks shouldn't need this as I transition away from excel
    logdata=cell(length(logdatastruct.TRIALSTART), length(logdataheaders));
    for field=1:length(logdataheaders)
        for trial=1:length(logdatastruct.TRIALSTART)
%             if strcmp(logdataheaders{field},'correctresp0x2Ert') || strcmp(logdataheaders{field},'allkeys0x2Ert')
%                 logdata{trial,field}=str2num(logdatastruct.(logdataheaders{field})(trial,:));
%             else
                logdata{trial,field}=logdatastruct.(logdataheaders{field})(trial,:); 
                if ischar(logdata{trial,field})
                    logdata{trial,field}=strtrim(logdata{trial,field}); % get rid of leading and trailing spaces
                end
%             end
        end
    end
    tstartmultiplier=1; % the TRIALSTART used to be saved in s, not ms. If you're using a session.log file though its already in ms. 
    logdataheaders=regexprep(logdataheaders, {'0x2E'}, {'.'}); % tdfread changes some string characters to strange characters for some reason
else
    sessFile = fullfile(sessdirect,'session.xlsx');
    [~,~,logdata]=xlsread(sessFile);
    logdataheaders=logdata(1,:); % get the headers
    logdata=logdata(2:end,:); % get the data
    datecol=find(not(cellfun('isempty', strfind(logdataheaders, 'date'))));
    dateStrPsycho  = logdata(1,datecol);  % example: "2015_Feb_19_1125"
    tstartmultiplier=1000; % the TRIALSTART used to be saved in s, not ms. 
    logdata=logdata(cellfun(@(V) any(~isnan(V(:))),logdata(:,find(strcmp(logdataheaders, 'trials.thisRepN')))),:); % get ride of all of the empty rows between blocks. 
end

% find the column corresponding to each header
starttimecol=find(not(cellfun('isempty', strfind(logdataheaders, 'TRIALSTART'))));
sequenceblockcol=find(not(cellfun('isempty', strfind(logdataheaders, 'sequenceblock'))));
nogoblockcol=find(not(cellfun('isempty', strfind(logdataheaders, 'nogoblock'))));
imagecol=find(not(cellfun('isempty', strfind(logdataheaders, 'image'))));
correctrespcol=find(not(cellfun('isempty', strfind(logdataheaders, 'correctresp.keys'))));
correctRTcol=find(not(cellfun('isempty', strfind(logdataheaders, 'correctresp.rt'))));
incorrectrespcol=find(not(cellfun('isempty', strfind(logdataheaders, 'allkeys.keys'))));
incorrectRTcol=find(not(cellfun('isempty', strfind(logdataheaders, 'allkeys.rt'))));


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
if ~strcmp(dateStrMSstart, dateStrPsycho2)
    fprintf('\n >> PROBLEM converting to pyepl time reference: msoffset %d = %s  (should match psychoPy xls date = %s) << ', msStartPyEPL, dateStrMSstart, dateStrPsycho2);  %- uncomment to confirm date conversion is working
    hourJava   = dayJava/24;
    hourMatlab = datenum('01/01/01 2:00')-datenum('01/01/01 1:00');   % number of days in a matlab date num (should be exactly 1)
    timeDiff   = datenum(dateStrMSstart)-datenum(dateStrPsycho2);
    if (timeDiff-hourMatlab)<0.1*hourMatlab,     % is it about an hour ahead
        msStartPyEPL   = msStartPyEPL-hourJava;
    elseif (timeDiff+hourMatlab)<0.1*hourMatlab, % is it about an hour behind
        msStartPyEPL   = msStartPyEPL+hourJava;
    else
        fprintf('\n Uh Oh... times dont match by +/- 1 hour... error is not daylight savings problem'); keyboard;
    end
    dateNumMSstart = datenum(char(cell(javaSDF.format(Date(msStartPyEPL)))));  % this magic conversion relies on java 'Date' and 'SimpleDateFormat' imports at the top of the page
    dateStrMSstart = datestr(dateNumMSstart, 'mm/dd/yy HH:MM PM');  % this magic conversion relies on java 'Date' and 'SimpleDateFormat' imports at the top of the page
    fprintf('\n >> CORRECTION converting to pyepl time reference: msoffset %d = %s  (should match psychoPy xls date = %s) << ', msStartPyEPL, dateStrMSstart, dateStrPsycho2);  %- uncomment to confirm date conversion is working
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%open future log file for saving
logfile=fullfile(sessdirect, 'session.log');
fid=fopen(logfile,'w');
fprintf(fid, [num2str(msStartPyEPL) '\tsequenceblock\tnogoblock\tfinger\tnogotrial\tRT\tincorrectresp\tincorrectRT']);  

% save log file
for trial=1:size(logdata,1)
    mstime=round(tstartmultiplier*logdata{trial, starttimecol}) + msStartPyEPL; % log the time of arrow onset
    sequenceblock=1; % log if this is a sequence block
        if logdata{trial,sequenceblockcol}==0; sequenceblock=0; end
    nogoblock=1; % log if this is a nogo block
        if logdata{trial,nogoblockcol}==0; nogoblock=0; end
    finger=1; % log if the finger cued during trial
        if ~isempty(regexp(logdata{trial,imagecol}, 'middle')); finger=2; 
        elseif ~isempty(regexp(logdata{trial,imagecol}, 'ring')); finger=3;
        elseif ~isempty(regexp(logdata{trial,imagecol}, 'pinky')); finger=4;
        end
    nogotrial=0; % log if it's a nogotrial
        if strcmp(logdata{trial,correctrespcol},'None'); nogotrial=1; end
    RT=0; % log the RT
        if ~isnan(logdata{trial,correctRTcol}); RT=round(str2num(logdata{trial,correctRTcol})*1000); end
    incorrectresp=str2num(regexprep(logdata{trial,incorrectrespcol}, {'[', ']', char(39), ','}, '')); % log any incorrect responses
        if isempty(incorrectresp); incorrectresp=NaN; end
    incorrectRT=NaN; % log the RT
        if ~isnan(logdata{trial,incorrectRTcol})==1; incorrectRT=round(str2num(logdata{trial,incorrectRTcol})*1000); end

    
    %save the log file data
    fprintf(fid, ['\n' num2str(mstime) '\t' num2str(sequenceblock) '\t' num2str(nogoblock) '\t' num2str(finger) '\t' num2str(nogotrial) '\t' num2str(RT) '\t' regexprep(regexprep(num2str(incorrectresp), '  ', ' '), ' ', '&') '\t' regexprep(regexprep(num2str(incorrectRT), '  ', ' '), ' ', '&')]);  %write to logfile
      
    events(trial).mstime = mstime;
    events(trial).sequenceblock = sequenceblock;
    events(trial).nogoblock = nogoblock;
    events(trial).finger = finger;
    events(trial).nogotrial = nogotrial;
    events(trial).RT = RT;
    events(trial).incorrectresp = incorrectresp;
    events(trial).incorrectRT = incorrectRT;
end
fclose(fid);

% reexport the log file in the pyepl format
eeglogfile=fullfile(sessdirect, 'origeeg.eeglog');
fid=fopen(eeglogfile,'r');
if fid<0
    fprintf('\nNO origeeg.eeglog FILE DETECTED!\n');
else
    eegtable=textscan(fid, '%f%s%s');
    fclose(fid);
    eeglogfile=regexprep(eeglogfile, 'origeeg.eeglog', 'eeg.eeglog');
    fid = fopen(eeglogfile,'w');
    for pulse = 1:length(eegtable{1})
        % save it to file
        fprintf(fid,'%d\t%d\t%s\n',round(eegtable{1}(pulse)*tstartmultiplier) + msStartPyEPL,1,eegtable{3}{pulse});
    end
    fclose(fid);
end

    