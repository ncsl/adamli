function eegPrepAndAlign( subj, rootEEGdir )
%Function eegPrepAndAlign( subj, rootEEGdir)
%
%  Master function used to prepare a subject's data for alignment.  
%  Rerun multiple times to guide alignment process.
%    --Preparation of EEG data--
%      (1) run to generate list of approximate eeg session times to guide Kareem's acquisition of RAW data
%      (2) run to convert RAW eeg data to channel data
%      (3) run to identify eeg sync channels and confirm existance of resultance eeg sync file
%    --Preparation of Behavioral data--
%      (1) run to extract behavioral events.mat for all tasks and sessions
%      (2) run to align behavioral sync file and eeg sync files
%
%  Outputs:
%    --Command line outputs describing status of RAW and Behavioral files
%    --text file saved to subject/behavior/alignmentSummary.txt
%    --if alignment possible, updated events.mat in each session and "master events.mat" found in task's root directory
%    --                       copies of session.log and eeg.eeglog with align info (session.log.align and eeg.eeglog.align)
%    --text file alignmentPairing_auto.txt that lists alignment pairs... this can be modified and saved as alignmentPairing_forced.txt to override auto pairing
%    --text file alignmentStats.txt that lists alignment fit info (sucess, R^2, max devitions, etc)
%
%  Inputs:
%    -- subj                        % subject string,        ex) 'NIH016'
%    -- rootEEGdir                  % data path up to "eeg", ex) '/Users/wittigj/DataJW/data/eeg'   
%    -- FORCE_EVENT_REEXTRACTION    % 0 or 1: re-extract all behavioral events using "behavioralProcessing"; 
%                                             (events.mat always extracted if missing)
%    -- FORCE_MASTER_EVENTS_UPDATE  % 0 or 1: confirm all master events.mat up-to-date after alignment and update if need be 
%                                             (master always updated when session aligned)
%
%  created by JHW 9/10/2013
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Function Flow:
%       [1/4]  Searching RAW and/or EEG.NOREREF for Raw and/or Extracted Channel files
%               --> if raws missing, look for extracted channels and sync files and proceed (sometimes extraction present when raws aren't)
%               --> if raws present, confirm that each has been extracted and has a sync file;  extract if necessary;  rereference if necessary
%       [2/4] Searching behavioral directory for eeg.eeglog and events.mat files
%               --> extract events.mat and eeg.eeglogup if missing
%       [3/4] Preparing for alignment: identify pairings of eeg.eeglog <--> extracted sync pulses
%               --> try to identify pairs of behavioral and eeg files.  happens automatically, but can be overrode with text file
%       [4/4] Alignment: confirm all events.mat aligned; offer alignment if not:
%               --> steps through each alignment one-by-one;  update master events.mat.
%       [END] Summary output
%               --> graphs and text output indicating target dates of missing raw files, missing sync files, and unsuccessful alignments
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%-- USER SETS THE FOLLOWING VARIABLES if running directly from M-file (instead of using as function... useful for debugging)

%clear all
%subj       = 'NIH019';
%rootEEGdir = '/Users/wittigj/DataJW/AnalysisStuff/dataLocal/eeg';  %%- rootEEGdir is data path up to and including "EEG"
%rootEEGdir = '/Volumes/Kareem/data/eeg/';  %%- rootEEGdir is data path up to and including "EEG"
%rootEEGdir = 'C:/Users/jDub/DataJW/eeg';



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%-- Global Variable Definition and Error check existance of rootEEGdir string
%%--
%- execution options
FORCE_RAW_REEXTRACTION      = 0 ;  % 0 or 1: re-extract all raw data to individual channels (Raw always extracted if matching channel data is missing)

FORCE_EVENT_REEXTRACTION    = 0 ;  % 0 or 1: re-extract all behavioral events using "behavioralProcessing"; if 0 only sessions missing events will be extracted
FORCE_MASTER_EVENTS_UPDATE  = 0 ;  % 0 or 1: confirm all master events.mat is up-to-date after alignment and update if need be (master always updated when session aligned)

FORCE_REALIGNMENT           = 0 ;  % 0 or 1: (re)run alignment on all event files.
BYPASS_ALIGNMENT_USER_QUERY = 0 ;  % 0 or 1: should ALWAYS be 0, unless you are sure that all alignments are OK and just need to realign a task.


%%% not a valid toggle yet, but would be convenient... need to (1) confirm no.reref is empty or doesnt exist, (2) modify nk_split to only output first channel (irrespective of tag names, etc)
%%%  also it would be nice to make alignment only pause when something is NOT good
%EXTRACT_1CHAN_TO_TEST_ALIGNMENT = ; % 0 or 1:  should ALWAYS be 0, unless you are doing a first pass at confirming behavior and physio line up... eeg.noreref and eeg.reref should be deleted after running this in setting 1
SKIP_EXTRACTION = 0;   % 0 or 1:  should ALWAYS be 0, unless you are doing a first pass at confirming behavior and physio line up... eeg.noreref and eeg.reref should be deleted after running this in setting 1


%- events eegfile entry all pointed to this root
serverDataPath = '/Volumes/Shares/FRNU/data/eeg/';
FORCE_ALIGNMENT_TO_SERVER_PATH = 1; % 0 or 1: if 1 (default), set aligned events eegfile to '/Volumes/Shares/FRNU/data/eeg/subj/eeg.reref/'; if 0, set aligned events to local data directory
                        

%- imports required to convert "epoch time" saved by pyepl into real date
import java.lang.System;
import java.text.SimpleDateFormat;
import java.util.Date;
javaSDF = SimpleDateFormat('MM/dd/yyyy HH:mm:ss.SS');  %this java object is used for mstime to date conversion

%- confirm subject directory exists
subjDir = fullfileEEG(rootEEGdir,subj);
if ~exist(subjDir,'dir'), error(sprintf('Error: root eeg directory: %s \n       does not contain subject: %s',rootEEGdir, subj) ); end
fprintf('\n\n\n**************************************************************************************'); %%- Command line output
fprintf('\n*************************************** %s ***************************************', subj);     %%- Command line output
fprintf('\n**************************************************************************************');     %%- Command line output

if BYPASS_ALIGNMENT_USER_QUERY==1, fprintf('\n WARNING: BYPASS_ALIGNMENT_USER_QUERY set to 1... default state should be 0\n'); end
if SKIP_EXTRACTION==1,             fprintf('\n WARNING: SKIP_EXTRACTION set to 1... default state should be 0.  Raw Files will NOT be split.\n'); end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%-- search RAW directory
%%--        if raw data there extract the details (name/date)
%%--        confirm whether already extracted to noreref (extract if not)
%%--        look for associated sync files and pull TTL channel numbers if so
%%--
fprintf('\n\n[STEP 1/4] Searching RAW and/or EEG.NOREREF for Raw and/or Extracted Channel files:\n');

MISSING_RAW_AND_EXTRACTED = 0;        
rawDir = fullfileEEG(rootEEGdir,subj,'raw');
days   = dir(fullfileEEG(rootEEGdir,subj,'raw/DAY_*'));
%stim   = dir(fullfileEEG(rootEEGdir,subj,'raw/STIM*')); days(end+1:end+length(stim))=stim; %-comment in line to include stimulation files
rawList=[];  extractedList=[];
rawTimes=nan;
if (length(days)==0 | SKIP_EXTRACTION==1)
    MISSING_ALL_RAW  = 1;
   
    %%- Missing Raw, but possibly eeg.noreref (and sync files) already generated.  Check for that here:
    extractedList = dir(fullfileEEG(rootEEGdir,subj,'eeg.noreref/*.001'));
    if (length(extractedList)==0)
        MISSING_RAW_AND_EXTRACTED = 1;
        fprintf(' RAW EEG data not found... just output EEG times to grab based on session.log files:');
    else
        fprintf(' RAW EEG data not found, but %d EEG.NOREREF extractions found. Attempting to match to session.log files',length(extractedList));
    end
    
    MISSING_ALL_SYNC = 1; %assume no sync files at all, will be set to 0 if a single sync file found
    for iList=1:length(extractedList),
        
        %- read the tagName.txt list... last entry should specify the channel with pulses (either ECG, EKG, or DC)
        if (iList==1),
            if ~exist(fullfileEEG(rootEEGdir,subj,'/docs/tagNames.txt'),'file'),
                fprintf('\n WARNING: /docs/tagNames.txt is missing. Guessing that EKG is the pulse channel.\n');
                pulseTag = 'EKG'; %assume it is EKG...
            else
                tagNameOrder = textread(fullfileEEG(rootEEGdir,subj,'/docs/tagNames.txt'),'%s%*[^\n]');
                pulseTag     = tagNameOrder{end};
            end
        end
        
        %-pull extracted root name and directory
        extract001Path = fullfileEEG(rootEEGdir, subj, 'eeg.noreref', extractedList(iList).name);
        fName = extractedList(iList).name;
        fName = fName(1:end-4); %cut out .001
        extractRootPath = fullfileEEG(rootEEGdir, subj, 'eeg.noreref', fName);
        extractedList(iList).rootName = fName;
        extractedList(iList).extractRootPath = extractRootPath;
        extractedList(iList).extract001Path  = extract001Path;
        
        %-pull extracted date/time for sorting relative to eeglog times later
        dateStr = fName(min(find(fName=='_'))+1:end);
        Cstr = textscan(fName,'%s%s%s','delimiter','_');
        extractedList(iList).dateN = datenum(dateStr,'yymmdd_HHMM',2001);  %--new version of date
        
        %-pull TTL channels from the jacksheet (used for creating sync file)
        jackFile        = sprintf('%s.jacksheet.txt',extractRootPath);
        if ~exist(jackFile,'file'), error(' ERROR: %s is missing\n', jackFile); end
        
        %-pull TTL channels from the jacksheet (used for creating sync file)
        [jackChans jackNames] = textread(jackFile,'%s %s');
        iTTLchan        = find(strncmp(jackNames,pulseTag,length(pulseTag)));  % last entry in tagNames.txt indicates sync channel
        TTLchan1        = str2num(jackChans{iTTLchan(1)});
        if length(iTTLchan)<2 | strcmp(pulseTag,'DC'),
            TTLchan2    = TTLchan1;
        else
            TTLchan2    = str2num(jackChans{iTTLchan(2)});
        end
        fileTTLchan1    = sprintf('%s.%03d',extractRootPath, TTLchan1);
        fileTTLchan2    = sprintf('%s.%03d',extractRootPath, TTLchan2);
        
        %-look for any sync file with the proper channel prefix... if not found try the predicted sync file names
        syncFileList = dir( sprintf('%s.*.sync.txt',extractRootPath) );
        if length(syncFileList)==1,
            syncFileFound = fullfileEEG(rootEEGdir,subj,'eeg.noreref',syncFileList(1).name);
        else
            if length(syncFileList)>1, fprintf('\n WARNING: more than 1 sync file found for %s. \n', extractRootPath); end
            syncFileFound = '';
        end
        
        %-look for expected specific sync file names
        syncFileExpect = sprintf('%s.%03d.%03d.sync.txt',extractRootPath, TTLchan1, TTLchan2);
        syncFile = syncFileExpect;
        if (length(dir(syncFile))==0) syncFile = sprintf('%s.%03d.%03d.sync.txt',extractRootPath, TTLchan2, TTLchan1); end
        if (length(dir(syncFile))==0) syncFile = sprintf('%s.trigDC09.sync.txt',extractRootPath); end
        if (length(dir(syncFile))==0) syncFile = syncFileExpect; end %if don't find it try the two other methods, go back to original expectation for warning/error message
        
        %-does expected file match "found" file?
        if length(syncFileFound)>0 & ~strcmp(syncFile,syncFileFound),
            fprintf('\n WARNING: found [and will use] syncFile %s, but expected %s\n', syncFileList(1).name, syncFile);
            syncFile = syncFileFound;
        end
        
        %- confirm sync file exists and save the location
        if (length(dir(syncFile))>0)  hasSync = 1; syncStr = 'sync found';   MISSING_ALL_SYNC = 0; % allow for alignment even if just 1 sync present
        else                          hasSync = 0; syncStr = 'sync MISSING'; syncFile = '';  end
        
        %- save to the extractedList
        extractedList(iList).jackChanStr = sprintf('TTL chan: %d, %d', TTLchan1, TTLchan2);
        extractedList(iList).hasSync  = hasSync;
        extractedList(iList).syncStr  = syncStr;
        extractedList(iList).syncFile = syncFile;
        extractedList(iList).pairedToAlign = 0 ; % initialize to zero here... this will be a counter of the number of behavioral files paired with this raw
        
    end
    if (MISSING_ALL_SYNC==0)
        extrTimes = [extractedList.dateN];                                    %extracted times
        syncTimes = [extractedList(find([extractedList.hasSync]==1)).dateN];  %sync times
    else
        fprintf('\n WARNING: at least 1 sync missing, but somewhat iffy code for estimating sync file name when RAW is missing... assumes pulses on "EKG".'); 
        extrTimes = [];
        syncTimes = [];
    end

else
    MISSING_ALL_RAW = 0;
    
   
    %%- create list of raw EEG times (to compare with eeglog list).
    %%-         use .21E file creation date (.EEG creation date is not the same)
    for iDay = 1:length(days)
        dayDir = fullfileEEG(rawDir,days(iDay).name);
        % check to see if multiple sesisons were done in a given day
        session = dir([dayDir '/SESS_*']);
      
        %%-- code to catch folders named "A" and "B" rather than SESS_A and SESS_B
        if isempty(session)
            dList = dir([dayDir '/*']);
            session=[];
            for iList=1:length(dList)
                if (dList(iList).isdir==1 & dList(iList).name(1)~='.')
                    session = [session dList(iList)];
                end
            end
            if (~isempty(session)) fprintf('HEADS UP: %s contains session folders without SESS_ prefix\n',days(iDay).name); end
        end
        
        if ~isempty(session)
            for k = 1:length(session)
                rawPath = fullfileEEG(dayDir,session(k).name);
                rawFile = dir(fullfileEEG(rawPath,'*.21E'));
                if (length(rawFile)>1) fprintf('HEADS UP: multiple .21E files in folder %s\n',rawPath); end
                for iRawFile=1:length(rawFile),
                    rawFile(iRawFile).rawDir  = rawPath;
                    rawFile(iRawFile).rawPath = fullfileEEG(rawPath, rawFile(iRawFile).name);
                    rawFile(iRawFile).clnPath = fullfileEEG(days(iDay).name, session(k).name, rawFile(iRawFile).name);
                    rawList = [rawList rawFile(iRawFile)];
                end
            end
        else
            rawPath = dayDir;
            rawFile = dir(fullfileEEG(rawPath,'*.21E'));
            if (length(rawFile)>1) fprintf('HEADS UP: multiple .21E files in folder %s\n',rawPath); end
            for iRawFile=1:length(rawFile),
                rawFile(iRawFile).rawDir  = rawPath;
                rawFile(iRawFile).rawPath = fullfileEEG(rawPath, rawFile(iRawFile).name);
                rawFile(iRawFile).clnPath = fullfileEEG(days(iDay).name, rawFile(iRawFile).name);
                rawList = [rawList rawFile(iRawFile)];
            end
        end
    end
    
    
    %%- if any raw found, figure out the expected extraction file name
    MISSING_EXTRACTION = 0;     % assume all extracted... switch to 1 if any files missing
    for iList=1:length(rawList)
        
        EEG_file = [rawList(iList).rawPath(1:end-3) 'EEG'];  %switch the suffix from .21E to .EEG
        if (~exist(EEG_file,'file')) error('MISSING Raw .EEG file, but .21E file found: %s',rawList(iList).rawPath); end; %% should never happen
        
        %open EEG file, skip over initial info, then pull the date and time
        %   (see nk_split for original version of the following code)
        fid = fopen(EEG_file, 'r');
        
        %1) seek to EEG1 control block to get offset to waveform block
        offsetToEEG1 = 146 ;                    % skips device info (128 byte), skips block ID (1 byte), device type (16 byte), number of blocks (1 byte)
        fseek(fid,offsetToEEG1,'bof');          % fseek(fileID, offset, origin) moves to specified position in file. bof=beginning of file
        
        %2) seek to EEG2 waveform block to get offset of actual data
        offsetToEEG2 = fread(fid,1,'*int32');
        offsetToEEG2 = offsetToEEG2 + 18 ;      % skips block ID (1 byte), device type (16 byte), number of blocks (1 byte)
        fseek(fid,offsetToEEG2,'bof');
        
        %3) seek to actual data, skip over initial info then read date/time
        blockAddress = fread(fid,1,'*int32');
        blockAddress = blockAddress + 20 ;      % skips block ID (1 byte), device type (16 byte), number of blocks (1 byte), byte length of one data (1 byte), mark/event flag (1 byte)
        fseek(fid,blockAddress,'bof');          %
        
        %%- annonomous function to convert binary to decimal.  input is binary string created with dec2bin
        bcdConverter2 = @(strDec2bin)  10*bin2dec(strDec2bin(1:4)) + bin2dec(strDec2bin(5:8));
        
        % get the start time
        T_year   = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
        T_month  = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
        T_day    = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
        T_hour   = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
        T_minute = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
        T_second = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
        %fprintf('Date of session: %d/%d/%d\n',T_month,T_day,T_year)
        %fprintf('Time at start: %02d:%02d:%02d\n',T_hour,T_minute,T_second)
        fclose(fid);
        
        % determine expected extraction root name and other extraction info (date, root, existance)
        %extractRootName = sprintf('%s_%02d%02d%02d_%02d%02d', subj,T_day,T_month,T_year,T_hour,T_minute);  % format copied from nk_split
        extractRootName = sprintf('%s_%02d%02d%02d_%02d%02d', subj,T_year,T_month,T_day,T_hour,T_minute);  % format copied from nk_split -- new version is year/month/day
        extractRootPath = fullfileEEG(rootEEGdir,subj,'eeg.noreref',extractRootName);
        extract001Path  = fullfileEEG(rootEEGdir,subj,'eeg.noreref',sprintf('%s.001', extractRootName));
        
        % following code is important when channel 001 isn't present in all recordings.
        actual001chan = 5; %- channel 5 should always be there... it is ground
        if exist(fullfileEEG(rootEEGdir,subj,'eeg.noreref'),'dir'),
            while ~exist(extract001Path,'file') & actual001chan<160,
                actual001chan=actual001chan+1;
                extract001Path = fullfileEEG(rootEEGdir,subj,'eeg.noreref',sprintf('%s.%03d', extractRootName,actual001chan));
            end
            if ~exist(extract001Path,'file'), 
                fprintf('\n >> Uh oh... not finding extracted file %s. This may be bad. Setting path to channel 005. << \n',extract001Path);
                actual001chan = 5;
                extract001Path = fullfileEEG(rootEEGdir,subj,'eeg.noreref',sprintf('%s.%03d', extractRootName,actual001chan));
            end
        end
        
        dateStr         = extractRootName(min(find(extractRootName=='_'))+1:end);
        extractDateNum  = datenum(dateStr,'yymmdd_HHMM',2001); % useful for sorting by absolute time difference
        
        rawList(iList).extractRootName = extractRootName ;  % ex) "NIH016_170613_1057"
        rawList(iList).extractRootPath = extractRootPath ;  % ex) "/Users/wittigj/DataJW/data/eeg/NIH016/eeg.noreref/NIH016_170613_1057"
        rawList(iList).extract001Path  = extract001Path  ;  % ex) "/Users/wittigj/DataJW/data/eeg/NIH016/eeg.noreref/NIH016_170613_1057.001"
        rawList(iList).extractDateNum  = extractDateNum  ;  % ex) "7.3540e+05"
       
        if (exist(extract001Path,'file') & FORCE_RAW_REEXTRACTION==0)
            rawList(iList).extracted   = 1  ;
        else
            rawList(iList).extracted   = 0  ;
            MISSING_EXTRACTION         = 1  ;
        end
        
        rawList(iList).pairedToAlign   = 0 ; % initialize to zero here... this will be a counter of the number of behavioral files paired with this raw
    end
    
    
    %%- one or more raw files not extracted... extract now
    if (MISSING_EXTRACTION)
        needsExtr = find([rawList.extracted]==0);
        fprintf(' RAW EEG data found (%d files); but missing %d of %d EEG.NOREREF files: \n',  length(rawList), length(needsExtr), length(rawList) );
        
        %-selectively extract just the missing data
        MISSING_EXTRACTION = 0;
        for iList=needsExtr,
            fprintf('>>>>>>>>>> extracting %s --> %s <<<<<<<<<<\n',rawList(iList).clnPath, rawList(iList).extractRootName);
            %- remove the patients name from the raw data (only happens when extracted)
            nknih_anon(rawList(iList).rawDir)
            %- grab the tag names and pass to nk_split
            tagNameOrder = '';
            fid          = fopen(fullfileEEG(rootEEGdir,subj,'/docs/tagNames.txt'));
            if (fid~=-1)
                foo                        = textscan(fid,'%s');
                tagNameOrder               = foo{1};
                %check to see if R, EKG, or REF are in the tag list, if so, don't add them  --- 10/2015, JW thinks this doesn't need to be a requirement anymore
                %if (sum( [[~cellfun('isempty',strfind(tagNameOrder,'R'))];  [~cellfun('isempty',strfind(tagNameOrder,'REF'))]] )==0),
                %    error('ERROR: /docs/tagNames.txt is missing REF or R... please add and re-run eegPrepAndAlign (final tagName.txt entry should be EKG or D, whichever has pulses)');
                %end
                if ( strcmp(tagNameOrder(end),'EKG')==0 & strcmp(tagNameOrder(end),'DC')==0 ),
                    fprintf('SEVERE WARNING: last entry in /docs/tagNames.txt should specify then pulse channel(s).\n  Current entry is "%s", usually pulses on "EKG" or "DC"',tageNames(end));
                end
                fclose(fid);
            end
            %keyboard
            allTags = nk_split(subj,rawList(iList).rawDir,tagNameOrder);
            if (~isempty(allTags) & fid==-1)
                fprintf('\n\n\nMissing or messed up /docs/tagNames.txt. Following is list of actual channel names from nk_split:\n');
                for iTags=1:length(allTags)
                    fprintf('%s\n',allTags{iTags})
                end
                error('create file /docs/tagNames.txt and rerun eegPrepAndAlign.m');
            end
            
            %- Now confirm that data was extracted... drop error if not
            extractPath = rawList(iList).extract001Path; 
            extractRawSet = dir([rawList(iList).extractRootPath '*']);  %- use this as a catch for when channel 001 not extracted
            MIN_RAW_SET_SIZE = 10;  %- guestimate: want to be higher than the number of trig,param,jacksheet files...
            if (exist(extractPath,'file')) | length(extractRawSet)>=MIN_RAW_SET_SIZE,  %-
                rawList(iList).extracted   = 1  ;
            else
                rawList(iList).extracted   = 0  ;
                MISSING_EXTRACTION = 1;
                fprintf('ERROR: %s not extracted to\n   %s\n',rawList(iList).clnPath, rawList(iList).extract001Path);
                error('ERROR: just extracted but at least 1 RAW not extracted.'); % should never happen.. perhaps name mismatch
            end
        end
    else
        fprintf(' RAW EEG data found (%d files); all files already extrated to EEG.NOREREF', length(rawList))
    end
    
    %%- look for sync files (generated by using alignTool to convert TTL waveforms to pulse times)
    %%-    if missing, user needs to run alignTool to get pulse times from raw TTL waveforms
    MISSING_ALL_SYNC = 1;  % assume no sync files at all, will be set to 0 if a single sync file found
    for iList=1:length(rawList),
        
        %- read the tagName.txt list... last entry should specify the channel with pulses (either ECG, EKG, or DC)
        if (iList==1),
            tagNameOrder = textread(fullfileEEG(rootEEGdir,subj,'/docs/tagNames.txt'),'%s%*[^\n]');
            pulseTag     = tagNameOrder{end};
        end
        
        %-all raw files are extracted at this point thanks to MISSING_EXTRACTION condition above... don't need to check whether extracted==1
        extractRootPath = rawList(iList).extractRootPath;
        jackFile        = sprintf('%s.jacksheet.txt',extractRootPath);
        if ~exist(jackFile,'file'), error(' ERROR: %s is missing\n', jackFile); end
        
        %-pull TTL channels from the jacksheet (used for creating sync file)
        [jackChans jackNames] = textread(jackFile,'%s %s');
        iTTLchan        = find(strncmp(jackNames,pulseTag,length(pulseTag)));  % last entry in tagNames.txt indicates sync channel
        TTLchan1        = str2num(jackChans{iTTLchan(1)});
        if length(iTTLchan)<2 | strcmp(pulseTag,'DC'),
            TTLchan2    = TTLchan1;
        else
            TTLchan2    = str2num(jackChans{iTTLchan(2)});
        end
        fileTTLchan1    = sprintf('%s.%03d',extractRootPath, TTLchan1);
        fileTTLchan2    = sprintf('%s.%03d',extractRootPath, TTLchan2);
        
        %-look for any sync file with the proper channel prefix... if not found try the predicted sync file names
        syncFileList = dir( sprintf('%s.*.sync.txt',extractRootPath) );
        if length(syncFileList)==1,
            syncFileFound = fullfileEEG(rootEEGdir,subj,'eeg.noreref',syncFileList(1).name);
        else
            if length(syncFileList)>1, fprintf('\n WARNING: more than 1 sync file found for %s. \n', extractRootPath); end
            syncFileFound = '';
        end
        
        %-look for expected specific sync file names
        syncFileExpect = sprintf('%s.%03d.%03d.sync.txt',extractRootPath, TTLchan1, TTLchan2);
        syncFile = syncFileExpect;
        if (length(dir(syncFile))==0) syncFile = sprintf('%s.%03d.%03d.sync.txt',extractRootPath, TTLchan2, TTLchan1); end
        if (length(dir(syncFile))==0) syncFile = sprintf('%s.trigDC09.sync.txt',extractRootPath); end
        if (length(dir(syncFile))==0) syncFile = syncFileExpect; end %if don't find it try the two other methods, go back to original expectation for warning/error message
        
        %-does expected file match "found" file?
        if length(syncFileFound)>0 & ~strcmp(syncFile,syncFileFound),
            fprintf('\n WARNING: found [and will use] syncFile %s, but expected %s\n', syncFileList(1).name, syncFile);
            syncFile = syncFileFound;
        end
        
        %- confirm sync file exists and save the location
        if (length(dir(syncFile))>0)  hasSync = 1; syncStr = 'sync found';   MISSING_ALL_SYNC = 0; % allow for alignment even if just 1 sync present
        else                          hasSync = 0; syncStr = 'sync MISSING'; syncFile = '';  end
        
        %- save to the rawList
        rawList(iList).jackChanStr = sprintf('TTL chan: %d, %d', TTLchan1, TTLchan2);
        rawList(iList).hasSync  = hasSync;      % ex) 1
        rawList(iList).syncStr  = syncStr;      % ex) sync found
        rawList(iList).syncFile = syncFile;     % ex) /Users/wittigj/DataJW/data/eeg/NIH016/eeg.noreref/NIH016_280613_1411.083.084.sync.txt
    end
    rawTimes  = [rawList.extractDateNum];                              % used for plotting raw vs extracted vs behavior at end... define here to differentiate from case where raw is missing but extraction exists
    extrTimes = [rawList.extractDateNum];                              % extracted times
    syncTimes = [rawList(find([rawList.hasSync]==1)).extractDateNum];  % sync times
    
    if (MISSING_ALL_SYNC || sum([rawList.hasSync])<length(rawList))
        %fprintf('\n\nAt least 1 sync file missing... USE alignTool to find TTL pulse times and create sync file\n\n');
        %- save pathdef.m for command-line instance of matlab (sans java) used to call alignTool for picking out peaks (not required... can call alignTool from graphical matlab command line)
        %savepath(fullfileEEG(rootEEGdir, subj, 'eeg.noreref/pathdef.m'))
        fprintf('; only %d sync files found in EEG.NOREREF', sum([rawList.hasSync]))
    else
        fprintf('; all sync files found in EEG.NOREREF', length(rawList))
    end
    
    
    %%- check for the jacksheetMaster.txt and create if not found.  This would normally happen during a call to nk_split, but add here for subjects that are already extracted
    fprintf('\n checking for jacksheetMaster.txt: ');
    jackMaster_file = fullfileEEG(subjDir, 'docs/jacksheetMaster.txt');
    if ~exist( jackMaster_file, 'file' ),
        if exist( fullfileEEG(subjDir,'docs/tagNames.txt'), 'file') & exist( fullfileEEG(subjDir,'docs/electrodes.m'), 'file') & exist( fullfileEEG(subjDir,'tal/leads.txt'), 'file'),
            createMasterJack(subj,rootEEGdir);
        else
            fprintf(' ...WARNING... does not exist and cannot be created because of missing doc/tagNames.txt, docs/electrodes.m, or tal/leads.txt\n');
        end
    else
        fprintf(' found\n');
    end
    
    
    %%- ATTEMPT TO RE-REFERENCE IF ALL FILES ARE IN PLACE    
    strRerefFiles{1} = 'docs/electrodes.m'   ;   % list of files required for rereferencing... check existance here to avoid partial rereferencing
    strRerefFiles{2} = 'tal/leads.txt'       ; 
    strRerefFiles{3} = 'tal/good_leads.txt'  ; 
    strRerefFiles{4} = 'tal/bad_leads.txt'   ; 
    
    MISSING_ANY_REREF_FILES = 0;
    for iRRfile = 1:length(strRerefFiles),
        if ~exist( fullfileEEG(rootEEGdir, subj, strRerefFiles{iRRfile}), 'file' )
            fprintf(' WARNING: rereferencing NOT possible because of MISSING %s\n',strRerefFiles{iRRfile});
            MISSING_ANY_REREF_FILES = 1;
        end
    end
    
    if MISSING_ANY_REREF_FILES==0,
        fprintf(' re-reference channel files if not done already:');
        try
            %%- call reref wrapper to create all rereferenced channels too. only creates files that are missing
            %       (assumes filestem presence means all rerefs have been created)
            [stemsChecked, stemsRerefed] = rerefWrapper(subj, rootEEGdir);
            fprintf(' %d of %d file stems needed to be rereferenced', stemsRerefed, stemsChecked );
        catch err
            getReport(err,'extended')
            fprintf(' WARNING: error rereferencing.');
            keyboard
        end
    end
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%-- search "behavioral" directory
%%--        pull .eeglog times from all tasks, all sessions... make eeglog.up if not created already
%%--        confirm that behavioral events.mat already created... if not, create it
%%--
behDir   = fullfileEEG(rootEEGdir,subj,'behavioral');
fprintf('\n\n[STEP 2/4] Searching behavioral directory for eeg.eeglog and events.mat files:\n');

%%- generate list of tasks
dList = dir(behDir);
taskDir=[];
for i=1:length(dList),
    if (dList(i).isdir==1 & dList(i).name(1)~='.') taskDir = [taskDir dList(i)]; end
end


%%- for each task generate list of session folders and extract the relevant info
allEEGlogs=[]; allSessionEvents=[]; taskStrAr=[]; numAlignedWithBlank=0;
for iTask = 1:length(taskDir),
    taskStr = taskDir(iTask).name ;
    taskStrAr{iTask} = taskStr;
    
        
    sessDir = dir(fullfileEEG(behDir,taskStr,'session_*'));
    if length(sessDir)<1, fprintf(' WARNING -- task folder contains no session folders:  %s\n',taskStr); end
    
    
    %%- quick loop through session directories to correctly order double digit session numbers (else 10 comes after 1 and before 2)
    sessNumAr=[];
    for iSess = 1:length(sessDir),
        sessStr     = sessDir(iSess).name;
        strNumeric  = find( sessStr >= '0' & sessStr <= '9');
        sessNum     = str2num( sessStr(strNumeric) );  if isempty(sessNum), sessNum=iSess; end; %shouldn't need this catch...
        sessNumAr(iSess) = sessNum;
    end
    if length(sessDir)>0,
        [sortVal sortInd] = sort(sessNumAr);
        sessDir = sessDir(sortInd);
    end
    
    if strcmp(taskStr,'stimMapping'), break; end
    
    for iSess = 1:length(sessDir)
        iSess
        sessStr = sessDir(iSess).name ;
        
        eeglogfStr  = fullfileEEG(behDir,taskStr,sessStr,'eeg.eeglog');
        eeglogFile  = dir(eeglogfStr);
        dateStr     = eeglogFile.date;
        dateMAT_dir = eeglogFile.datenum;  % matlab datenum from directory listing (when was file created and/or modified
        dateStr_dir = datestr(dateMAT_dir,'mm/dd/yy HH:MM PM');  %%- attempting to match format of mac info
        
        %read mstime from eeg.eeglog to get pyepl start time (instead of just file creation/modification date)
        [mstimes]   = textread(eeglogfStr,'%n%*[^\n]');  %read all ms time from the pulse file
        dateMAT_act = datenum(char(cell(javaSDF.format(Date(mstimes(1))))));  % this magic conversion relies on java 'Date' and 'SimpleDateFormat' imports at the top of the page
        dateStr_act = datestr(dateMAT_act,'mm/dd/yy HH:MM PM');  %%- attempting to match format of mac info
        dateMAT_actEnd = datenum(char(cell(javaSDF.format(Date(mstimes(end))))));  % this magic conversion relies on java 'Date' and 'SimpleDateFormat' imports at the top of the page
        
        thisEEGlog.task     = taskStr;
        thisEEGlog.taskNum  = iTask;
        thisEEGlog.sess     = sessStr;
        thisEEGlog.taskDir  = fullfileEEG(behDir,taskStr);
        thisEEGlog.taskSess = fullfileEEG(taskStr,sessStr);
        thisEEGlog.dateMAT_dir = dateMAT_dir ;
        thisEEGlog.dateStr_dir = dateStr_dir ;
        thisEEGlog.dateMAT_act = dateMAT_act ;
        thisEEGlog.dateStr_act = dateStr_act ;
        thisEEGlog.dateMAT_actEnd = dateMAT_actEnd ;
        %if abs(thisEEGlog.dateMAT_act - thisEEGlog.dateMAT_dir) > datenum('01/01/01 3:00')-datenum('01/01/01 1:00'),
        %    fprintf(' WARNING: %s date discrepmancy: %s (mstime conversion), %s (dir listing)\n',fullfileEEG(thisEEGlog.taskSess,'eeg.eeglog'),dateStr_act,dateStr_dir);  %-- check conversion from dir to actual date
        %end
        if abs(thisEEGlog.dateMAT_actEnd - thisEEGlog.dateMAT_act) > datenum('01/01/01 2:30')-datenum('01/01/01 1:00'),
            fprintf(' SERIOUS WARNING: %s date discrepancy: end time >90min different from start time %s vs %s\n',fullfileEEG(thisEEGlog.taskSess,'eeg.eeglog'),datestr(dateMAT_act,'mm/dd/yy HH:MM PM'),datestr(dateMAT_actEnd,'mm/dd/yy HH:MM PM'));  %-- check conversion from dir to actual date
            reply = input('               check session.log and eeg.eeglog file and remove spurious start times if appropriate.\n...  PRESS RETURN TO CONTINUE (break and rerun eegPrepAndAlign if eeg.eeglog has been modified)...\n');
        end
        
        % check to see if eeglog.up file already created... if not, make it
        eeglogStr   = fullfileEEG(behDir,taskStr,sessStr,'eeg.eeglog');
        eeglogUpStr = fullfileEEG(behDir,taskStr,sessStr,'eeg.eeglog.up');
        if (length(dir(eeglogUpStr))==0) fixEEGLog(eeglogStr,eeglogUpStr); end; 
        thisEEGlog.eeglogStr   = eeglogStr ;
        thisEEGlog.eeglogUpStr = eeglogUpStr ;
        
        % find the session log... alignment will created a modified version (session.log.align) that includes pointers to the eeg file
        sessionLogStr = fullfileEEG(behDir,taskStr,sessStr,'session.log');
        thisEEGlog.sessionLogStr = sessionLogStr;
        
        % load in the session log, and convert the first and last time entry into date numbers (instead of relying on directory date num) [possibly comment out following lines... no need to open/read file]
        extractSessionLogDates = 0;
        if extractSessionLogDates,
            [mstimes] = textread(sessionLogStr,'%n%*[^\n]');
            sessStartDateMAT = datenum(char(cell(javaSDF.format(Date(mstimes(1))))));  % this magic conversion relies on java 'Date' and 'SimpleDateFormat' imports at the top of the page
            sessStartDateStr = datestr(dateMAT_act,'mm/dd/yy HH:MM PM');  %%- attempting to match format of mac info
            sessEndDateMAT   = datenum(char(cell(javaSDF.format(Date(mstimes(end))))));  % this magic conversion relies on java 'Date' and 'SimpleDateFormat' imports at the top of the page
            sessEndDateStr   = datestr(dateMAT_act,'mm/dd/yy HH:MM PM');  %%- attempting to match format of mac info
            %fprintf('\n  session.log dates: %s (dir listing), %s (mstime conversion)',dateStr_dir,dateStr_act);
        end
    
        % look for events.mat... confirm whether alignment has already happened
        sessEventsStr = fullfileEEG(behDir,taskStr,sessStr,'events.mat');
        if (exist(sessEventsStr,'file')==0)
            eventsExists  = 0;
            eventsAligned = 0;
            eventsEEGfile = '';
            eventStr      = sprintf('events.mat MISSING');
        else
            eventsExists = 1;
            % events file exists... check to see whether already aligned
            events = [];
            load(sessEventsStr);
            if (isfield(events,'eegfile') & isfield(events,'eegoffset'))
                eventsAligned = 1;
                eventsEEGfile = events(1).eegfile;
                eventStr      = sprintf('events.mat aligned');
                numEmptyField = sum(strcmp({events.eegfile},''));
                if numEmptyField>0, eventStr = sprintf('%s [%d blank eegfile field]',eventStr,numEmptyField); numAlignedWithBlank = numAlignedWithBlank+1;end
            else
                eventsAligned = 0;
                eventsEEGfile = '';
                eventStr      = sprintf('events.mat NOT ALIGNED');
            end
        end
        thisEEGlog.eventsExists  = eventsExists;
        thisEEGlog.eventsAligned = eventsAligned;
        thisEEGlog.eventsEEGfile = eventsEEGfile;
        thisEEGlog.eventsFile    = sessEventsStr;
        thisEEGlog.eventsStr     = eventStr;
        
        % create list of all event logs
        allEEGlogs = [allEEGlogs thisEEGlog];
        
    end
end

%%- EVENTS MISSING: extract behavioral events now?
if ( sum([allEEGlogs.eventsExists])<length(allEEGlogs) |  FORCE_EVENT_REEXTRACTION )
    
    if (FORCE_EVENT_REEXTRACTION)
        iNeedEvents = 1:length(allEEGlogs);
        iTaskList           = [allEEGlogs(iNeedEvents).taskNum];
        [uniqTask,iUniq,iC] = unique(iTaskList);  % iUniq is index into iNeedEvents that points to unique events (i think)
        
        fprintf(' EXTRACTION of behavioral events.mat: \n      forcing (re)extraction of all %d events.mat files from %d tasks. \n      ', length(iNeedEvents), length(uniqTask));
        reply = 'Y';
    else
        iNeedEvents         = find( [allEEGlogs.eventsExists]==0 );
        iTaskList           = [allEEGlogs(iNeedEvents).taskNum];
        [uniqTask,iUniq,iC] = unique(iTaskList);  % iUniq is index into iNeedEvents that points to unique events (i think)
        
        fprintf(' EXTRACTION of behavioral events.mat. Missing %d total events.mat files from %d tasks: \n', length(iNeedEvents), length(uniqTask));
        for iList = 1:length(iUniq),
            fprintf('         %d events.mat missing from %s\n', length(find([allEEGlogs(iNeedEvents).taskNum]==allEEGlogs(iNeedEvents(iUniq(iList))).taskNum)), allEEGlogs(iNeedEvents(iUniq(iList))).task );
        end
        reply='Y';
        if (BYPASS_ALIGNMENT_USER_QUERY==0)
            reply = input('Attempt to extract missing events.mat files from session.logs now? Y/N [Y]:','s');
            if isempty(reply)
                reply = 'Y';
            end
            fprintf('\n');
        end
    end
    
    if ( reply(1)=='Y' || reply(1)=='y' )
        
        % behavioral processing does all sessions of task... only call once per task
        thisDir = pwd;
        iExtracted = [iNeedEvents];      % start with list of iNeedEvents
        for iList = 1:length(iUniq)
            thisEEGlog = allEEGlogs(iNeedEvents(iUniq(iList)));
            try
                behavioralProcessing(subj,rootEEGdir,thisEEGlog.task);  % in eeg_toolbox/events: should create events for all sessions of the selected task...
                iExtracted = [iExtracted find(strcmp({allEEGlogs.task},thisEEGlog.task))];
            catch err
                fprintf('BehavioralProcessing threw an error.\n');
                getReport(err)
            end
        end
        chdir(thisDir);
        
        % now double check to see whether events were created
        iExtracted = unique(iExtracted);  % contains all iNeedEvents + any additional events that were extracted because they were in the same task as an iNeed
        eventExtStr = '\n';
        for iList = iExtracted,
            thisEEGlog = allEEGlogs(iList);
            
            % look for events.mat... confirm whether alignment has already happened
            sessEventsStr = thisEEGlog.eventsFile;
            padTaskStr = sprintf('%s/%s',thisEEGlog.task, thisEEGlog.sess);
            padTaskStr(end+1:25) = ' ';
            if (exist(sessEventsStr,'file')==0)
                eventExtStr    = sprintf('%s WARNING: %s  NOT extracted\n', eventExtStr, padTaskStr);
            else
                %eventExtStr    = sprintf('%s%s  extracted\n',     eventExtStr, padTaskStr);
                eventStr       = sprintf('events.mat NOT ALIGNED');
                
                allEEGlogs(iList).eventsStr     = eventStr;
                allEEGlogs(iList).eventsExists  = 1;
                allEEGlogs(iList).eventsAligned = 0; % can't be aligned if just extracted
        
            end
        end
        fprintf(eventExtStr)
    end
end
fprintf(' BEHAVIORAL EEG.EEGLOG found (%d files); %d events.mat files found', length(allEEGlogs), sum([allEEGlogs.eventsExists]) );



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%-- PREP-ALIGNMENT: attempt to match eeglog times with raw times
%%--        - check to see whether "alignmentParing_force.txt" exists.. if so, use that to chose alignment pairs
%%--        - otherwise, automatically chose pairs by identifying gap > 1h between eeglog times and label those gaps as "isNewSession"
%%--         try to match raw file times with "NewSession" eeglogs
%%--
fprintf('\n\n[STEP 3/4] Preparing for alignment: identify pairings of eeg.eeglog <--> extracted sync pulses:\n');

%%- define delta time thresh for auto detection (will be ignored if alignment pairs are forced
deltaTimeThresh   = datenum('01/01/01 2:00')-datenum('01/01/01 1:00');  %any tasks>1h apart are likely from different sessions
[allDatesS,iLogs] = sort([allEEGlogs.dateMAT_act]);


%%- check for ALIGNMENT_PAIRS: read "alignmentPairing_force.txt" which lists attempted pairs. a precursor to this file is generated automatically if it's not found
fileForcedAlign = fullfileEEG(behDir,'alignmentPairing_forced.txt');
FORCE_PAIRS = 0;
if exist(fileForcedAlign,'file'),
    fid = fopen(fileForcedAlign,'r');
    x = textscan(fid,'%s [ %[^]] ] <--> %s [ %[^]] ]');  %x is 4 cell arrays, one with beh_dir, beh_date, eeg_root, eeg_date
    fclose(fid);
    
    iListAr=1:find(strcmp(x{1},'***'))-1;  %look at all entries up to the '*****' row
    forcePairs = [];
    for iList=iListAr,
        this_behSession_dir  = x{1}{iList};
        this_eegExtract_root = x{3}{iList};
        
        this_behSession_dir(find(this_behSession_dir=='\')) = '/';  % shouldn't be necessary for any extraction using fullfileEEG, but older extractions from PC may have backslash
        
        iEegLog = find(strcmp({allEEGlogs.taskSess}, this_behSession_dir));
        if MISSING_ALL_RAW==0,
            iRawOrExtrList = find(strcmp({rawList.extractRootName}, this_eegExtract_root));
        else
            iRawOrExtrList = find(strcmp({extractedList.rootName}, this_eegExtract_root));
        end
        forcedPairs(iList,1:2) = [iEegLog iRawOrExtrList];
    end
    
    if size(forcedPairs,1)~=length(iLogs),
        error(' ERROR: alignmentPairing_forced.txt contains %d pairs, but %d eeg.eeglog files have been found! \nAll pairs must be specified\n', size(forcedPairs,1),length(iLogs));
    else
        fprintf(' Using FORCED Alignment Pairs (%d pairs specified in %s)\n', size(forcedPairs,1), fileForcedAlign);
    end
    FORCE_PAIRS = 1;
end


%%- loop through behavioral eeglogs (ordered by date, not task), and find the raw file with the closest date (unless alignmentPairing_force.txt overrides)
for iL=1:length(iLogs),
    if (iL==1)
        allEEGlogs(iLogs(iL)).deltaT = 999 ;
    else
        allEEGlogs(iLogs(iL)).deltaT = allEEGlogs(iLogs(iL)).dateMAT_act - allEEGlogs(iLogs(iL-1)).dateMAT_act;
    end
    if (allEEGlogs(iLogs(iL)).deltaT > deltaTimeThresh) isNewSess = 1;
    else                                                isNewSess = 0; end;
    allEEGlogs(iLogs(iL)).isNewSession = isNewSess;
    
    %- if forced_pairs makes this raw different from the preceding raw, isNewSess should be triggered!
    if FORCE_PAIRS & iL>1, 
        %keyboard
        thisForcedSess = forcedPairs(find(forcedPairs(:,1)==iLogs(iL)),2);
        lastForcedSess = forcedPairs(find(forcedPairs(:,1)==iLogs(iL-1)),2);
        if  thisForcedSess ~= lastForcedSess, isNewSess = 1; 
        else                                  isNewSess = 0;  end;
    end
        
    rawStr = '';
    strAdd=sprintf('.................................................................................\n');
    if (isNewSess & MISSING_ALL_RAW==0)
        %-find the matching raw file
        diffList = allEEGlogs(iLogs(iL)).dateMAT_act - extrTimes;   %% 
        iList = find(abs(diffList)<deltaTimeThresh);
        
        if FORCE_PAIRS & ~isempty(find(forcedPairs(:,1)==iLogs(iL))), iList = forcedPairs(find(forcedPairs(:,1)==iLogs(iL)),2); end
            
        if (length(iList)==0)
            iList = find(abs(diffList)<deltaTimeThresh*2);
            fprintf(' WARNING: NO RAW FOUND WITHIN 1 HOUR OF EEGLOG %s/%s\n                  ... TRYING 2 HOURS --> %d found\n',allEEGlogs(iLogs(iL)).task,allEEGlogs(iLogs(iL)).sess, length(iList));
        end
        if (length(iList)==0)
            iList = find(abs(diffList)<deltaTimeThresh*3);
            if (length(iList)>0) strWarn = '[COULD BE WRONG RAW; CONFIRM HAS PULSES]';
            else                 strWarn = '[RAW APPEARS TO BE MISSING]'; end
            fprintf('                  ... TRYING 3 HOURS --> %d found %s\n',length(iList),strWarn);
        end
        if (length(iList)>1)
            fprintf(' WARNING: MATCHED MULTIPLE RAW FILES TO EEGLOG %s/%s\n',allEEGlogs(iLogs(iL)).task,allEEGlogs(iLogs(iL)).sess);
            [delt, iList] = min(abs(diffList));
        end
        if (length(iList)>0)
            rawStr          = sprintf('%s>>%s  %s \t<<-- raw found, %s\n', strAdd, datestr(rawList(iList).extractDateNum,'mm/dd/yy HH:MM PM'), rawList(iList).clnPath, rawList(iList).syncStr);
            hasRaw          = 1 ;
            thisRawIndex    = iList; 
            thisExtractRoot = rawList(iList).extractRootName;
            thisExtract001  = rawList(iList).extract001Path;
            thisSyncFile    = rawList(iList).syncFile;  %can have a syncFile path even if it doesn't exist
            thisExtractDate = rawList(iList).extractDateNum;
            rawList(iList).pairedToAlign = rawList(iList).pairedToAlign+1;
            if (rawList(iList).hasSync==0)
                rawStr      = sprintf('%s--- need to run alignTool on %s, %s --- \n', rawStr, rawList(iList).extractRootName, rawList(iList).jackChanStr);
                hasSync     = 0 ;
            else
                hasSync     = 1 ;
            end
        else                        % matched raw not found
            rawStr = sprintf('%s>>****************************************** \t<<-- raw MISSING\n',strAdd) ;
            hasRaw          = 0 ;
            hasSync         = 0 ;
            thisRawIndex    = -1; 
            thisExtractRoot = '';
            thisExtract001  = '';
            thisSyncFile    = '';
            thisExtractDate = nan;
        end
    elseif (isNewSess & MISSING_ALL_RAW==1)     % no raw's found
        
        rawStr = sprintf('%s>>****************************************** \t<<-- raw MISSING\n',strAdd) ;
        hasRaw          = 0 ;
        hasSync         = 0 ;
        thisRawIndex    = -1; 
        thisExtractRoot = '';
        thisExtract001  = '';
        thisSyncFile    = '';
        thisExtractDate = nan;
        
        
        %-no raw file, but extracted files (and sync files) could exist
        if (MISSING_ALL_SYNC==0)
            diffList = allEEGlogs(iLogs(iL)).dateMAT_act - extrTimes;
            iList = find(abs(diffList)<deltaTimeThresh*2);  %give double the amount of time for extracted files
         
            if FORCE_PAIRS & ~isempty(find(forcedPairs(:,1)==iLogs(iL))), iList = forcedPairs(find(forcedPairs(:,1)==iLogs(iL)),2); end
        
            if (length(iList)>1)
                fprintf(' WARNING: MATCHED MULTIPLE EXTRACTED/SYNC FILES TO AN EEGLOG %d\n',iLogs(iL));
                [delt, iList] = min(diffList);
            end
            if (length(iList)>0)
                rawStr          = sprintf('%s>>%s  %s \t<<-- Extracted found; %s\n', rawStr, datestr(extrTimes(iList),'mm/dd/yy HH:MM PM'), extractedList(iList).rootName, extractedList(iList).syncStr);
                hasSync         = 1 ;
                thisExtractRoot = extractedList(iList).rootName;
                thisExtract001  = extractedList(iList).extract001Path;
                thisSyncFile    = extractedList(iList).syncFile;  %can have a syncFile path even if RAW doesn't exist
                thisExtractDate = extractedList(iList).dateN;
                extractedList(iList).pairedToAlign = extractedList(iList).pairedToAlign+1;
            end    
        end
    end
    
    % associate raw data with task file: hasSync/SyncFile/ExtractFile only updated for new sessions
    allEEGlogs(iLogs(iL)).rawStr          = rawStr;
    allEEGlogs(iLogs(iL)).hasRaw          = hasRaw ;         % 1 or 0
    allEEGlogs(iLogs(iL)).hasSync         = hasSync ;        % 1 or 0
    allEEGlogs(iLogs(iL)).rawListIndex    = thisRawIndex ;   % -1 (if no raw), else index to rawList
    allEEGlogs(iLogs(iL)).extractRootName = thisExtractRoot; % ex) /Users/wittigj/DataJW/data/eeg/NIH016/eeg.noreref/NIH016_130617_1057
    allEEGlogs(iLogs(iL)).extract001Path  = thisExtract001;  % ex) /Users/wittigj/DataJW/data/eeg/NIH016/eeg.noreref/NIH016_130617_1057.001
    allEEGlogs(iLogs(iL)).syncFilePath    = thisSyncFile;    % ex) /Users/wittigj/DataJW/data/eeg/NIH016/eeg.noreref/NIH016_130617_1057.083.084.sync.txt
    allEEGlogs(iLogs(iL)).extractDateN    = thisExtractDate; % matlab datenum, should match up with extracted channel file name root (e.g., NIH016_130617 --> 06/17/2013)
end



%%- ALIGNMENT_PAIRS: create "alignmentPairing_auto.txt" which lists attempted pairs.  this file can be altered and saved as "alignmentPairing_forced.txt" to override auto pairs 
if FORCE_PAIRS==0, fileAlignmentPairs = sprintf('%s/alignmentPairing_auto.txt',behDir);
else               fileAlignmentPairs = sprintf('%s/alignmentPairing_forcedUsed.txt',behDir);
end
fid = fopen(fileAlignmentPairs,'w+');
for iList=1:length(allEEGlogs),
    thisEEGlog = allEEGlogs(iList);
    
    % output the behavioral directory and extracted file root... these can be rearranged to override auto pairs
    behSession_dir   = thisEEGlog.taskSess ;         % ex) playPass/session_7
    eegExtract_root  = thisEEGlog.extractRootName ;  % ex) NIH016_280613_1411
    
    
    behSession_dateStr = thisEEGlog.dateStr_act ; 
    %should be able to get date number by searching rawList or extractedList... as long as raw pair was found!
    eegExtract_dateStr = '';
    if thisEEGlog.hasRaw, eegExtract_dateStr = datestr(thisEEGlog.extractDateN,'mm/dd/yy HH:MM PM'); end; 
        
        
    % output to file and command line
    fprintf(fid, '%s [%s]\t <-->  %s [%s]\n', behSession_dir, behSession_dateStr,eegExtract_root,eegExtract_dateStr);
    %fprintf(     '%s [%s]\t <-->  %s [%s]\n', behSession_dir, behSession_dateStr,eegExtract_root,eegExtract_dateStr);
end
fprintf(fid, '\n*** completed list of extracted raw files [and dates] below... paste above then resave as "alignmentPairing_forced.txt" to force different pairs  ***\n');
%fprintf(     '\n*** completed list of extracted raw files (and dates) ***\n');
extractedString = {''};
for iList=1:length(rawList)+length(extractedList)
    if length(rawList)>0,
        thisExtractRoot = rawList(iList).extractRootName;
        thisExtractDate = datestr(rawList(iList).extractDateNum,'mm/dd/yy HH:MM PM');
    else
        thisExtractRoot = extractedList(iList).rootName;
        thisExtractDate = datestr(extractedList(iList).dateN,'mm/dd/yy HH:MM PM');
    end
    extractedString{iList} = sprintf('%s [%s]\n', thisExtractRoot,thisExtractDate);
    %fprintf(fid, '%s [%s]\n', thisExtractRoot,thisExtractDate);
    %fprintf(     '%s [%s]\n', thisExtractRoot,thisExtractDate);
end  
orderedString = sort(extractedString);  %- this way they are listed in chronological order... easier to find targets
fprintf(fid,'%s',orderedString{:});
fclose(fid);
fprintf(' Alignment Pairing List saved to file %s\n   (modify and save as "alignmentPairing_forced.txt" to override auto-pairs)',fileAlignmentPairs);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%-- ALIGNMENT and Updating Master EVENTS.mat
%%--         give user option to run alignment on any un-aligned pairs of behavioral & eeg files
%%--         propogate newly aligned events.mat files from each session to the aggregtaed events.mat for the task
%%--
fprintf('\n\n[STEP 4/4] Alignment: confirm all events.mat aligned; offer alignment if not:\n');

if FORCE_REALIGNMENT, 
    fprintf(' (forcing realignment of all alignable events)\n'); 
    iNeedAlign = find([allEEGlogs.eventsExists]==1 & [allEEGlogs.hasSync]==1 & [allEEGlogs.eventsAligned]==1);
    for iList = iNeedAlign, allEEGlogs(iList).eventsAligned = 0; end 
end


%%- ALIGNMENT CHECK: are there any files that could/should be aligned?  If so, ask user if that is desirable
iNeedAlign   = find([allEEGlogs.eventsExists]==1 & [allEEGlogs.hasSync]==1 & [allEEGlogs.eventsAligned]==0);
iJustAligned = [];
if ( length(iNeedAlign)>0 )
    
    fprintf('\nALIGNMENT of behavior to physio clock. %d events.mat can be aligned: \n', length(iNeedAlign));
    for iList = iNeedAlign,
        fprintf('         %s\n', fullfileEEG(allEEGlogs(iList).task, allEEGlogs(iList).sess, 'events.mat') );
    end
    reply='Y';
    if (BYPASS_ALIGNMENT_USER_QUERY==0)
        reply = input('      Align now? Y/N [Y]:','s');
        if isempty(reply)
            reply = 'Y';
        end
        fprintf('\n');
    end
    
    if (reply(1)=='Y' || reply(1)=='y')
        
        %%- ALIGNMENT: Loop through Tasks/Sessions and align any events files that still need alignment
        fid = fopen(sprintf('%s/alignmentStats.txt',behDir),'a+');
        fprintf(fid,'\n\n=================================================================================================================');
        fprintf(fid,'\n=========================== Alignment stats from eegPrepAndAlign on %s ===========================', datestr(now,'mm/dd/yy HH:MM PM'));
        fprintf(fid,'\n=================================================================================================================');
        
        alignStr = '\nAlignment Summary:\n';
        for iList = iNeedAlign,
            
            thisEEGlog = allEEGlogs(iList);
            
            %%- if (events not aligned & events exist (means eeglog exists) & sync exist (means chan extracted)
            if ( thisEEGlog.eventsAligned==0  &  thisEEGlog.eventsExists==1  &  thisEEGlog.hasSync==1 )
                
                behSync_file = thisEEGlog.eeglogUpStr ;     % ex) /Users/wittigj/DataJW/data/eeg/NIH016/behavioral/playPass/session_7/eeg.eeglog.up
                eegSync_file = thisEEGlog.syncFilePath ;    % ex) /Users/wittigj/DataJW/data/eeg/NIH016/eeg.noreref/NIH016_280613_1411.083.084.sync.txt
                eegChan_file = thisEEGlog.extract001Path ;  % ex) /Users/wittigj/DataJW/data/eeg/NIH016/eeg.noreref/NIH016_280613_1411.001
                events_file  = thisEEGlog.eventsFile ;      % ex) /Users/wittigj/DataJW/data/eeg/NIH016/behavioral/playPass/session_7/events.mat
                
                %keyboard
                %- pass the session log and pulse log so alignment adds info to those too (helpful if necessary to split session across two raw files
                singleLog_file = {events_file};
                multiLog_files = {thisEEGlog.eventsFile thisEEGlog.sessionLogStr thisEEGlog.eeglogStr};
                cellOfLogs     = multiLog_files ; % singleLog_file  or  multiLog_files
                
                % get the samplerate
                sampleRate = GetRateAndFormat(eegChan_file);  
                if isempty(sampleRate), error('ERROR: GetRateAndFormat did not return a sampleRate.  Is params.txt present?'); end
                fprintf(     '\n>>>>>>>>>> alignment of [%s] and [%s] <<<<<<<<<<\n', fullfileEEG(thisEEGlog.task, thisEEGlog.sess), eegSync_file(strfind(eegSync_file,'eeg.noreref')+12:end));
                fprintf(fid, '\n-------------------------------------\n...alignment of [%s] and [%s]...\n', fullfileEEG(thisEEGlog.task, thisEEGlog.sess), eegSync_file(strfind(eegSync_file,'eeg.noreref')+12:end));
                
                % run the alignment
                alignmentWarning = 0;
                try
                    moreAccurateAlign = 0 ; %much slower if set to 1
                    alignInfo = runAlign(sampleRate, {behSync_file}, {eegSync_file}, {eegChan_file}, cellOfLogs, 'mstime', 0, 0, moreAccurateAlign);
                    fprintf(fid, '%s\n%s\n%s\n', alignInfo.strPulseAlign, alignInfo.strStats, alignInfo.strWarning);
                    if ~isempty(strfind(alignInfo.strWarning,'WARNING')), alignmentWarning = 1; end
                catch err
                    report = getReport(err, 'basic','hyperlinks','off');
                    fprintf(     'runAlign threw an error: %s\n', report);
                    fprintf(fid, 'runAlign threw an error: %s\n', report);
                    alignmentWarning = 1;
                end
                
                % query the user so each alignment is confirmed if a warning came up
                if alignmentWarning==1 & BYPASS_ALIGNMENT_USER_QUERY==0,
                    reply = input(sprintf('\nConfirm that alignment results look OK: \n Is Max. Dev. < 5 ms?   Is R^2 > 0.98?   Are all events aligned?\n If not, type "N" to break so you can take a closer look at %s/%s: [Y]', thisEEGlog.task, thisEEGlog.sess) ,'s');
                    if (isempty(reply)) reply = 'Y'; end
                    if (reply(1)=='N' | reply(1)=='n')
                        fclose(fid);
                        error('--force break from eegPrepAndAlign.m so failed alignment can be examined--');
                    end
                end
                fprintf('\n');
                
                % confirm events file modified
                events = [];
                load(events_file);
                if (isfield(events,'eegfile') & isfield(events,'eegoffset'))
                    alignStrMod = '';
                    if FORCE_ALIGNMENT_TO_SERVER_PATH,
                        for iEv=1:length(events),
                            events(iEv).eegfile = regexprep(events(iEv).eegfile, fullfileEEG(rootEEGdir,subj,''), fullfileEEG(serverDataPath,subj,'')); %
                        end
                        alignStrMod = ' [to server]'; 
                        saveEvents(events,events_file);
                    end
                    allEEGlogs(iList).eventsAligned = 1;
                    allEEGlogs(iList).eventsEEGfile = events(1).eegfile;
                    allEEGlogs(iList).eventsStr     = sprintf('events.mat aligned%s',alignStrMod);
                    alignStr                        = sprintf('%s  -%s/%s aligned%s\n', alignStr, thisEEGlog.task, thisEEGlog.sess,alignStrMod);
                    iJustAligned = [iJustAligned iList];
                else
                    allEEGlogs(iList).eventsStr     = sprintf('events.mat FAILED ALIGNMENT');
                    alignStr                        = sprintf('%s  -%s/%s alignment FAILED!!!\n', alignStr, thisEEGlog.task, thisEEGlog.sess);
                    %error('ERROR: Event not aligned... not sure why:\n\n%s',alignStr);  %This shouldn't happen, unless perhaps above Catch found an error too
                end
            end
        end
        fprintf(alignStr);
    end
    fprintf('\n');
end


%%- CHECK MASTER EVENTS.MAT: if not aligned, aggregate aligned events structures together
if (FORCE_MASTER_EVENTS_UPDATE | length(iJustAligned)>0)
    fprintf('\nCONCATENATED EVENTS: confirming master events.mat exists and is aligned\n');
    
    if (FORCE_MASTER_EVENTS_UPDATE) taskList = unique([allEEGlogs.taskNum]);
    else                            taskList = unique([allEEGlogs(iJustAligned).taskNum]); end
    for iTask = taskList
        
        % find all events from a single task
        numSess = length( find([allEEGlogs.taskNum] == iTask) ) ;
        iListAr = find( [allEEGlogs.taskNum] == iTask  &  [allEEGlogs.eventsAligned] ) ;
        if (length(iListAr)>0)
            % aggregate aligned events together
            allEvents    = [];
            for iList = iListAr,
                eventFile = allEEGlogs(iList).eventsFile;
                events = [];
                load(eventFile);
                allEvents=[allEvents, events];
            end
            
            % even if master events exists overwrite because this alignment could be an improvement
            eventMaster = fullfileEEG(rootEEGdir,subj,'behavioral',allEEGlogs(iListAr(1)).task,'events.mat');
            events = allEvents;
            fid = fopen(eventMaster,'w');
            if fid==-1, error(sprintf('ERROR: cannot save master events file %s', eventMaster)); end
            save(eventMaster, 'events', '-v7'); %- version 7 file format is compact... only need version 7.3 if >2GB
            
            % output result of check to terminal... everything OK?
            if (length(iListAr)<numSess) strMiss='<< MISSING SESSION'; else strMiss=''; end
            padStr = sprintf('%s/events.mat', allEEGlogs(iListAr(1)).task); padStr(end+1:25)=' ';
            fprintf('  aligned: %s (%d events; from %d of %d sessions) %s\n', padStr, length(events), length(iListAr), numSess, strMiss);
            
        end
    end
    
    %-- changes eegfile in events to point at the reref directory [this dones't really make sense here... should be done later so files point to server]
    fprintf('\n');
    
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%-- Text output pretty list for Kareem to use for grabbing raw files
%%--
%%--
fprintf('\n\n[SUMMARY] Prep and Align Results:\n');

fid = fopen(sprintf('%s/alignmentSummary.txt',behDir),'w+');
fprintf(fid,'List of EEG times (grabbed from all tasks, all times):\n');


%%- sort all the date/times for easier-to-read output
fprintf(fid,'\n\nSorted by task/session:\n');
%fprintf(    '\n\nSorted by task/session:\n');
for iList=1:length(allEEGlogs),
    thisEEGlog = allEEGlogs(iList);
    padTaskStr = sprintf('%s/%s',thisEEGlog.task, thisEEGlog.sess);
    padTaskStr(end+1:21) = ' ';
    
    % output to file and command line
    fprintf(fid, '  %s \t %s   -%s\n', padTaskStr, thisEEGlog.dateStr_act, thisEEGlog.eventsStr);
    %fprintf(     '  %s \t %s   -%s\n', padTaskStr, thisEEGlog.dateStr_act, thisEEGlog.eventsStr);
end


%%- same as above, but sorted by time
fprintf(fid,'\n\nSorted by time (and grouped by EEG session):\n');
fprintf(    '\nSORTED BEHAVIORAL DATA (sorted by date/time and grouped by EEG session):\n');
[allDatesS,iLogs] = sort([allEEGlogs.dateMAT_act]);
for iList=iLogs,
    thisEEGlog = allEEGlogs(iList);
    strAdd     = thisEEGlog.rawStr;
    padTaskStr = fullfileEEG(thisEEGlog.task, thisEEGlog.sess);   padTaskStr(end+1:25)=' ';
    
    % output to file and command line
    fprintf(fid, '%s  %s  %s \t<<-- %s\n', strAdd, thisEEGlog.dateStr_act, padTaskStr, thisEEGlog.eventsStr);
    fprintf(     '%s  %s  %s \t<<-- %s\n', strAdd, thisEEGlog.dateStr_act, padTaskStr, thisEEGlog.eventsStr);
end


%%- indicate any RAW that exists but ISN'T USED
fprintf(fid, '\n---------------------------------------------------------------------------------\n');
fprintf(     '\n---------------------------------------------------------------------------------\n');
iListExtAr = [];  iListRawAr = [];  numUnpairedRaw = 0;
if MISSING_RAW_AND_EXTRACTED==0,
    if MISSING_ALL_RAW==1, iListExtAr = find([extractedList.pairedToAlign]==0);
    else                   iListRawAr = find([rawList.pairedToAlign]==0);  end
    if length(iListExtAr)+length(iListRawAr)==0,
        fprintf(fid, '>>All %d raw and/or extracted channel files paired with at least 1 eeg.eeglog', length(rawList)+length(extractedList));
        fprintf(     '>>All %d raw and/or extracted channel files paired with at least 1 eeg.eeglog', length(rawList)+length(extractedList));
    else
        fprintf(fid, '>>WARNING: %d of %d raw and/or extracted channel files NOT paired with any eeg.eeglog:\n', length(iListExtAr)+length(iListRawAr), length(rawList)+length(extractedList));
        fprintf(     '>>WARNING: %d of %d raw and/or extracted channel files NOT paired with any eeg.eeglog:\n', length(iListExtAr)+length(iListRawAr), length(rawList)+length(extractedList));
        for iList=iListExtAr,
            fprintf(fid, '   %s  %s\n', datestr(extractedList(iList).dateN,'mm/dd/yy HH:MM PM'),    extractedList(iList).rootName);
            fprintf(     '   %s  %s\n', datestr(extractedList(iList).dateN,'mm/dd/yy HH:MM PM'),    extractedList(iList).rootName);
        end
        for iList=iListRawAr,
            numUnpairedRaw = numUnpairedRaw+1;
            fprintf(fid, '   %s  %s\n', datestr(rawList(iList).extractDateNum,'mm/dd/yy HH:MM PM'), rawList(iList).clnPath);
            fprintf(     '   %s  %s\n', datestr(rawList(iList).extractDateNum,'mm/dd/yy HH:MM PM'), rawList(iList).clnPath);
        end
    end
end


%%- a list of the raw dates (and associated extractions), sorted by time
fprintf(fid,'\n\nRAW data already saved to server:\n');
%fprintf(    '\n\nRAW data already saved to server:\n');
for iList=1:length(rawList),
    outStr = sprintf('  %s  %s', datestr(rawList(iList).extractDateNum,'mm/dd/yy HH:MM PM'), rawList(iList).clnPath);
    outStr(end+1:46) = ' '; % pad so text aligns to right
    
    if ispc, outStr(find(outStr=='\'))='/'; end % avoid Warning with PC version of matlab that "Escape sequence 'B' is not valid
    
    fprintf(fid, outStr);   % output to eegTimes textfile
    %fprintf(     outStr);   % also output to command line
    
    %also output associated sync file names (or instruct how to create)
    if (rawList(iList).extracted)
        if (rawList(iList).hasSync) fullSyncStr = sprintf(' [%s: %s]', rawList(iList).syncStr, rawList(iList).syncFile(max(find(rawList(iList).syncFile=='/' | rawList(iList).syncFile=='\'))+1:end)) ;
        else                        fullSyncStr = sprintf(' [%s!] \n   -->> generate sync with alignTool on %s, %s <<--', rawList(iList).syncStr, rawList(iList).extractRootName, rawList(iList).jackChanStr);  end
        
        fprintf(fid, '     -%s \n', fullSyncStr);
        %fprintf(     '     -%s \n', fullSyncStr);
    else
        error('Shouldnt be possible to get here... raw always extracted above...')
    end
end


%%- Summary Counts
numTaskSess = length(       allEEGlogs                                                   );
numAligned  = length( find([allEEGlogs.eventsAligned]==1                               ) );
numNeedEvnt = length( find([allEEGlogs.eventsAligned]==0 & [allEEGlogs.eventsExists]==0) );
numNeedRaw  = length( find([allEEGlogs.eventsAligned]==0 & [allEEGlogs.hasRaw]==0      ) );
numNeedSync = length( find([allEEGlogs.eventsAligned]==0 & [allEEGlogs.hasSync]==0     ) );
numCldAlign = length (find([allEEGlogs.eventsAligned]==0 & [allEEGlogs.eventsExists]==1 & [allEEGlogs.hasSync]==1) );
if numAlignedWithBlank>0, strAlignedWithBlank = sprintf(' [%d events.mat with at least 1 blank eegfile field]', numAlignedWithBlank); else strAlignedWithBlank = ''; end
fprintf(fid, '\n\nSUMMARY: %02d of %02d task-sessions aligned %s \n         %02d missing events.mat \n         %02d missing eeg RAW data \n         %02d missing eeg sync\n         %02d alignment possible \n         %02d unpaired eeg RAW data', numAligned, numTaskSess, strAlignedWithBlank, numNeedEvnt, numNeedRaw, numNeedSync, numCldAlign, numUnpairedRaw);
fprintf(     '\n\nSUMMARY: %02d of %02d task-sessions aligned %s \n         %02d missing events.mat \n         %02d missing eeg RAW data \n         %02d missing eeg sync\n         %02d alignment possible \n         %02d unpaired eeg RAW data', numAligned, numTaskSess, strAlignedWithBlank, numNeedEvnt, numNeedRaw, numNeedSync, numCldAlign, numUnpairedRaw);


fclose(fid);
fprintf('\n\nTimes saved to %s \n', fullfileEEG(behDir,'alignmentSummary.txt'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%  Also create text output that matches format of README.txt
fileHelper = sprintf('%s/readme_helper.txt',behDir);
fid = fopen(fileHelper,'w+');
if fid==-1, fprintf('ERROR: could not create and/or open %s.  Confirm that you have write access and rerun eegPrepAndAlign', fileHelper); error('ERROR: cant create/write file'); end
fprintf(fid,'\nPREP and ALIGN OUTPUT (sorted by date/time): to easily import to subjects README.txt\n');
[allDatesS,iLogs] = sort([allEEGlogs.dateMAT_act]);
for iList=iLogs,
    thisEEGlog = allEEGlogs(iList);
    
    syncChan = '??';  rawFilePath = '???';
    if thisEEGlog.hasRaw,
        thisRawFile = rawList(thisEEGlog.rawListIndex);
        syncChan    = thisRawFile.jackChanStr;
        rawFilePath = sprintf('%s --> %s', fullfileEEG(subj,'raw',thisRawFile.clnPath), thisRawFile.extractRootName);
    end
    syncFile = '??';
    if thisEEGlog.hasSync,
        [syncPath, syncFile, syncExt] = fileparts(thisEEGlog.syncFilePath);
        syncFile = sprintf(' [%s%s]', syncFile, syncExt);
    end
    
    behavDataDir = fullfileEEG('/eeg', subj, 'behavioral', thisEEGlog.taskSess);
    
    fprintf(fid, '\n-------------------------------------------------------------------\n');
    fprintf(fid, '%s\n',                    datestr(thisEEGlog.dateMAT_act, 'mm/dd/yyyy'));  %
    fprintf(fid, 'Task: %s\n',              thisEEGlog.task );
    fprintf(fid, 'Session: %s\n',           thisEEGlog.sess );
    fprintf(fid, 'Start: %s\n',             datestr(thisEEGlog.dateMAT_act, 'HH:MM PM') );
    fprintf(fid, 'End: %s\n',               datestr(thisEEGlog.dateMAT_actEnd, 'HH:MM PM') );
    fprintf(fid, 'Sync: %s %s\n',           syncChan, syncFile );
    fprintf(fid, 'Behavioral data: %s\n',   behavDataDir );
    fprintf(fid, 'Clinical EEG data: %s\n', rawFilePath );
    fprintf(fid, 'Testers: ??? \n');
    fprintf(fid, 'Notes: ??? \n');
    
end
fclose(fid);
fprintf('Times also saved to %s \n', fullfileEEG(behDir,'README_helper.txt'));
fprintf('******************************** %s *****************************\n\n', subj);



%%%%% Prompt user to create pulse align figure if all raws are accounted for but pulse figure is missing
if numNeedRaw==0 & ~exist(fullfileEEG(rawDir,'align_PlotPulseChannels.png'),'file') & BYPASS_ALIGNMENT_USER_QUERY==0,
    fprintf(' NOTE: raw directory is missing pulse screenshot ''align_PlotPulseChannels.png''\n');
    
    tagNameOrder = textread(fullfileEEG(rootEEGdir,subj,'/docs/tagNames.txt'),'%s%*[^\n]');
    pulseTag     = tagNameOrder{end};
    if strcmp(pulseTag,'DC'),  pulseChan = {'DC09'};
    else                       pulseChan = {sprintf('%s2',pulseTag),sprintf('%s1',pulseTag)}; end
    
    fprintf('       guessing (based on last entry in docs/tagNames.txt) that pulse channel(s) are: ');
    for iPC=1:length(pulseChan), fprintf('%s ',pulseChan{iPC}); end
    reply = input('\n       Run pulseVisualize now to make the screenshot using these pulse channel(s)? Y/N [N]:','s');
    if isempty(reply), 
        reply(1) = 'N'; 
    end
    if upper(reply(1))=='Y',  
        eegPulseVisualize(rawDir, pulseChan);
    end
    fprintf('\n');
end

            
%%%%% Make sure eventEegFilePaths.txt is created once everything is aligned.  If any events just aligned recreate 
%if numAligned==numTaskSess &  FORCE_ALIGNMENT_TO_SERVER_PATH==0  &  length(iJustAligned)>0 || ~exist(fullfileEEG(behDir,'eventEegFilePaths.txt'),'file'),
if numAligned==numTaskSess &  length(iJustAligned)>0 || ~exist(fullfileEEG(behDir,'eventEegFilePaths.txt'),'file'),
    if  ~exist(fullfileEEG(behDir,'eventEegFilePaths.txt'),'file'),
        fprintf(' NOTE: behavioral directory is missing ''behavioral/eventEegFilePaths.txt''... will generate using changeEventsEegFile now:\n');
    else
        fprintf(' NOTE: one or more experiments just aligned; updating ''behavioral/eventEegFilePaths.txt'' using changeEventsEegFile now:\n');
    end
        
    [uniqueEegFilePaths] = changeEventsEegFile(subj, rootEEGdir, '', '');   % if eventEegFilePaths.txt is not created make it now
    if length(uniqueEegFilePaths)>1,
        fprintf(' NOTE: multiple file paths found in events.mat:  \n       FIX any BLANKS [empty fields] by modifying non-aligned mstimes in a session.log.  \n       Re-extract, align, and/or re-map (using eegPrepAndAlign and/or changeEventsEegFile) any experiments with innaccurate filepaths\n ');
    elseif length(uniqueEegFilePaths)==1,
        fprintf(' LOOKING GOOD: single file path ''%s'' can be passed as "oldphrase" \n   to changeEventsEegFile(subj, rootEEGdir, oldphrase, newphrase) if/when events rereferencing is required\n', uniqueEegFilePaths{1});
    end
    fprintf('\n');
end
    


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%-- Graphical version of list: histogram of session times
%%--
figure(1001); clf;

%- sort the data
allDates     = [allEEGlogs.dateMAT_act];
deltaTimeHr  = datenum('01/01/01 2:00')-datenum('01/01/01 1:00');
deltaTimeBin = deltaTimeHr*3;
dBins  = [min(allDates)-deltaTimeBin/2:deltaTimeBin:max(allDates)+deltaTimeBin/2]; % create 2-hour bins
taskHist=[];
for iTask=1:length(taskDir),
    taskDates = [allEEGlogs(find([allEEGlogs.taskNum]==iTask)).dateMAT_act];
    [oc, dBins] = hist(taskDates,dBins);
    taskHist(iTask,:)=oc;
end

%-histogram of task sessions/day
hB = barh(dBins,taskHist', 'stacked'); hold on
datetick('y','mm/dd');
for iTask=1:length(taskDir), set(hB(iTask),'BarWidth',1.0,'Edgecolor','k'); end
xMax = max(get(gca,'xlim'));
set(gca,'xlim',[0 xMax+2])
title(sprintf('Testing Dates: .%s. ',subj),'fontsize',20)
xlabel('Sessions Collected','fontsize',18)
set(gca,'fontsize',14,'YDir','reverse')


%-add markers of EEG recording breaks
iCount = 1;
for iList=iLogs
    thisEEGlog = allEEGlogs(iList);
    if (thisEEGlog.isNewSession)
        hLine = plot([0 xMax+.2],thisEEGlog.dateMAT_act*[1 1],'r--');
        hText = text(xMax+.45,thisEEGlog.dateMAT_act,sprintf('Test Session %d',iCount),'fontsize',15);
        
        hPt = plot(xMax+0.3,thisEEGlog.dateMAT_act,'ko'); set(hPt,'markersize',14,'MarkerFaceColor','r')
        iCount = iCount+1;
    end
end


%-add markers of raw start times
if (MISSING_ALL_RAW==1 && MISSING_ALL_SYNC==1)
    lText = taskStrAr;
    lText{end+1} = 'Raw MISSING';
    legend([hB hPt],lText,'Location','Best')
else
    hRaw = plot((xMax+0.3)*ones(size(rawTimes)),rawTimes,'ko');
    set(hRaw,'markersize',14,'MarkerFaceColor','k')
    
    if (length(syncTimes)>0)
        hSync = plot((xMax+0.3)*ones(size(syncTimes)),syncTimes,'ko');
        legSync = 'Raw Synced';
        set(hSync,'markersize',6,'LineWidth',0.5,'MarkerFaceColor','c','MarkerEdgeColor','k')
    else
        hSync = plot(max(get(gca,'xlim'))*2, 0,'kx');  %plot outside range of data
        legSync = 'No Sync Found';
        set(hSync,'markersize',12,'LineWidth',1,'MarkerFaceColor','c','MarkerEdgeColor','k')
    end
    
    lText = taskStrAr;
    lText{end+1} = 'Raw MISSING';
    lText{end+1} = 'Raw found';
    lText{end+1} = legSync ;
    legend([hB hPt hRaw hSync],lText,'Location','Best')
end



