function actualName_ALL=getChanNames(elecFileNk,eegFileNk)
%
% getChanNames.m
% 
% Takes in a pair of raw files and returns the names and codes for
% all recorded channels.
% 
% INPUT ARGs:
% subj = 'TJ022'
%
% Output
%
% 10/2015 - updated to handle NEW EEG-1200 file format
%

VERBOSE = 0 ; %

% Open EEG file
fid = fopen(eegFileNk);
if fid==-1, fprintf('\n ERRROR:  cant open .EEG file %s',eegFileNk); keyboard; end


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
x=fread(fid,1,'*uint8');
x=fread(fid,16,'*char');   if strcmp(x(1:9)','EEG-1200A'),NEW_FORMAT=1;else NEW_FORMAT=0; end; 
x=fread(fid,1,'*uint8');

numberOfBlocks=x;
if numberOfBlocks > 1
    % we think we will never have this
    % throw an error for now and re-write code if necessary
    fprintf('ERROR: %d EEG2 control blocks detected (only expecting 1).\n');
    return
end
% if numberOfBlocks is ever > 1, the following should be a for loop
blockAddress=fread(fid,1,'*int32');
x=fread(fid,16,'*char');           


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Reading EEG2m control block (contains names and addresses for waveform blocks)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fseek(fid,blockAddress,'bof');     
x=fread(fid,1,'*uint8');           
x=fread(fid,16,'*char');           
numberOfBlocks=fread(fid,1,'*uint8');
if numberOfBlocks > 2
    % we think we will never have this
    % throw an error for now and re-write code if necessary
    fprintf('ERROR: %d waveform blocks detected (only expecting 1).\n');
    return
end
% if numberOfBlocks is ever > 1, the following should be a for loop
blockAddress=fread(fid,1,'*int32');  
x=fread(fid,16,'*char');             


%%%%%%%%%%%%%%%%%%%%%%%
%Reading waveform block
%%%%%%%%%%%%%%%%%%%%%%%
fseek(fid,blockAddress,'bof'); %fprintf('\nin EEG waveform block!\n')
x=fread(fid,1,'*uint8');             
x=fread(fid,16,'*char');             
x=fread(fid,1,'*uint8');             
L=fread(fid,1,'*uint8');             
M=fread(fid,1,'*uint8');             


%%- annonomous function to convert binary to decimal.  input is binary string created with dec2bin
bcdConverter2 = @(strDec2bin)  10*bin2dec(strDec2bin(1:4)) + bin2dec(strDec2bin(5:8));

% get the start time
T_year   = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
T_month  = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
T_day    = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
T_hour   = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
T_minute = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
T_second = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
    

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
num100msBlocks=fread(fid,1,'*uint32');   
numSamples=actSamplerate*num100msBlocks/10; if VERBOSE, fprintf('number of samples: %d\n',numSamples); end
AD_off=fread(fid,1,'*int16');               
AD_val=fread(fid,1,'*uint16');              
bitLen=fread(fid,1,'*uint8');               
comFlag=fread(fid,1,'*uint8');              
numChannels=fread(fid,1,'*uint8');          



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
    x=fread(fid,1,'*uint32');               if VERBOSE==2, fprintf('data interval (sample rate): %d\n',x);                end; actSamplerate  = double(x);
    x=fread(fid,1,'*uint64');               if VERBOSE==2, fprintf('Length of Session: %2.2f hours\n',double(x)/10/3600); end; num100msBlocks = double(x);
    
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
[allCodes,allNames]=textread(elecFileNk,'%s%s','delimiter','='); %textread reads data from a txt file and write to multiple outputs
endRange  = find(strcmp(allCodes,'[SD_DEF]')); %finds the range of the electrodes
allCodes  = allCodes(1:endRange-1);  %stores the codes
allNames  = allNames(1:endRange-1);  %stores the names
%goodCodes = [0:36 74 75 100:253];
goodCodes = [0:36 42:73 74:75 100:253];  %include DC channels, 42-73, but not mark channels 76-77  (JHW 10/2013)
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
    chanCodeString=sprintf('%04d',x); %format data into string. Same as chanCode except the format is string.
    matchingRow=find(strcmp(chanCodeString,allCodes)); %looks for this particular string in allCodes and stores its locations in matchingRow
    actualName=allNames{matchingRow};
    
    if ~ismember(chanCode(k),goodCodes) %if not a member of goodCodes
        goodElec(k)=false;
        badElec(k) = true;
    elseif any(strcmp(actualName,badNames)) %or if it's part of badNames
        goodElec(k)=false;
        badElec(k) = true;
    else
        goodElec(k)=true;
        badElec(k) = false;
    end
    
    % save out the names for the jacksheet
    if goodElec(k); actualName_ALL(end+1)=allNames(matchingRow); end %if it is a good electrode, append it to the jacksheet
    
    
    fseek(fid,6,'cof'); %skipping the six most sig. bits of 'name'
    
    %finds the channel sensitivity
    chan_sensitivity=fread(fid,1,'*uint8');
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

fclose(fid);