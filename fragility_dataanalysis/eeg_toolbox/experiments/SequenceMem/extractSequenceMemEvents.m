function events=extractSequenceMemEvents(subject,expDir,session)
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
    logdataheaders=regexprep(logdataheaders, {'0x28', '0x3D','0x3B', '0x29'}, {'(', '=', ';',')'}); % tdfread changes some string characters to strange characters for some reason
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
numberdelaycol=find(not(cellfun('isempty', strfind(logdataheaders, 'delay'))));
numbercol=find(not(cellfun('isempty', strfind(logdataheaders, 'number'))));
circlepresentcol=find(not(cellfun('isempty', strfind(logdataheaders, 'circlepresent'))));
circletargetcol=find(not(cellfun('isempty', strfind(logdataheaders, 'circletarget'))));
sequencesaidcol=find(not(cellfun('isempty', strfind(logdataheaders, 'sequencesaid'))));
correctcol=find(not(cellfun('isempty', strfind(logdataheaders, 'correct(0=inc;1=corr;2=wrongtarget)'))));


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
fprintf(fid, [num2str(msStartPyEPL) '\tBLOCK\tCORRECT\tSAIDSEQ\tNUMBER\tCIRCLE\tTARGET']);  

blockrows=find(isnan([logdata{:,numbercol}])); %find all of the block summary rows
trialsbetweenblocks=diff(blockrows)-1; % how many trials were between each block. 
if isempty(find(not(cellfun('isempty', strfind(logdataheaders, 'beginexperiment.keys')))))
    trialsbetweenblocks=[blockrows(1)-1  trialsbetweenblocks];% since the session.log file doesn't have an empty first row, I need to add the number of trials in the very first block becauase diff wont do it
else
    blockrows=blockrows(2:end); % drop the very first one because it's the "begin experiment" row. this is only relevant if you're extracting using the excel file.
end

% save log file
for block=1:size(blockrows,2) 
    saidseq=num2str(logdata{blockrows(block), sequencesaidcol});    
    correct=logdata{blockrows(block), correctcol};
    circletarget=logdata{blockrows(block), circletargetcol};
 
    % psychopy drops any zeros that were typed first. This adds them back
    % in if the trial was correct but the said seq has fewer than 1/2 of
    % the block length (Assumes 1:1 ratio of targets:distractors;
    if length(saidseq)<trialsbetweenblocks(block)/2 && correct>0 
        saidseq=['0' saidseq];
    end

    for trial=blockrows(block)-trialsbetweenblocks(block):blockrows(block)-1
        mstime=round((tstartmultiplier*logdata{trial, starttimecol}+1000*str2num(logdata{trial, numberdelaycol}))) + msStartPyEPL; % log the time of arrow onset
        number=logdata{trial, numbercol};
        circle=logdata{trial, circlepresentcol};
        target=1; 
        if (circletarget==1 && circle==0) || (circletarget==0 && circle==1); 
            target=0;
        end
        events(trial).mstime = mstime;
        events(trial).block  = block;
        events(trial).correct= correct;
        events(trial).saidseq= saidseq;
        events(trial).number = number;
        events(trial).circle = circle;
        events(trial).target = target;
        
        %save the log file data
        fprintf(fid, ['\n' num2str(mstime) '\t' num2str(block) '\t' num2str(correct) '\t' saidseq '\t' num2str(number) '\t' num2str(circle) '\t' num2str(target)]);  %write to logfile
    end
end
fclose(fid);
events(cellfun('isempty',{events.mstime}))=[]; % get rid of the empty "trials" that happened due to the blocks. 

% reexport the log file in the pyepl format
eeglogfile=fullfile(sessdirect, 'origeeg.eeglog');
fid=fopen(eeglogfile,'r');
eegtable=textscan(fid, '%f%s%s');
fclose(fid);
eeglogfile=regexprep(eeglogfile, 'origeeg.eeglog', 'eeg.eeglog');
fid = fopen(eeglogfile,'w');
for pulse = 1:length(eegtable{1})
    % save it to file
    fprintf(fid,'%d\t%d\t%s\n',round(eegtable{1}(pulse)*tstartmultiplier) + msStartPyEPL,1,eegtable{3}{pulse});
end
fclose(fid);


    