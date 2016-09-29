function [annotationStruct] = nk_parseAnnotation(nk_dir);
%
% This function converts a .LOG file to a structure that contains time stamps and annotation text
%


annotationStruct = struct([]);  %- create empty return struct incase exit function early
VERBOSE = 0;                    %- default is 0;  set to 1 to debug code

%keyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% confirm single LOG file exists and open it
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LOG_file = [nk_dir, '.LOG'];    %- allow user to enter raw filename root for compatability with eegPulseVisualize (i.e., '/Volumes/Kareem/data/eeg/NIH018/raw/DAY_3/DA8661N4')

if ~exist(LOG_file,'file'),     %- allow user to enter SESSion directory for compatability with nk_slit
    d = dir([nk_dir '/*.LOG']);
    if length(d)==0, fprintf(' --no log file found in %s-- ', nk_dir); return; end
    if length(d)>1,  fprintf(' --ERRROR: %d log files found in %s (expecting 0 or 1); NO log parsed', length(d), nk_dir); return; end
    LOG_file = fullfile(nk_dir,d.name);
end

fid      = fopen(LOG_file,'r+');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-DEVICE BLOCK: 128 bytes : read as 1 string (don't need to parse info)
fseek(fid,0,'bof');                      %-dont really have to do this, but convenient for debugging
deviceBlock  = fread(fid,128,'*char')';  %-device block contains: device type, file chain, file chain (next), ID number, date/time, char type, name, reserved, additional version


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-CONTROL BLOCK: 896 bytes : parse contents of control block... will point to annotation block
blockID  = fread(fid,1,'*uint8');                       if VERBOSE, fprintf('block ID: %d\n',blockID); end;
devType  = fread(fid,16,'*char');                       if VERBOSE, fprintf('device type: %s\n',devType); end
blockCnt = fread(fid,1,'*uint8');                       if VERBOSE, fprintf('total number of the Event log blocks: %d\n',blockCnt); end


%- loop through block information stored in the control block
blockAddress = []; blockAdressSub = []; blockName = {}; blockNameSub = {};
for iBlock=1:22,
    % if numberOfBlocks is ever > 1, the following should be a for loop
    blockAddress(iBlock) = fread(fid,1,'*int32');       if VERBOSE, fprintf('address of block %d: %d\n',iBlock,blockAddress(iBlock)); end
    blockName{iBlock}    = fread(fid,16,'*char');       if VERBOSE, fprintf('name of waveform block: %s\n',blockName{iBlock}); end
end  
for iBlock=1:21,
    % if numberOfBlocks is ever > 1, the following should be a for loop
    blockAddressSub(iBlock) = fread(fid,1,'*int32'); 	if VERBOSE, fprintf('sub address of block %d: %d\n',iBlock,blockAddress(iBlock)); end
    blockNameSub{iBlock}    = fread(fid,16,'*char'); 	if VERBOSE, fprintf('name of waveform block: %s\n',blockName{iBlock}); end
end
if length(find(blockAddress))>1, fprintf('Note: more than 1 block contains info... will loop over blocks!'); end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-EVENT LOG BLOCK: jump to the first (and only) occupied block (perhaps get 2 blocks if >255 annotations?)
iEvTot = 1;
for iBlock=1:blockCnt,
    fseek(fid,blockAddress(iBlock),'bof');
    x=fread(fid,1,'*uint8');                                if VERBOSE, fprintf('block ID: %d\n',x); end
    x=fread(fid,16,'*char');                                if VERBOSE, fprintf('data name: %s\n',x); end
    x=fread(fid,1,'*uint8');                                if VERBOSE, fprintf('table type: %d\n',x); end
    N=fread(fid,1,'*uint8');                                if VERBOSE, fprintf('event count: %d\n',N); end
    L=fread(fid,1,'*uint8');                                if VERBOSE, fprintf('event length (should be 45): %d\n',L); end
    
    %%- rough check of table contents (all entries are 45 bytes irrespective of detailed format)
    % for iEv=1:N+2,
    %     blkStr = fread(fid,20,'*char');     fprintf('> %s <',  blkStr);
    %     blkStr = fread(fid,25,'*char');     fprintf('> %s <\n', blkStr);
    % end
    
    %- manual makes it sound like 1st event is stored differenly than subsequent events (see below)
    %              ... in practice they are all stored like first
    for iEv=1:N,
        eventName   = fread(fid,20,'*char');                if VERBOSE, fprintf('%d)       name: %s\n',iEv,eventName); end
        elapseTime  = fread(fid,6, '*char');                if VERBOSE, fprintf('  elapsed time: %s (hhmmss)\n',elapseTime); end
        clockTime   = fread(fid,14,'*char');                if VERBOSE, fprintf('    clock time: %s (yyMMddhhmmss)\n',clockTime); end
        blockNum    = fread(fid,1, '*int8');                if VERBOSE, fprintf('  wave blk num: %d\n',blockNum); end
        sysEcode    = fread(fid,1, '*int8');                if VERBOSE, fprintf(' system e-code: %d\n',sysEcode); end
        eventType   = fread(fid,1, '*int8');                if VERBOSE, fprintf('    event type: %d\n',eventType); end
        eventPage   = fread(fid,1, '*int16');               if VERBOSE, fprintf('    event page: %d\n',eventPage); end
        
        elapseTimeSec = str2num(elapseTime(1:2)')*3600 + str2num(elapseTime(3:4)')*60 + str2num(elapseTime(5:6)') ;
        if VERBOSE, fprintf('  elapsed time: %.1f (sec)\n',elapseTimeSec); end
        ev(iEvTot).str     = eventName;
        ev(iEvTot).timeSec = elapseTimeSec;
        ev(iEvTot).type    = eventType; %0 for system, 1 for user input
        iEvTot=iEvTot+1;
    end
    
    % %- subsequent events supposed to be stored like this, but they aren't
    % for iEv=1:N,
    %     eventName   = fread(fid,20,'*char');                if VERBOSE, fprintf('%d)       name: %s\n',iEv,eventName); end
    %     elapseTime  = fread(fid,4, '*char');                if VERBOSE, fprintf(' elapsed time1: %s (hhhh)\n',elapseTime); end
    %     elapseTime2 = fread(fid,6, '*char');                if VERBOSE, fprintf(' elapsed time2: %s (cccuuu)\n',elapseTime2); end
    %     clockTime   = fread(fid,4, '*char');                if VERBOSE, fprintf('   clock time1: %s (yyyy)\n',clockTime); end
    %     clockTime2  = fread(fid,6, '*char');                if VERBOSE, fprintf('   clock time2: %s (cccuuu)\n',clockTime2); end
    %     reserved    = fread(fid,5, '*char');                if VERBOSE, fprintf('      reserved: %s\n',reserved); end
    % end
end

%- trim out system events
iUser = find([ev.type]==1);
ev = ev([iUser]);

%- save to output structure
annotationStruct = ev;












