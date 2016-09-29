function events=extractGoAntiGoEvents(subject,expDir,session)
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
            if strcmp(logdataheaders{field},'key_resp_20x2Ert')
                logdata{trial,field}=str2double(logdatastruct.(logdataheaders{field})(trial,:));
            else
                logdata{trial,field}=logdatastruct.(logdataheaders{field})(trial,:); 
                if ischar(logdata{trial,field})
                    logdata{trial,field}=strtrim(logdata{trial,field}); % get rid of leading and trailing spaces
                end
            end
        end
    end
    tstartmultiplier=1; % the TRIALSTART used to be saved in s, not ms. If you're using a session.log file though its already in ms. 
    logdataheaders=regexprep(logdataheaders, '0x2E', '.'); % tdfread changes periods to 0x2E for some reason
else
    sessFile = fullfile(sessdirect,'session.xlsx');
    [~,~,logdata]=xlsread(sessFile);
    logdataheaders=logdata(1,:); % get the headers
    logdata=logdata(2:end,:); % get the data
    datecol=find(not(cellfun('isempty', strfind(logdataheaders, 'date'))));
    dateStrPsycho  = logdata(1,datecol);  % example: "2015_Feb_19_1125"
    tstartmultiplier=1000; % the TRIALSTART used to be saved in s, not ms. 
end

% find the column corresponding to each header
starttimecol=find(not(cellfun('isempty', strfind(logdataheaders, 'TRIALSTART'))));
arrowdelaycol=find(not(cellfun('isempty', strfind(logdataheaders, 'delay'))));
directioncol=find(not(cellfun('isempty', strfind(logdataheaders, 'direction'))));
keyrespcol=find(not(cellfun('isempty', strfind(logdataheaders, 'key_resp_2.keys'))));
RTcol=find(not(cellfun('isempty', strfind(logdataheaders, 'key_resp_2.rt'))));
colorcol=find(not(cellfun('isempty', strfind(logdataheaders, 'color'))));
edgecolorcol=find(not(cellfun('isempty', strfind(logdataheaders, 'edgecolor'))));
colorcol=setdiff(colorcol,edgecolorcol);
correctcol=find(not(cellfun('isempty', strfind(logdataheaders, 'key_resp_2.corr'))));


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


%open future log file for saving
logfile=fullfile(sessdirect, 'session.log');
fid=fopen(logfile,'w');
fprintf(fid, [num2str(msStartPyEPL) '\tDIRECTION\tRESPONSE\tRT\tGOANTIGO\tNOGO\tCORRECT']);  

% save log file
for trial=1:size(logdata,1)    
    mstime=round((tstartmultiplier*logdata{trial, starttimecol}+1000*str2num(logdata{trial, arrowdelaycol}))) + msStartPyEPL; % log the time of arrow onset
    direction='RIGHT'; % log the direction of arrow
        if logdata{trial,directioncol}==-90; direction='LEFT'; end
    response=upper(logdata{trial, keyrespcol}); % log the response 
    RT=round(logdata{trial,RTcol}*1000); % log the RT
    goantigo='GO';% log if go or antigo
        if strcmp(logdata{trial,colorcol}, 'red'); goantigo='ANTIGO'; end
    nogo=0;% log if nogo
        if strcmp(logdata{trial,edgecolorcol}, 'white'); nogo=1; end
    correct=logdata{trial,correctcol}; % log if correct
    
    %save the log file data
    fprintf(fid, ['\n' num2str(mstime) '\t' direction '\t' response '\t' num2str(RT) '\t' goantigo '\t' num2str(nogo) '\t' num2str(correct)]);  %write to logfile
      
    events(trial).mstime = mstime;
    events(trial).direction = direction;
    events(trial).response = response;
    events(trial).correct = correct;
    events(trial).goantigo = goantigo;
    events(trial).nogo = nogo;
    events(trial).RT = RT;
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

    