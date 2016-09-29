function eegRawServerDir( subj, rootEEGdir, rawFilePrefix, strDateStart, strDateEnd )
% function eegRawServerDir( rawFilePrefix, strDateStart, strDateEnd )
%
%   does a "smart" directory listing from the EEG server to help identify potiential raw files for analysis
%     extracts file start times embedded in the raw files
%     identifies file sizes that deviate from automatically saved files
%
%   NOTE: ONLY WORKS IF YOU HAVE ACCESS TO '/Volumes/shares/EEG/LTVEEG_DATA/nkt/EEG2100'... confirm this first!
%
%
%   INPUTS:
%      -rawFilePrefix  --- either 'DA8661'   or   'BA6932'  depending on which NK machine was used
%      -strDateStart   --- starting date range to look for, e.g. '10/25/13'
%      -strDateEnd     --- ending date range to look for,   e.g. '10/30/13'
%
%   OUTPUTS:
%      - command line and txt file with directory listing
%
%%-- values for NIH020
% prefixMachine = 'DA8661';    % subject specific
% strDateStart  = '10/25/13';  % format: mm/dd/yy
% strDateEnd    = '10/30/13';
%
%%-- values for NIH019
% prefixMachine = 'BA6932';    % subject specific
% strDateStart  = '10/10/13';  % format: mm/dd/yy
% strDateEnd    = '10/16/13';
%
%%-- values for NIH018
% prefixMachine = 'DA8661';    % subject specific
% strDateStart  = '09/25/13';  % format: mm/dd/yy
% strDateEnd    = '10/10/13';

% sometimes this code hangs/crashes, probably due to slow interaction with the server.  Forcing all files closed seems to help
fclose all;

%%- directory should be the same on all computers in Kareem's lab...
nktdir = '/Volumes/Shares-1/EEG/LTVEEG_DATA/nkt/EEG2100';
%nktdir = '/Volumes/shares/EEG/LTVEEG_DATA/nkt/EEG2100-full';

if ~exist(nktdir,'dir'),  error(' ERROR: cant see EEG folder on server '); end

prefixMachine = rawFilePrefix;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%   Use the information above to generate a refined list of Raw EEG files   %%%%%%
getEmbeddedDates = 1;


%-list complete directory for this machine prefix
rawList  = dir( fullfile(nktdir, [prefixMachine '*.EEG']) );
numRaw   = length(rawList);
fprintf('\n Found %d files starting with %s, directory listing date range: %s to %s\n', numRaw, rawFilePrefix, datestr(min([rawList.datenum]),'mm/dd/yy'), datestr(max([rawList.datenum]),'mm/dd/yy'));


%-get embedded dates and use these to filter out any files out of the specified date range
if getEmbeddedDates==1,
    fprintf(' fetching %d embeded dates: ', length(rawList));
    for iList=1:length(rawList),
        if mod(iList, round(length(rawList)/10))==0, fprintf('%.0f%% ',100.0*iList/length(rawList)); end
        
        EEG_file = fullfile(nktdir,rawList(iList).name);
        
        %%- Gets to data in the waveform block
        fid = fopen(EEG_file);
        if fid==-1,
            fprintf(' WARNING: raw file %s did not open\n', rawList(iList).name);
            rawList(iList).dateActStr = '';
            rawList(iList).dateActNum = nan;
        else
            %%%%%%%%%%%%%%%%%%%%%%%%%%%
            % skipping EEG device block
            %%%%%%%%%%%%%%%%%%%%%%%%%%%
            deviceBlockLen=128; %skips the first 128 bytes
            fseek(fid,deviceBlockLen,'bof');  %fseek(fileID, offset, origin) moves to specified position in file. bof=beginning of file
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % reading EEG1 control Block (contains names and addresses for EEG2 blocks)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            x=fread(fid,1,'*uint8');  %fprintf('block ID: %d\n',x);
            x=fread(fid,16,'*char');  %fprintf('device type: %s\n',x);
            x=fread(fid,1,'*uint8');  %fprintf('number of EEG2 control blocks: %d\n',x);
            blockAddress=fread(fid,1,'*int32');  %fprintf('address of block %d: %d\n',i,blockAddress);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Reading EEG2m control block (contains names and addresses for waveform blocks)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            fseek(fid,blockAddress,'bof');          %fprintf('\nin EEG21 block!\n')
            x=fread(fid,1,'*uint8');                %fprintf('block ID: %d\n',x);
            x=fread(fid,16,'*char');                %fprintf('data format: %s\n',x);
            numberOfBlocks=fread(fid,1,'*uint8');   %fprintf('number of waveform blocks: %d\n',numberOfBlocks);
            blockAddress=fread(fid,1,'*int32'); %fprintf('address of block %d: %d\n',i,blockAddress);
            
            %%%%%%%%%%%%%%%%%%%%%%%
            %Reading waveform block
            %%%%%%%%%%%%%%%%%%%%%%%
            fseek(fid,blockAddress,'bof');      %fprintf('\nin EEG waveform block!\n')
            x=fread(fid,1,'*uint8');            %fprintf('block ID: %d\n',x);
            x=fread(fid,16,'*char');            %fprintf('data format: %s\n',x);
            x=fread(fid,1,'*uint8');            %fprintf('data type: %d\n',x);
            L=fread(fid,1,'*uint8');            %fprintf('byte length of one data: %d\n',L);
            M=fread(fid,1,'*uint8');            %fprintf('mark/event flag: %d\n',M);
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%- annonomous function to convert binary to decimal.  input is binary string created with dec2bin
            bcdConverter2 = @(strDec2bin)  10*bin2dec(strDec2bin(1:4)) + bin2dec(strDec2bin(5:8));
            
            T_year   = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8)) + 2000;  %last two digits encoded; add 2000
            T_month  = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
            T_day    = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
            T_hour   = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
            T_minute = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
            T_second = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
            strTime  = sprintf('[%d/%d/%d %02d:%02d:%02d] ',T_month,T_day,T_year,T_hour,T_minute,T_second);
            
            rawList(iList).dateActStr = strTime;
            rawList(iList).dateActNum = datenum(T_year,T_month,T_day,T_hour,T_minute,T_second);
            
            fclose(fid);
        end
        
    end
    
    [dSort, iSortDateAct] = sort([rawList.dateActNum]);
    rawList = rawList(iSortDateAct);  strSort = 'sort by date act';
    fprintf(' embedded date range: %s to %s\n', datestr(dSort(1),'mm/dd/yy'), datestr(dSort(end),'mm/dd/yy'));
    
    rawListCopy = rawList; %- save a copy before trimming
    
    %-exclude files outside the specified date range (use file info dates)
    dateStart = datenum(strDateStart,'mm/dd/yy');
    dateEnd   = datenum(strDateEnd,  'mm/dd/yy');
    rawDateN = [rawList.dateActNum];
    iDateOK  = find(rawDateN >= dateStart & rawDateN <= dateEnd);
    rawList  = rawList(iDateOK);
    numTrim  = length(rawList);
    strTrim  = sprintf('  %d files between %s and %s [embedded dates]\n',numTrim, strDateStart, strDateEnd);
end


%- if all files cut using embedded dates, try using directory listing dates
if length(rawList)==0,
    
    fprintf('%s \n --> trying to trim based on directory listing dates\n',strTrim);
    rawList = rawListCopy;
    
    
    %-exclude files outside the specified date range (use file info dates from directory listing)
    dateStart = datenum(strDateStart,'mm/dd/yy');
    dateEnd   = datenum(strDateEnd,  'mm/dd/yy');
    rawDateN = [rawList.datenum];
    iDateOK  = find(rawDateN >= dateStart & rawDateN <= dateEnd);
    rawList  = rawList(iDateOK);
    numTrim  = length(rawList);
    strTrim  = sprintf('  %d files between %s and %s [dir dates]\n',numTrim, strDateStart, strDateEnd);
    
    
    %-zero out "actual" dates
    for iList=1:length(rawList),
        rawList(iList).dateActStr = '';
        rawList(iList).dateActNum = nan;
    end
end


%- if all files cut using directory listing dates, don't trim
if length(rawList)==0,
    
    fprintf('%s \n --> dont trim based on dates \n',strTrim);
    
    rawList = rawListCopy;
    numTrim  = length(rawList);
    
    strTrim = '';
end


%- if still no files, then return
if length(rawList)==0,
    fprintf('\n\n ERROR: NO FILES SATISFY THE PREFIX & DATE COMBINATION SPECIFIED!!!!\n');
    return;
end



%- most files should be the same size.. stop/start will make them shorter
modeSizeB  = mode([rawList.bytes]); %returns smallest value if no repititions
meanSizeB  = mean([rawList.bytes]); %


%- output list to command line and text file
fileStr = fullfile(rootEEGdir,subj,'raw',sprintf('rawFileList_%s.txt',subj));
fid = fopen(fileStr,'w+');
if fid==-1, 
    fprintf(' WARNING: cannot create text file in %s\n  saving to current working directory\n', fileStr); 
    fileStr = fullfile(pwd,sprintf('rawFileList_%s.txt',subj));  % set fid to 2 for standard error output
    fid = fopen(fileStr,'w+'); 
    if fid==-1, error(' ERROR: cant open text file in local directory either... output line will be doubled'); fid = 2; end  %fid=2 --> standard error
end  

outStr = sprintf('\n\nListing Raw EEG files in %s: machine prefix %s --> %d entries\n%s  mode size %.3f GB  (mean %.3f GB)\n\n  <filename>     <dir listing date>      <embedded date>     <size>   <<smaller files\n', nktdir, prefixMachine, numRaw, strTrim, modeSizeB/(2^30), meanSizeB/(2^30));
fprintf(fid, outStr);   % output to eegTimes textfile
fprintf(     outStr);   % also output to command line

for iList=1:length(rawList),
    if rawList(iList).bytes<0.95*modeSizeB, strMod = '<<'; else strMod = ''; end  % mark any file with 5% drop in size
    outStr = sprintf(' %s   %s  %s %.3f GB  %s\n',rawList(iList).name, rawList(iList).date, rawList(iList).dateActStr, rawList(iList).bytes/(2^30), strMod);
    fprintf(fid, outStr);   % output to eegTimes textfile
    fprintf(     outStr);   % also output to command line
end

fclose(fid);
fprintf('\n\nDirectory Listing saved to %s \n', fileStr);

%figure(1);clf
%hist( [rawList.bytes]/(2^30), 100)

