function eegStimPrep_v3a( subj, rootEEGdir )
%Function eegStimPrep( subj, rootEEGdir)
%
%  Master function used as a wrapper for nk_split to pull out the single-channel 
%      raw files (reref and noreref) for stimulation.
%
%  After this function is called, 
%
%  Outputs:
%    --Command line outputs describing status of RAW and Behavioral files
%    --single-channel time series in eeg.noreref and eeg.reref
%    --copy of annotation text file in behavioral/stimMapping.  
%
%  Inputs:
%    -- subj                        % subject string,        ex) 'NIH016'
%    -- rootEEGdir                  % data path up to "eeg", ex) '/Users/wittigj/DataJW/data/eeg'   
%
%
%  What to do AFTER running this function: once the pulse updown files are moved to stimMapping, use "saveas" to create a copy of
%      the file containing stimulation pulse timing renamed as session.log, then run behavioralProcessing on stimMapping
%      to convert that to an events file for analysis
%    
%
%
%  created by JHW 2/11/2014
%  modified by TCS 1/6/2016
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Function Flow:
%       [1/4]  Searching RAW and/or EEG.NOREREF for Raw and/or Extracted Channel files
%               --> if raws missing, look for extracted channels and sync files and proceed (sometimes extraction present when raws aren't)
%               --> if raws present, confirm that each has been extracted and has a sync file;  extract if necessary;  rereference if necessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%-- USER SETS THE FOLLOWING VARIABLES if running directly from M-file (instead of using as function... useful for debugging)

% %clear all
% subj       = 'NIH035';
% rootEEGdir = '/Volumes/Shares/FRNU/dataWorking/eeg/';  % dataWorking 
% %rootEEGdir = '/Volumes/Macintosh HD 2/STIM_MAP_DATA'; %local


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



%- events eegfile entry all pointed to this root
serverDataPath = '/Volumes/Shares/FRNU/data/eeg/';
FORCE_ALIGNMENT_TO_SERVER_PATH = 0; % 0 or 1: if 1 (default), set aligned events eegfile to '/Volumes/Shares/FRNU/data/eeg/subj/eeg.reref/'; if 0, set aligned events to local data directory
                        

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
days   = dir(fullfileEEG(rootEEGdir,subj,'raw/STIM*')); %need * at end to avoid looking inside the STIM directory
rawList=[];  extractedList=[];
rawTimes=nan;
if (length(days)==0)
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
            
            %- export a text version of the annotation (log) file
            %nknih_parseAnnotation(rawList(iList).rawDir)
            
            %- grab the tag names and pass to nk_split
            tagNameOrder = '';
            fid          = fopen(fullfileEEG(rootEEGdir,subj,'/docs/tagNames.txt'));
            if (fid~=-1)
                foo                        = textscan(fid,'%s');
                tagNameOrder               = foo{1};
%                 %check to see that last tag name is EKG or DC
                if ( strcmp(tagNameOrder(end),'EKG')==0 & strcmp(tagNameOrder(end),'DC')==0 ),
                    fprintf('SEVERE WARNING: last entry in /docs/tagNames.txt should specify then pulse channel(s).\n  Current entry is "%s", usually pulses on "EKG" or "DC"',tageNames(end));
                end
                fclose(fid);
            end

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
            if (exist(extractPath,'file'))
                rawList(iList).extracted   = 1  ;
            else
                rawList(iList).extracted   = 1  ;
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




