function allTags = nk_split(subj,nk_dir,tagNameOrder)
% nk_split - Splits an nk .EEG datafile into separate channels into
% the specified directory.
%
% FUNCTION:
%    nk_split(subj,nk_dir,tagNameOrder)
%
% INPUT ARGs:
% subj = 'TJ022'
% nk_dir = '/Users/damerasr/damerasr/data/eeg/TJ022/raw/DAY_1'% must contain a single .EEG file
% tagNameOrder={'RFA'; 'RFB'; 'ROFA'; 'ROFB'; 'RAT'; 'RST'; 'RPT'; 'LOF'; 'E';'LF'; 'LAT'; 'LPT'; 'RAH'; 'EKG'; 'RMH'; 'RPH'}
%
% Output
%	output is saved out to: output_dir = '/Users/damerasr/damerasr/data/eeg/[SUBJ]/eeg.noreref/' set in line 49
%
%
% Edited from previous version so that manual input of the ouput_dir would not be necessary
% 
% 12/2013... now uses jacksheetMaster.txt to guide channel number outputs
% 10/2015... now can handel "new" EEG-1200 extended file formats
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
VERBOSE = 0 ; %1 = output info about each channel's remapping


if length(tagNameOrder) ~= length(unique(tagNameOrder)) %if loop makes sure there's no repeats in tagNameOrer
    error('There are repeats in tagNameOrder')
end


%%- Load the jacksheetMaster, or create it, or give a warning that it can't be created...
rootEEGdir      = nk_dir(1:strfind(nk_dir,subj)-1);
subjDir         = fullfile(rootEEGdir,subj);
jackMaster_file = fullfile(subjDir, 'docs/jacksheetMaster.txt');
if exist( jackMaster_file, 'file' ),
    [jackMaster_chans jackMaster_names jackMaster_counts] = textread( jackMaster_file,'%n %s %s\n');  %read channel numbers and names from master jacksheet
else
    if exist( fullfile(subjDir,'docs/tagNames.txt'), 'file') & exist( fullfile(subjDir,'docs/electrodes.m'), 'file') & exist( fullfile(subjDir,'tal/leads.txt'), 'file'),
        createMasterJack(subj,rootEEGdir);
        [jackMaster_chans jackMaster_names jackMaster_counts] = textread( jackMaster_file,'%n %s %s\n');  %read channel numbers and names from master jacksheet
    else
        fprintf(' WARNING: cannot create master jacksheet in nk_split---missing doc/tagNames.txt, docs/electrodes.m, or tal/leads.txt\n');
        jackMaster_chans  = [];
        jackMaster_names  = '';
        jackMaster_counts = [];
        reply = input('   extract channels anyway? (not recommended, choose "no" to break) Y/N [N]:','s');
        if ( isempty(reply) ||  reply(1)=='N' || reply(1)=='n' )
            %keyboard;
            error('  USER SELECTED TO ABORT PrepAndAlign... please confirm existance of doc/tagNames.txt, docs/electrodes.m, and tal/leads.txt');
        end
    end
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%First the home directory is established. Then the directory specified by
%nk_dir is checked and a list of all .EEG files in the directory are made.
%Then the full filepath for the .EEG file is established. Finally it throws
%an error if there is more than one .EEG file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%subjDir = fullfile('/Users/damerasr/Sri/data/eeg/',subj);
subjDir = fullfile( nk_dir(1:strfind(nk_dir,subj)+length(subj)) ); % JW-- extract home directory from nk_dir
d=dir([nk_dir '/*.EEG']);
EEG_file=fullfile(nk_dir,d.name);
assert(length(d)==1,'Expected 1 .EEG file, found %d',length(d));



% Same as above for .21E file
d=dir([nk_dir '/*.21E']);
ELEC_file=fullfile(nk_dir,d.name);
assert(length(d)==1,'Expected 1 .21E file, found %d',length(d));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Specifies filepath for output directory and then checks to see if the
% directory already exists. If it doesn't exist it then creates it
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
output_dir = fullfile(subjDir,'eeg.noreref');
if ~exist(output_dir,'dir')
    mkdir(output_dir)
end


%open and obtain *EEG* file information
fid = fopen(EEG_file);



%%%%%%%%%%%%%%%%%%%%%%%%%%%
% skipping EEG device block
%%%%%%%%%%%%%%%%%%%%%%%%%%%
deviceBlockLen=128; %skips the first 128 bytes
fseek(fid,deviceBlockLen,'bof');  %fseek(fileID, offset, origin) moves to specified position in file. bof=beginning of file


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% reading EEG1 control Block (contains names and addresses for EEG2 blocks)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%fread(fileID, sizeA, precision) reads data from a binary file.
%sizeA=output array size. uint8=unsigned integer with 8 bits.
%precision=string that specifies the form and size of the values to read
x=fread(fid,1,'*uint8');                if VERBOSE, fprintf('block ID: %d\n',x); end;
x=fread(fid,16,'*char');                if VERBOSE, fprintf('device type: %s\n',x); end;   if strcmp(x(1:9)','EEG-1200A'),NEW_FORMAT=1;else NEW_FORMAT=0; end; 
x=fread(fid,1,'*uint8');                if VERBOSE, fprintf('number of EEG2 control blocks: %d\n',x); end

numberOfBlocks=x;
if numberOfBlocks > 1
    % we think we will never have this
    % throw an error for now and re-write code if necessary
    fprintf('ERROR: %d EEG2 control blocks detected (only expecting 1).\n');
    return
end
% if numberOfBlocks is ever > 1, the following should be a for loop
blockAddress=fread(fid,1,'*int32');     if VERBOSE, fprintf('address of block %d: %d\n',i,blockAddress); end
x=fread(fid,16,'*char');                if VERBOSE, fprintf('name of EEG2 block: %s\n',x); end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Reading EEG2m control block (contains names and addresses for waveform blocks)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fseek(fid,blockAddress,'bof');          if VERBOSE, fprintf('\nin EEG21 block!\n'); end
x=fread(fid,1,'*uint8');                if VERBOSE, fprintf('block ID: %d\n',x); end
x=fread(fid,16,'*char');                if VERBOSE, fprintf('data format: %s\n',x); end
numberOfBlocks=fread(fid,1,'*uint8');   if VERBOSE, fprintf('number of waveform blocks: %d\n',numberOfBlocks); end
if numberOfBlocks > 1,
    % we think we will never have this
    % throw an error for now and re-write code if necessary
    fprintf('ERROR: %d waveform blocks detected (only expecting 1).\n');
    return
end
% if numberOfBlocks is ever > 1, the following should be a for loop
blockAddress=fread(fid,1,'*int32');     if VERBOSE, fprintf('address of block %d: %d\n',i,blockAddress); end
x=fread(fid,16,'*char');                if VERBOSE, fprintf('name of waveform block: %s\n',x); end


%%%%%%%%%%%%%%%%%%%%%%%
%Reading waveform block
%%%%%%%%%%%%%%%%%%%%%%%
fseek(fid,blockAddress,'bof'); %fprintf('\nin EEG waveform block!\n')
x=fread(fid,1,'*uint8');                if VERBOSE, fprintf('block ID: %d\n',x); end
x=fread(fid,16,'*char');                if VERBOSE, fprintf('data format: %s\n',x); end
x=fread(fid,1,'*uint8');                if VERBOSE, fprintf('data type: %d\n',x); end
L=fread(fid,1,'*uint8');                if VERBOSE, fprintf('byte length of one data: %d\n',L); end
M=fread(fid,1,'*uint8');                if VERBOSE, fprintf('mark/event flag: %d\n',M); end


%%- annonomous function to convert binary to decimal.  input is binary string created with dec2bin
bcdConverter2 = @(strDec2bin)  10*bin2dec(strDec2bin(1:4)) + bin2dec(strDec2bin(5:8));

% get the start time
T_year   = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
T_month  = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
T_day    = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
T_hour   = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
T_minute = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
T_second = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
strTime  = sprintf('%d/%d/%d %02d:%02d:%02d',T_month,T_day,T_year,T_hour,T_minute,T_second); % 
fprintf(' Date of session: %d/%d/%d\n',T_month,T_day,T_year)
fprintf(' Time at start: %02d:%02d:%02d\n',T_hour,T_minute,T_second)
%fileStemDate = sprintf('%02d%02d%02d_%02d%02d',T_day,T_month,T_year,T_hour,T_minute);    % old version: file stem of extracted channels (old version.... YYMMDD_HHMM)
fileStemDate = sprintf('%02d%02d%02d_%02d%02d',T_year,T_month,T_day,T_hour,T_minute);     % new version: file stem of extracted channels -- JHW 11/2013
    

% get the sampling rate
x=fread(fid,1,'*uint16');  %fprintf('sample rate (coded): %d\n',x);
switch(x)
    case hex2dec('C064'),
        actSamplerate=100;
    case hex2dec('C0C8'),
        actSamplerate=200;
    case hex2dec('C1F4'),
        actSamplerate=500;
    case hex2dec('C3E8'),
        actSamplerate=1000;
    case hex2dec('C7D0'),
        actSamplerate=2000;
    case hex2dec('D388'),
        actSamplerate=5000;
    case hex2dec('E710'),
        actSamplerate=10000;
    otherwise
        fprintf('UNKNOWN SAMPLING RATE\n');
end

fprintf(' Sampling rate: %d Hz\n',actSamplerate);

% get the number of 100 msec block
num100msBlocks=fread(fid,1,'*uint32');      if NEW_FORMAT==0, fprintf(' Length of Session: %2.2f hours\n',double(num100msBlocks)/10/3600); end %- num100msBlocks=10 if new format
numSamples=actSamplerate*num100msBlocks/10; if VERBOSE, fprintf('number of samples: %d\n',numSamples); end
AD_off=fread(fid,1,'*int16');               if VERBOSE, fprintf('AD offset at 0 volt: %d\n',AD_off); end
AD_val=fread(fid,1,'*uint16');              if VERBOSE, fprintf('AD val for 1 division: %d\n',AD_val); end
bitLen=fread(fid,1,'*uint8');               if VERBOSE, fprintf('bit length of one sample: %d\n',x); end
comFlag=fread(fid,1,'*uint8');              if VERBOSE, fprintf('data compression: %d\n',x); end
numChannels=fread(fid,1,'*uint8');          if VERBOSE, fprintf('number of RAW recordings: %d\n',numChannels); end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ****** EXTENDED FORMAT (NEW) .EEG FILE                          ******
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (numChannels==1 & numSamples-actSamplerate==0) & NEW_FORMAT==0, fprintf('\n expecting old format, but 1 channel for 1 second'); keyboard; end
if (numChannels>1)                                & NEW_FORMAT==1, fprintf('\n expecting new format, but >1 channel ');           keyboard; end

if NEW_FORMAT | (numChannels==1 & numSamples-actSamplerate==0),

    if VERBOSE, fprintf('** New File Format **'); end
    
    %- seek the file location of the new wave data... need to make a pit stop in the new EEG2 header, which will provide the direct address
    waveformBlockOldFormat = 39 + 10 + 2*actSamplerate + double(M)*actSamplerate; %- with new format the initial waveform block contains 1 channel (10 bytes of info) for 1 second (2bytes x 1000)
    controlBlockEEG1new    = 1072;
    blockAddressEEG2       = blockAddress + waveformBlockOldFormat + controlBlockEEG1new;% + controlBlockEEG1new + controlBlockEEG2new;
    
    
    
    %- EEG2' format
    addTry = blockAddressEEG2;
    fseek(fid,addTry,'bof');                if VERBOSE, fprintf('--EEG2-prime format--\n'); end
    x=fread(fid,1,'*uint8');                if VERBOSE==2, fprintf('block ID: %d\n',x); end
    x=fread(fid,16,'*char');                if VERBOSE==2, fprintf('data format: %s\n',x); end
    x=fread(fid,1,'*uint16');               if VERBOSE==2, fprintf('number of waveform blocks: %d\n',x); end;
    x=fread(fid,1,'*char');                 if VERBOSE==2, fprintf('reserved: %s\n',x); end
    x=fread(fid,1,'*int64');ii=1;           if VERBOSE==2, fprintf('address of block %d: %d\n',ii,x);    end; waveBlockNew = x;
    
    
    %- EEG2' waveform format
    fseek(fid,waveBlockNew,'bof');          if VERBOSE, fprintf('--EEG2-prime WAVE format--\n'); end
    x=fread(fid,1,'*uint8');                if VERBOSE==2, fprintf('block ID: %d\n',x); end
    x=fread(fid,16,'*char');                if VERBOSE==2, fprintf('data format: %s\n',x); end
    x=fread(fid,1,'*uint8');                if VERBOSE==2, fprintf('data type: %d\n',x); end
    L=fread(fid,1,'*uint8');                if VERBOSE==2, fprintf('byte length of one data: %d\n',L); end
    M=fread(fid,1,'*uint8');                if VERBOSE==2, fprintf('mark/event flag: %d\n',M); end
    
    %- now things get a little different with the new header
    x=fread(fid,20,'*char');                if VERBOSE==2, fprintf('start time string: %s\n',x); end
    x=fread(fid,1,'*uint32');               if VERBOSE==2, fprintf('data interval (sample rate): %d\n',x); end; actSamplerate  = double(x);
    x=fread(fid,1,'*uint64');               fprintf('Length of Session: %2.2f hours\n',double(x)/10/3600); num100msBlocks = double(x);
    
    numSamples  = actSamplerate*num100msBlocks/10; if VERBOSE==2, fprintf('number of samples: %d\n',numSamples); end
    AD_off      = fread(fid,1,'*int16');           if VERBOSE==2, fprintf('AD offset at 0 volt: %d\n',AD_off); end
    AD_val      = fread(fid,1,'*uint16');          if VERBOSE==2, fprintf('AD val for 1 division: %d\n',AD_val); end
    bitLen      = fread(fid,1,'*uint16');          if VERBOSE==2, fprintf('bit length of one sample: %d\n',bitLen); end
    comFlag     = fread(fid,1,'*uint16');          if VERBOSE==2, fprintf('data compression: %d\n',comFlag); end
    reserveL    = fread(fid,1,'*uint16');          if VERBOSE==2, fprintf('reserve length: %d\n',reserveL); end
    x           = fread(fid,reserveL,'*char');     if VERBOSE==2, fprintf('reserve data: %s\n',x); end
    
    numChannels = fread(fid,1,'*uint32');          if VERBOSE==2, fprintf('number of RAW recordings: %d\n',numChannels); end
    
end






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ******.21E FILE******set the look-up tables to get the electrode names
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[allCodes,allNames]=textread(ELEC_file,'%s%s','delimiter','='); %textread reads data from a txt file and write to multiple outputs
endRange  = find(strcmp(allCodes,'[SD_DEF]')); %finds the range of the electrodes
allCodes  = allCodes(1:endRange-1);  %stores the codes
allNames  = allNames(1:endRange-1);  %stores the names

goodCodes = [0:36 74 75 100:253];    % classic good codes... does not include DC
if length(tagNameOrder)>0,
    if strcmp(tagNameOrder{end},'DC'),  % if tagNames are specified and last entry is DC, then extract the DC channels
        goodCodes = [0:36 42:73 74:75 100:253];  %include DC channels, 42-73, but not mark channels 76-77  (JHW 10/2013)
    end
end

badNames  = {'E'};
actualName_ALL = {};


%the following for loop iterates through all the channels, which each
%stores a channel code. For each channel, it reads in the channel code,
%changes it to string format, and matches it to "allCodes" to find a match
%and stores that in matchingRow. It stores the matchingRow-th element in
%allNames into actualName, and checks to see if that is a good or bad
%electrode code. If good, it appends it to the list of good electrodes
%(actualName_ALL).

for k=1:numChannels
    x=fread(fid,1,'*int16');  %reads in 1 byte every time you iterate the loop
    chanCode(k)=x; %and stores it in chanCode(k)
    if (VERBOSE) fprintf(' Index %d ''name'': Channel %d\n',k,x); end
    chanCodeString=sprintf('%04d',x); %format data into string. Same as chanCode except the format is string.
    matchingRow=find(strcmp(chanCodeString,allCodes)); %looks for this particular string in allCodes and stores its locations in matchingRow
    actualName=allNames{matchingRow};
    
    if ~ismember(chanCode(k),goodCodes) %if not a member of goodCodes
        %fprintf(' chan %d (%s) is a bad channel code and excluded\n',chanCode(k),actualName);
        goodElec(k)=false;
        badElec(k) = true;
    elseif any(strcmp(actualName,badNames)) %or if it's part of badNames
        %fprintf(' chan %d (%s) is a bad address\n',chanCode(k),actualName);
        goodElec(k)=false;
        badElec(k) = true;
    else
        if (VERBOSE) fprintf(' chan %d (%s) is good!\n',chanCode(k),actualName); end
        goodElec(k)=true;
        badElec(k) = false;
    end
    
    % save out the names for the jacksheet
    if goodElec(k); actualName_ALL(end+1)=allNames(matchingRow); end %if it is a good electrode, append it to the jacksheet
    
    
    fseek(fid,6,'cof'); %skipping the six most sig. bits of 'name'
    
    %finds the channel sensitivity
    chan_sensitivity=fread(fid,1,'*uint8');
    if (VERBOSE) fprintf('channel sensitivity: %d\n',chan_sensitivity); end
    switch fread(fid,1,'*uint8');  %fprintf('         unit: %d\n',chan_unit);
        case 0; CAL=1000;%microvolt
        case 1; CAL=2;%microvolt
        case 2; CAL=5;%microvolt
        case 3; CAL=10;%microvolt
        case 4; CAL=20;%microvolt
        case 5; CAL=50;%microvolt
        case 6; CAL=100;%microvolt
        case 7; CAL=200;%microvolt
        case 8; CAL=500;%microvolt
        case 9; CAL=1000;%microvolt
    end
    GAIN(k)=CAL/double(AD_val);%OK TO ASSUME THIS IS CONSTANT FOR ALL ELECS?
end

% ADD THIS CODE TO CLEAN UP EEG ERROR WITH WHITESPACE AFTER SOME TAGS (NIH018, channel "LF2 ") -- JW 10/2013
actualName_ALL = strtrim(actualName_ALL);

%keyboard
% CHECKS TO SEE IF USER HAS SPECIFIED TAG NAME ORDER OTHERWISE PROGRAM ENDS AND TAG NAME ORDER IS RETURNED
if isempty(tagNameOrder)
    allTags = actualName_ALL;
else
    allTags = {};
    %the function 'assert' generates error when condition is violated. 'unique'
    %returns an array with the same value but no repetition
    assert(length(unique(GAIN))==1,'All channels do not have the same gain!');
    
    
    %%%%%%%%%%%%%%
    % get the data
    %%%%%%%%%%%%%%
    fprintf('Reading Data...');
    
    d=fread(fid,[double(numChannels+1) double(numSamples)],'*uint16'); %reads the content into an array
    if VERBOSE, fprintf('done\n'); end
    
    %- pull the trigger bits out of the event/mark entry (JHW 10/2013)
    dEvntMrk = d((numChannels+1),:);  %additional element in time series (chan+1) is 16-bit event/mark data, where bits 7-14 encode DC09-DC13 triggers
    trigDC09 = bitget(dEvntMrk,7);    %trigDC09 encodes the aligment pulses
    trigDC10 = bitget(dEvntMrk,8);    %trigDC10 encodes stimulation pulses
    trigDC11 = bitget(dEvntMrk,9);
    trigDC12 = bitget(dEvntMrk,10);
    trigDC13 = bitget(dEvntMrk,11);
    trigDC14 = bitget(dEvntMrk,12);
    trigDC15 = bitget(dEvntMrk,13);
    trigDC16 = bitget(dEvntMrk,14);
    
    d=d([goodElec false],:);  %removing bad electrodes (including 16-bit event/mark data)
    
    fprintf('Removing offset...');
    d_int16=int16(int32(d)+int32(AD_off)); %convert to int16
    
    %the line below proves the above is lossless... it eats up ram, so only do it on a beefy mac
    if ismac,
        fprintf('Validating conversion...');
        assert(isequal(d,uint16(double(d_int16)-double(AD_off))))
        fprintf('.');
    end
    
    % scale the DC input lines (different scaling than EEG signals)  (JHW 10/2013)
    iDC = find(~cellfun('isempty',strfind(actualName_ALL,'DC')));
    %GAIN_DC = 500 / 2730 ; % E11FFmt.pdf says "Ox0555 corresponds to 500 mV"; Ox555 = 1365;  looks like actually OxAAA-->500mV (2730)... should confirm on multiple machines though
    GAIN_DC = 500 / 1365 ; % E11FFmt.pdf says "Ox0555 corresponds to 500 mV"; Ox555 = 1365;  looks like actually OxAAA-->500mV (2730)... should confirm on multiple machines though
    for thisDC = iDC,
        d_int16(thisDC,:) = d_int16(thisDC,:)*GAIN_DC;  %possibly this should not be scaled here... could loose data with the int16 transform
    end
    
    % clear the temp variable and close the file
    clear d
    fprintf('done\n'); 
    fprintf(' Number of channels to split from raw file: %d\n',size(d_int16,1));
    fclose(fid);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % reorder the jacksheet and the electrodes... two options: sort using tagNames, or sort using jacksheetMaster.  Always use master if possible
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%--- OLD WAY: NO jackMaster ---------------------------------------------------------------------------------------------%%%
    %%%---     reorder the channels according to tagNames.  If any tag missing from channel list or tagNames drop an error ----%%%
    %%%------------------------------------------------------------------------------------------------------------------------%%%
    if isempty(jackMaster_chans),
        %regexprep('str', 'expr', 'repstr') replaces all occurences of 'expr' in string 'str' with the string 'repstr'.
        originalTagNames = regexprep(actualName_ALL','\d','')';               %gets only the tagnames
        originalTagNums  = str2double(regexprep(actualName_ALL','[\D]',''))'; %gets only the tag numbers
        %above two lines takes RFA and 1 from RFA1 in actualName_ALL
        
        %JD inserted the for loop to make sure all the TagNums have a number
        for index = 1:length(originalTagNums)
            if (isnan(originalTagNums(index))) && ~strcmpi(originalTagNames(index),'EKG')
                originalTagNums(index)=1;
            end
        end
        
        newElectrodeOrderIdx = []; %initialize newElectrodeOrderIdx
        newElectrodeNames = [];    %initialize newElectrodeNames
        justToCheck = actualName_ALL';
        
        %keyboard
        for t=1:length(tagNameOrder)
            
            %for each iteration, it looks in originalTagNames for any tag names
            %that shares the tag in tagNameOrder(t), and then stores the indices of those tags in thisTagIdx.
            thisTagIdx = find(strcmp(originalTagNames,tagNameOrder{t}));
            if isempty(thisTagIdx)
                fprintf('\n\n  ERROR!\n')
                fprintf('  ''tagNameOrder'' ELEMENT ''%s'' NOT FOUND in following list:\n',tagNameOrder{t})
                disp([actualName_ALL']);
                fprintf('\n  No output written. Exiting\n\n')
                return
            end
            %the above if statement makes sure that there are electrodes that
            %corresponds to each one of the elements in tagNameOrder
            
            theseTags  = actualName_ALL(thisTagIdx); %contains full names
            theseNums  = originalTagNums(thisTagIdx); %contains the number after the electrode name2
            
            % only permit EKG to not have numbers
            if sum(isnan(theseNums))>0; %if there are any non-zero elements in theseNums...
                if strcmp('EKG',tagNameOrder{t}) %if there are 'EKG' in tagNameOrder{t}...
                    newElectrodeNames     = [newElectrodeNames   theseTags]; %make newElectrodeNames a 2D array
                    newElectrodeOrderIdx  = [newElectrodeOrderIdx thisTagIdx];%make newElectrodeOrderIdx contain itself and thisTagIdx
                    justToCheck(thisTagIdx) = {'THIS_WAS_USED'}; %store that phase into variable that has all the electrode names
                    continue
                else
                    error('FOUND BAD NANS');
                end
            end
            
            % order them in case they are out of order
            [theseNums_sorted sortIdx] = sort(theseNums);
            newElectrodeNames     = [newElectrodeNames theseTags(sortIdx)];
            newElectrodeOrderIdx  = [newElectrodeOrderIdx thisTagIdx(sortIdx)];
            justToCheck(thisTagIdx(sortIdx)) = {'THIS_WAS_USED'};  %????????
        end
        
        %check to make sure you used them all
        unusedNameIdx = find(~strcmp(justToCheck,'THIS_WAS_USED'));
        if ~isempty(unusedNameIdx)
            fprintf('\n\n  ERROR!\n')
            fprintf('  THE FOLLOWING CHANNELS MUST BE INCLUDED IN ''tagNameOrder'' INPUT\n')
            for k=1:length(unusedNameIdx)
                fprintf('    %s\n',justToCheck{unusedNameIdx(k)})
            end
            fprintf('\n  No output written. Exiting\n\n')
            return
        end
        
        % sort the electrodes to match the jacksheet
        d_int16 = d_int16(newElectrodeOrderIdx,:);
        
        % JHW.. add a channel out and channel name surrogate for jacksheet creation (to make compatible with second method)
        chanOut = [1:size(d_int16,1)];                  %JHW... create alternative to jacksheetMaster
        newElectrodeChans = chanOut ;
        if length(chanOut)~=length(newElectrodeNames),
            keyboard
            %this shouldn't happen... if it does rethink chanOut definition
        end
        
        
    %%%--- NEW WAY: use jackMaster --------------------------------------------------------------------------------------------------------%%%
    %%%---     reorder the channels according to jackMaster.  Skip any tag missing from channel list. Error if missing from jackmaster ----%%%
    %%%---     this method allows for channels being added/subtracted between sessions... channel numbers will be preserved            ----%%% 
    %%%------------------------------------------------------------------------------------------------------------------------------------%%%
    else
        
        chanOut = nan(1, size(d_int16,1));  % chanOut is same length as d_int16... maps raw channel order to jackMaster_chans
        newElectrodeNames = {};             % newElectrodeNames is same size as jackMaster_names... modified to indicate whether some channels are missing 
        newElectrodeChans = [];
        
        %- loop through all jackMaster channels... if jackMaster name is found, map the channel, if not found, modify the channel name for this session's jacksheet
        for iChan = 1:length(jackMaster_chans),
            
            masterChan = jackMaster_chans(iChan);
            masterName = jackMaster_names{iChan};
            
            actualChan = find(strcmp(actualName_ALL,masterName));
            
            if     length(actualChan)==1,
                chanOut(actualChan)      = masterChan;
                newElectrodeNames{end+1} = masterName;
                newElectrodeChans(end+1) = masterChan;
            
            elseif length(actualChan)==0,
                fprintf('  WARNING: raw channel list missing %s from jacksheetMaster.txt.  Channel %d will be skipped.\n', masterName, masterChan);
                newElectrodeNames{end+1} = sprintf('<%s_missing_from_raw>', masterName);
                newElectrodeChans(end+1) = masterChan;
            
            else
                keyboard
                error(' ERROR in nk_split: more than 1 instance of %s found in raw channel list. Should never happen!\n', masterName);
            
            end
              
        end
        
        %- any raw channels not accounted for?
        notInMaster = find(isnan(chanOut));
        if length(notInMaster)>0,
            
            for iChan = 1:length(notInMaster),
               rawName = actualName_ALL{notInMaster(iChan)};
               fprintf('  WARNING: raw channel list contains %s, but jacksheetMaster.txt does not.  Channel will not be extracted.\n', rawName) ; 
               newElectrodeNames{end+1} = sprintf('<%s_missing_from_jacksheetMaster.txt>', rawName);
               newElectrodeChans(end+1) = nan;
               
            end
            
            %- cut the raw channels that were not specified in the master
            inMaster = find(~isnan(chanOut));
            chanOut  = chanOut(inMaster);
            d_int16  = d_int16(inMaster,:);
        end
        
        %- sort so output in order (makes directory sorted by date look same as sorted by name)
        [chanOut_sorted sortIdx] = sort(chanOut);
        chanOut = chanOut(sortIdx);
        d_int16 = d_int16(sortIdx,:);
        
    end
    
    
    
    
    %%%%%%%%%%%%%%%%%%%%
    % make the jacksheet
    %%%%%%%%%%%%%%%%%%%%
    %keyboard
    fileRoot = sprintf('%s_%s',subj,fileStemDate);     % new version uses "fileStemDate".... YYMMDD_HHMM... defined above where date is extracted
    filestem = fullfile(output_dir,fileRoot);
    
    %- make the raw file specific jacksheet (with file stem)
    jackFile = sprintf('%s.jacksheet.txt',filestem);
    fout3    = fopen(jackFile,'w','l');
    for iChan = 1:length(newElectrodeChans),
        thisChan = newElectrodeChans(iChan);
        thisName = newElectrodeNames{iChan};
        fprintf(fout3,'%d %s\n',thisChan,thisName);  %JHW... mod to all for jacksheetMaster implementation 
    end
    fclose(fout3);
    
    %- check for global jacksheet (if no jacksheetMaster)
    if isempty(jackMaster_chans),
        if exist(fullfile(subjDir,'docs/jacksheet.txt'),'file')
            fid_tmp = fopen(fullfile(subjDir,'docs/jacksheet.txt'));
            previousJack = textscan(fid_tmp,'%s%s');
            if ~isequal(previousJack{2},newElectrodeNames')
                fprintf('\n\n  ERROR: docs/jacksheet.txt DOESN''T MATCH THIS JACKSHEET\n')
                fprintf('\n  No output written. Exiting\n\n')
                fclose(fid_tmp);
                return
            end
            fclose(fid_tmp);
        end
        if ismac,
            system([sprintf('cp "%s" "%s"',jackFile,fullfile(subjDir,'docs/jacksheet.txt'))]);
            %system([sprintf('cp "%s" "%s"',jackFile,fullfile(output_dir,'jacksheet.txt'))]);  % why make another copy... each stem gets its own copy anyway
            fprintf(' jacksheet.txt is made \n')
        else
            fprintf('\n WARNING: running nk_split on PC instead of MAC... jacksheet.txt not copied');
        end
    end
    pause(.5);%JFB: pause to smooth output. I am slow and so I like slow output!
    % the real JFB: above comment editorialized by JJ
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    % make the params.txt file
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    paramsFile=sprintf('%s.params.txt', filestem);
    fout4=fopen(paramsFile,'w','l');
    fprintf(fout4,'samplerate %d\n',actSamplerate);
    fprintf(fout4,'dataformat ''int16''\n');
    fprintf(fout4,'gain %d\n',GAIN(1));
    fclose(fout4);
    % copy over the most params.txt file
    if ismac,   
        system([sprintf('cp "%s" "%s"',paramsFile,fullfile(output_dir,'params.txt'))]);
        fprintf(' params.txt is made\n')
    else
        [success, message, messageid] = copyfile(paramsFile,fullfile(output_dir,'params.txt'));
        if success==1,
            fprintf(' params.txt is made\n')
        else
            fprintf('\n WARNING: running nk_split on PC instead of MAC... params.txt not copied sucessfully');
        end
    end
    pause(.5);%JFB: pause to smooth output
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % write the electrodes to file
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    pause(.5);%JFB: pause to smooth output
    fprintf('\nwriting files:')
    ticker=0;
    tick_inc=10;
    for thisChan=chanOut,
        if thisChan/length(chanOut)*100>=ticker
            fprintf(' %2.0f%%',ticker)
            ticker=ticker+tick_inc;
        end
        chanfile = sprintf('%s.%03i', filestem,thisChan);
        fchan = fopen(chanfile,'w','l');
        fwrite(fchan,d_int16(find(chanOut==thisChan),:),'int16');
        fclose(fchan);
        if ismac, fileattrib(chanfile, '+x', 'a'); end %JHW - change files to "executable"... helps for sorting in mac finder
    end
    if find(trigDC09>0), %JHW - output sync file if trigger bit is non-zero 11/2013
        updowns = [trigDC09(1) diff(trigDC09)];
        uptimes = find(updowns==1);
        chanfile = sprintf('%s.trigDC09.sync.txt', filestem);
        fchan = fopen(chanfile,'w','l');
        fprintf(fchan,'%d\n',uptimes);
        fclose(fchan);
        if ismac, fileattrib(chanfile, '+x', 'a'); end %JW - change files to "executable"... helps for sorting in mac finder
        fprintf('\nDigital pulse trigger found... extracted %d pulse up times to:\n   %s', length(uptimes), chanfile);
    else
        fprintf('\nDigital pulse trigger not found.  Must extract peaks and sync from EEG or DC09 wave.');
    end
    
    %- if stimulation, then DC10, 11, or 12 should have pulses, and possibly annotation file contains channel info
    if sum(trigDC10)>0 ||  sum(trigDC11)>0 || sum(trigDC12)>0,
        annStruct = nk_parseAnnotation(nk_dir);
        annTimes = [];
        annStr   = {};
        for iAnn=1:length(annStruct),
            annTimes(iAnn) = (annStruct(iAnn).timeSec+1)*actSamplerate;  %-add 1 sample to avoid indexing 0 (could cause problem for end of file?)
            annStr{iAnn}   = sprintf('ANNOTATE \t %s',annStruct(iAnn).str);
        end
        %-output annotation file... it will also be merged with the updown files 
        if length(annTimes)>0,
            chanfile    = sprintf('%s.annotation.txt', filestem);
            fchan       = fopen(chanfile,'w','l');
            fprintf(fchan,'1 \t FILENAME \t %s \n1 \t EEGSTEM \t %s \n', chanfile(min(strfind(chanfile, fileRoot)):end),fileRoot); %- make first entry "FILENAME"; trim off the path info
            for iOut = 1:length(annTimes),
                fprintf(fchan,'%d \t %s\n',annTimes(iOut), annStr{iOut});
            end
            fclose(fchan);
            if ismac, fileattrib(chanfile, '+x', 'a'); end %JW - change files to "executable"... helps for sorting in mac finder
            fprintf('\nAnnotation events found (%d total) and extracted to: %s', length(annTimes), chanfile);
            
            %-copy to stimMapping directory if .21E comes from a raw/STIM/SESS_X folder
            if isempty(strfind(nk_dir,fullfileEEG('raw','STIM','SESS_'))),
                fprintf(' DC10,11,12 active but .21E not located in raw/STIM/SESS_X directory, so digital up-down files not copied from noreref to behavioral/stimMapping task');
            else
                stimSessStr = nk_dir(max(strfind(nk_dir,fullfileEEG('STIM','SESS_')))+10:end); % if is
                stimSessNum = double(stimSessStr-'A');
                stimMappingDir = fullfileEEG(subjDir,'behavioral','stimMapping',sprintf('session_%d',stimSessNum)); if ~exist(stimMappingDir,'dir'), mkdir(stimMappingDir); end
                [sucess,message,messageid] = copyfile(chanfile,stimMappingDir); if sucess, fprintf(' (and copied to behavioral/stimMapping/session_%d)',stimSessNum); end
            end
        end
                
        %- loop through trig arrays and see whether they have any non-zero entries... if so, export a up-down file
        for trigOut = [10 11 12],
            trigStr  = sprintf('DC%02d',trigOut); %-create variable representing trigDC09, 10, 11, etc
            thisTrig = eval(sprintf('trig%s',trigStr)); %-create variable representing trigDC09, 10, 11, etc
            
            %- additional outputs if DC10, 11, or 12 had trigger events: this is used to determine stimulation timining 2/2014
            if sum(thisTrig)>0,
                trigDCout   = double(thisTrig);  
                
                %-create list of pulse start (up) and stop (down) times (in units of sample), and a string for each event
                %strUpDown   = {sprintf('%s \t PULSE_HI',trigStr),sprintf('%s \t PULSE_LO',trigStr)};
                strUpDown   = {sprintf('PULSE_HI \t %s',trigStr),sprintf('PULSE_LO \t %s',trigStr)};
                updowns     = [trigDCout(1) diff(trigDCout)];  %diff requires double input for proper functionality
                updownTimes = find(updowns==1  |  updowns==-1);
                updownStr   = {strUpDown{ ((updowns(updownTimes)-1)*-.5)+1 }} ; %-convert -1-->2 and 1->1
                
                %-merge annotation and pulse times.
                timesMerge  = [updownTimes annTimes];
                textMerge   = [updownStr   annStr  ];
                [y,iSort]   = sort(timesMerge);
                timesMerge  = timesMerge(iSort);
                textMerge   = textMerge(iSort);
                
                %-output updown file, with annotation if present
                chanfile    = sprintf('%s.trig%s.updown.txt', filestem, trigStr);
                fchan       = fopen(chanfile,'w','l');
                fprintf(fchan,'1 \t FILENAME \t %s \n1 \t EEGSTEM \t %s \n', chanfile(min(strfind(chanfile, fileRoot)):end),fileRoot); %- make first entry "FILENAME"; trim off the path info
                for iOut = 1:length(timesMerge),
                    fprintf(fchan,'%d \t %s\n',timesMerge(iOut), textMerge{iOut});
                end
                fprintf(fchan,'%d \t SESS_END \n', size(d_int16,2)); %- make first entry "FILENAME"; trim off the path info
                fclose(fchan);
                if ismac, fileattrib(chanfile, '+x', 'a'); end %JW - change files to "executable"... helps for sorting in mac finder
                fprintf('\nDigital trigger events found on %s... extracted %d pulse up and down times to:\n   %s', trigStr, length(updownTimes), chanfile);
            
                %-copy to stimMapping directory if .21E comes from a raw/STIM/SESS_X folder
                if isempty(strfind(nk_dir,fullfileEEG('raw','STIM','SESS_'))),
                    fprintf(' DC10,11,12 active but .21E not located in raw/STIM/SESS_X directory, so digital up-down files not copied from noreref to behavioral/stimMapping task');
                else
                    stimSessStr = nk_dir(max(strfind(nk_dir,fullfileEEG('STIM','SESS_')))+10:end); % if is
                    stimSessNum = double(stimSessStr-'A');
                    stimMappingDir = fullfileEEG(subjDir,'behavioral','stimMapping',sprintf('session_%d',stimSessNum)); if ~exist(stimMappingDir,'dir'), mkdir(stimMappingDir); end
                    [sucess,message,messageid] = copyfile(chanfile,stimMappingDir); if sucess, fprintf(' (+ copied to behavioral/stimMapping/session_%d)',stimSessNum); end
                end
            end
        end
    end


    fprintf('\nExtraction complete\n\n\n')
end
