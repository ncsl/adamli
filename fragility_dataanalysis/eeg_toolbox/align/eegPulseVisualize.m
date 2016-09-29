function eegPulseVisualize2(rawPath,ekgTagName)

% function ekgPulseVisualize(eegDir)
%   Description: visualizes the .sync pulses
%
%   --Input:
%       rawPath: path to .21E file or directory containing raw files.
%                 all subdirectories labeled "raw", "DAY", or "SESS" will be searched for raw files.
%
%       e.g.  /Volumes/Kareem/data/eeg/NIH018/raw/DAY_3/DA8661N4.21E  will extract and plot just DA8661N4.21E and .EEG
%       e.g.  /Volumes/Kareem/data/eeg/NIH018/raw/DAY_4/SESS_C        will just extract & plot DAY_4/Sess_C
%       e.g.  /Volumes/Kareem/data/eeg/NIH018/raw/                    will  extract & plot all days, all sessions
%
%       ekgTagName:  tag of electrodes with pulse signal, usually 'EKG' or 'DC09'; can pass in a two-element cell array to exactly specify tags (e.g. {'EKG1', 'EKG2'} or {'DC09'}
%
%
%   --Outputs:
%             --plot(s) that shows pulses
%
%   UPDATED 10/2015 so it can handle original EEG-1100 and "new" EEG-1200 extended file formats JW
%

FIX_FIGURE_NUM       = 101;

FIGURE_FOR_EACH_RAW  = 0; %each raw in its own figure
FIGURE_WITH_ALL_RAWS = 1; %single figure with subplots


fprintf('\n\nSearching for .21E and .EEG files in %s:\n', rawPath);
eegRootList = {};
eegRootList = findRaws(rawPath, eegRootList);


subjStr = '';
if ~isempty(strfind(rawPath,'eeg/NIH')),
    iSubjStr = strfind(rawPath,'eeg/NIH')+[4:9];
    subjStr = sprintf(' -- %s -- ', rawPath(iSubjStr) );
end

RAW_ROOT = 0;
if strcmp('raw',rawPath(end-2:end)) | strcmp('raw',rawPath(end-3:end-1)),
    RAW_ROOT = 1;
end


STIM_ROOT = 0;
if strcmp('STIM',rawPath(end-3:end)) | strcmp('STIM',rawPath(end-4:end-1)),
    STIM_ROOT = 1;
end


fprintf('\n')
if length(eegRootList)==0, fprintf('> No files found!!\n\n');
else
    numRow = min( [5 length(eegRootList)] );
    numCol = 0 + (ceil(length(eegRootList)/numRow));
    
    if (length(eegRootList)==1), FIGURE_WITH_ALL_RAWS=0; FIGURE_FOR_EACH_RAW=1; end;
    
    if length(ekgTagName)==2,   ekgTag2out = ekgTagName{2};
    else                        ekgTag2out = 'gnd'; end
    
    %- grab all the data (and the embedded dates for sorting the output plots)
    for iList=1:length(eegRootList),
        %-create a clean version of the path for the figure title (and commandline output)
        clnTitle = sprintf('%s <%s>', eegRootList{iList}, ekgTagName{1});;
        clnTitle(find(clnTitle=='_' | clnTitle=='\'))=' ';
        if ~isempty(strfind(clnTitle,'raw')), clnTitle = clnTitle(strfind(clnTitle,'raw'):end); end
        
        fprintf('... loading %d of %d: %s ...',iList,length(eegRootList),clnTitle)
        
        %disp(eegRootList{iList});
        [EKG1, EKG2, sampRate, strTime, numTime, annOut] = grabPulses(eegRootList{iList},ekgTagName);
        
        %%fake data for testing plot functions
        %EKG1 = rand(1000,1); EKG2 = rand(1000,1); sampRate=1000; strTime = 'blah'; numTime = datenum(now)+rand(1);
        
        fprintf(' [%s]\n', strTime);
        
        list_clnTitle{iList} = clnTitle;
        list_EKG1{iList}     = EKG1;
        list_EKG2{iList}     = EKG2;
        list_sampRate{iList} = sampRate;
        list_strTime{iList}  = strTime;
        list_numTime(iList)  = numTime;
        list_annOut{iList}   = annOut; %-structure with annotation information
    end
    
    
    %- open the figure and make full screen so axis are sized correctly before automatic save
    if FIGURE_WITH_ALL_RAWS,
        if FIX_FIGURE_NUM==0, hFig = figure;
        else                  hFig = figure(FIX_FIGURE_NUM); set(hFig,'name',sprintf('%s All Raw Files <%s>',subjStr, ekgTagName{1})); set(hFig,'Color','w','units','normalized','outerposition',[0 0 1 1]); end
        clf;
    end
    
    
    %- sort the list by embedded raw date/time
    [sorted, iSort] = sort(list_numTime);
    
    
    %- now plot all the loaded data!
    for iList = iSort,
        
        clnTitle = list_clnTitle{iList};
        EKG1     = list_EKG1{iList};
        EKG2     = list_EKG2{iList};
        sampRate = list_sampRate{iList};
        strTime  = list_strTime{iList};
        numTime  = list_numTime(iList);
        annOut   = list_annOut{iList};
        
        plotNum  = find(iSort==iList);
        
        if FIGURE_WITH_ALL_RAWS,
            figure(hFig);
            
            subplot(numRow,numCol,plotNum)
            t = [1:length(EKG1)]/sampRate/60;  %convert to minutes
            plot(t, EKG1-EKG2)
            
            xlabel('time (min)')
            %title( sprintf('%s  [%s]',clnTitle, strTime),'fontsize', 15);
            title( sprintf('%s',clnTitle),'fontsize', 15);
            set(gca,'box','off','tickdir','out');
            hT=text(mean(get(gca,'xlim')),max(get(gca,'ylim'))*.99,sprintf('[%s]',strTime));
            set(hT,'fontsize',18,'HorizontalAlignment','center','VerticalAlignment','top');
            %legend(strTime)
            
        end
        
        if FIGURE_FOR_EACH_RAW,
            figure(FIX_FIGURE_NUM+plotNum); clf
            set(gcf,'name',clnTitle, 'color', 'w')
            
            t = [1:length(EKG1)]/sampRate;  %convert to seconds for the individual figures
            
            if length(find(EKG2~=0))>0, OK_EKG2 = 1; else OK_EKG2 = 0; end
            if sum(~cellfun('isempty',strfind(ekgTagName,'DC'))), strUnits = '(mV)'; else strUnits = '(uV)'; end
            
            annFont = 15;
            
            
            %%- top plot (or only plot) is the difference between EKG1 and 2
            subplot(1+OK_EKG2*2,1,1); thisAx(1) = gca;
            plot(t, EKG1-EKG2, '-'); hold on
            yAnn = 0;
            for iAnn = 1:length(annOut.samp),
                hPt = plot(t(annOut.samp(iAnn)),yAnn,'*b','MarkerSize',15);
                hTx = text(t(annOut.samp(iAnn)),yAnn,annOut.text{iAnn},'Rotation',90,'FontSize',annFont);
            end
            axis tight
            grid on
            box off
            
            set(gca,'fontsize',13);
            ylabel(sprintf('%s-%s %s',ekgTagName{1},ekgTag2out, strUnits));
            xlabel('time (s)', 'fontsize',13)
            title(clnTitle,'fontsize', 15);
            legend(strTime)
            
            %%- if EKG2 is non-zero, then plot EGK1 and EGK2 separately
            if OK_EKG2,
                subplot(2+OK_EKG2,1,2); thisAx(2) = gca;
                plot(t, EKG1,'r'); hold on;
                grid on; box off; set(gca,'fontsize',13);
                if ~isempty(strfind(ekgTagName{1},'DC')), strUnits = '(mV)'; else strUnits = '(uV)'; end
                ylabel(sprintf('%s %s',ekgTagName{1},strUnits));
                %title(clnTitle,'fontsize', 15);
                yAnn = 0;
                for iAnn = 1:length(annOut.samp),
                    hPt = plot(t(annOut.samp(iAnn)),yAnn,'*b','MarkerSize',15);
                    hTx = text(t(annOut.samp(iAnn)),yAnn,annOut.text{iAnn},'Rotation',90,'FontSize',annFont);
                end
                
                subplot(3,1,3); thisAx(3) = gca;
                plot(t, EKG2,'b'); hold on;
                grid on; box off; set(gca,'fontsize',13);
                if ~isempty(strfind(ekgTagName{2},'DC')), strUnits = '(mV)'; else strUnits = '(uV)'; end
                ylabel(sprintf('%s %s',ekgTagName{2},strUnits));
                xlabel('time (s)', 'fontsize',13)
                yAnn = 0;
                for iAnn = 1:length(annOut.samp),
                    hPt = plot(t(annOut.samp(iAnn)),yAnn,'*m','MarkerSize',15);
                    hTx = text(t(annOut.samp(iAnn)),yAnn,annOut.text{iAnn},'Rotation',90,'FontSize',annFont);
                end
            end
            
            linkaxes(thisAx,'x')
            
            
            %%% ---  If annotation present, make the same plot in a vertical axis --- %%%
            if length(annOut.samp)>0,
                figure(FIX_FIGURE_NUM+50+plotNum); clf
                set(gcf,'name',clnTitle, 'color', 'w')
                
                
                subplot(1,1+OK_EKG2,1);  vertAx(1) = gca;
                plot(EKG1,t,'r'); hold on; grid on;
                if sum(~cellfun('isempty',strfind(ekgTagName,'DC'))), xlabel(sprintf('%s (mV)',ekgTagName{1})); else xlabel(sprintf('%s (uV)',ekgTagName{1})); end
                yAnn = 0;
                for iAnn = 1:length(annOut.samp),
                    hPt = plot(yAnn,t(annOut.samp(iAnn)),'*b','MarkerSize',15);
                    hTx = text(yAnn,t(annOut.samp(iAnn)),annOut.text{iAnn},'Rotation',0,'FontSize',annFont);
                end
                set(gca,'fontsize',13);
                set(vertAx(1),'YDir','reverse','Ylim',[0 max(t)]);
                
                if OK_EKG2,
                    subplot(1,2,2);  vertAx(2) = gca; set(gca,'YDir','reverse');
                    plot(EKG2,t,'b'); hold on;  grid on;
                    xlabel(ekgTag2out);
                    yAnn = 0;
                    for iAnn = 1:length(annOut.samp),
                        hPt = plot(yAnn,t(annOut.samp(iAnn)),'*m','MarkerSize',15);
                        hTx = text(yAnn,t(annOut.samp(iAnn)),annOut.text{iAnn},'Rotation',0,'FontSize',annFont);
                    end
                    set(vertAx(2),'YDir','reverse','Ylim',[0 max(t)]);
                end
                set(gca,'fontsize',13);
                
                linkaxes(vertAx,'y')
                
            end
            
        end
    end
    
    %- save a copy of the master figure to subjet's raw directory
    if FIGURE_WITH_ALL_RAWS & (RAW_ROOT | STIM_ROOT),
        if STIM_ROOT, fileSaveName = 'align_PlotPulseChannels_STIM';
        else          fileSaveName = 'align_PlotPulseChannels';
        end
        
        if ismac,
            reply = input('\n\n PRESS RETURN TO TAKE SCREENSHOT OF THE MASTER FIG AND DROP IT IN SUBJECT/RAW!!!!\n','s');
            figure(hFig);
            pause(1);
            unix(sprintf('screencapture -T 1 "%s"', fullfile(rawPath, sprintf('%s.png',fileSaveName))));  % quick view on mac
        else
            %- this has become a very big file...
            saveas(hFig, fullfile(rawPath, sprintf('%s.fig',fileSaveName)), 'fig');
            %saveas(hFig, 'align_PulseChannels.pdf', 'pdf');
        end
        
    end
    
end
fprintf('\n')




%%%-----------------------------------------------------------------------%%%
%%% Search all subdirectories and create list of raws
function eegRootList = findRaws(rawPath, eegRootListIn)

%- first check to see if raw file (insteead of raw path)
if ~isempty(strfind(rawPath,'.EEG')) | ~isempty(strfind(rawPath,'.21E')),
    rootEEG = rawPath(1:end-4);
    listEEG = dir([rootEEG '.EEG']);
    list21E = dir([rootEEG '.21E']);
    
    if length(list21E)~=1 || length(listEEG)~=1,
        fprintf('>>> %s missing matched .EEG and .21E files\n', rawPath);
    else
        eegRootListIn{end+1} = fullfile(rootEEG);
        %fprintf('> found %s .EEG and .21E\n', rootEEG)
    end
    %- its not an .EEG or .21E file (should be a directory).  recursively search subdirectories
else
    % gets filepath for .EEG file
    listEEG = dir( fullfile(rawPath, '*.EEG') );
    
    for iList=1:length(listEEG),
        rootEEG = listEEG(iList).name(1:end-4);
        list21E = dir( fullfile(rawPath, [rootEEG '.21E']) );
        
        if length(list21E)~=1, fprintf('>>>>>>>\n> in %s MISSING MATCHED %s .21E .EEG files!!\n>>>>>>>\n', rawPath, listEEG(iList).name);
        else
            eegRootListIn{end+1} = fullfile(rawPath,rootEEG);
            %fprintf('> in %s found %s .EEG and .21E\n', rawPath, rootEEG)
        end
    end
    
    listAll = dir( rawPath );
    for iList=1:length(listAll),
        if listAll(iList).isdir,
            if length(strfind(listAll(iList).name,'DAY_'))==1 | length(strfind(listAll(iList).name,'SESS_'))==1 | length(strfind(listAll(iList).name,'raw'))==1,
                eegRootListIn = findRaws( fullfile(rawPath,listAll(iList).name), eegRootListIn );
            end
        end
    end
end
eegRootList = eegRootListIn;





%%%-----------------------------------------------------------------------%%%
%%% Extract the EKG channels and Raw file creation date
function [EKG1, EKG2, sampRate, strTime, numTime, annOut] = grabPulses(eegRoot,ekgTagName)
VERBOSE = 0; % 1=some info, 2=LOTS of INFO

% gets filepath for .EEG file
EEG_file=[eegRoot '.EEG'];

% Same as above for .21E file
ELEC_file=[eegRoot, '.21E'];

%% gets all the codes and names from the .21E file
[allCodes,allNames] = textread(ELEC_file,'%s%s','delimiter','='); %textread reads data from a txt file and write to multiple outputs
endRange  = find(strcmp(allCodes,'[SD_DEF]')); %finds the range of the electrodes
allCodes  = allCodes(1:endRange-1);  %stores the codes
allNames  = allNames(1:endRange-1);  %stores the names
%disp([allCodes,allNames])
%goodCodes = [0:36 74 75 100:253];
goodCodes = [0:36 42:73 74:77 100:253];  %include DC channels, 42-73, plus mark channels 76-77
badNames  = {'E'};
actualCode_ALL = {};
actualName_ALL = {};
actualNameWbad_ALL = {};  %jw added this... makes it easier to track the file offset for the target channel


%% Gets to data in the waveform block
fid = fopen(EEG_file);
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% skipping EEG device block: 128 bytes, same for new (EEG-1200) and old (EEG-1100) filetypes
%%%%%%%%%%%%%%%%%%%%%%%%%%%
deviceBlockLen=128; %skips the first 128 bytes
fseek(fid,deviceBlockLen,'bof');  %fseek(fileID, offset, origin) moves to specified position in file. bof=beginning of file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% reading EEG1 control Block (contains names and addresses for EEG2 blocks) -- 896 bytes for new and old filetypes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x=fread(fid,1,'*uint8');  if VERBOSE==2, fprintf('block ID: %d\n',x); end
x=fread(fid,16,'*char');  if VERBOSE==2, fprintf('device type: %s\n',x); end;  if strcmp(x(1:9)','EEG-1200A'),NEW_FORMAT=1;else NEW_FORMAT=0; end; 
x=fread(fid,1,'*uint8');  if VERBOSE==2, fprintf('number of EEG2 control blocks: %d\n',x); end
numberOfBlocks=x;
if numberOfBlocks > 1
    % we think we will never have this
    % throw an error for now and re-write code if necessary
    fprintf('ERROR: %d EEG2 control blocks detected (only expecting 1).\n');
    return
end
% if numberOfBlocks is ever > 1, the following should be a for loop
blockAddress=fread(fid,1,'*int32');  if VERBOSE==2, fprintf('address of block %d: %d\n',i,blockAddress); end
x=fread(fid,16,'*char');             if VERBOSE==2, fprintf('name of EEG2 block: %s\n',x); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Reading EEG2m control block (contains names and addresses for waveform blocks)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fseek(fid,blockAddress,'bof');          if VERBOSE==2, fprintf('\nin EEG21 block!\n');  end
x=fread(fid,1,'*uint8');                if VERBOSE==2, fprintf('block ID: %d\n',x); end
x=fread(fid,16,'*char');                if VERBOSE==2, fprintf('data format: %s\n',x); end
numberOfBlocks=fread(fid,1,'*uint8');   if VERBOSE==2, fprintf('number of waveform blocks: %d\n',numberOfBlocks); end
if numberOfBlocks > 2
    % we think we will never have this
    % throw an error for now and re-write code if necessary
    fprintf('ERROR: %d waveform blocks detected (only expecting 1).\n');
    return
end
% if numberOfBlocks is ever > 1, the following should be a for loop
blockAddress=fread(fid,1,'*int32'); if VERBOSE==2, fprintf('address of block %d: %d\n',i,blockAddress); end
x=fread(fid,16,'*char');            if VERBOSE==2, fprintf('name of waveform block: %s\n',x); end

%%%%%%%%%%%%%%%%%%%%%%%
%Reading waveform block -- if New format the original waveform block will contain a single channel (channel 1) for exactly 1 second..
%%%%%%%%%%%%%%%%%%%%%%%
fseek(fid,blockAddress,'bof');      if VERBOSE==2, fprintf('\nin EEG waveform block!\n'); end
x=fread(fid,1,'*uint8');            if VERBOSE==2, fprintf('block ID: %d\n',x); end
x=fread(fid,16,'*char');            if VERBOSE==2, fprintf('data format: %s\n',x); end
x=fread(fid,1,'*uint8');            if VERBOSE==2, fprintf('data type: %d\n',x); end
L=fread(fid,1,'*uint8');            if VERBOSE==2, fprintf('byte length of one data: %d\n',L); end
M=fread(fid,1,'*uint8');            if VERBOSE==2, fprintf('mark/event flag: %d\n',M); end

%%- annonomous function to convert binary to decimal.  input is binary string created with dec2bin
bcdConverter2 = @(strDec2bin)  10*bin2dec(strDec2bin(1:4)) + bin2dec(strDec2bin(5:8));

% get the start time
T_year   = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
T_month  = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
T_day    = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
T_hour   = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
T_minute = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
T_second = bcdConverter2(dec2bin(fread(fid,1,'*uint8'),8));
strTime  = sprintf('%d/%d/%d %02d:%02d:%02d',T_month,T_day,T_year,T_hour,T_minute,T_second); if NEW_FORMAT, strTime=[strTime '(N)']; end
numTime  = datenum(T_year,T_month,T_day,T_hour,T_minute,T_second);

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
if VERBOSE==2, fprintf('Sampling rate: %d Hz\n',actSamplerate); end


% get the number of 100 msec block
num100msBlocks=fread(fid,1,'*uint32');         if VERBOSE==2, fprintf('Length of Session: %2.2f hours\n',double(num100msBlocks)/10/3600); end
numSamples  = actSamplerate*num100msBlocks/10; if VERBOSE==2, fprintf('number of samples: %d\n',numSamples); end
AD_off      = fread(fid,1,'*int16');           if VERBOSE==2, fprintf('AD offset at 0 volt: %d\n',AD_off); end
AD_val      = fread(fid,1,'*uint16');          if VERBOSE==2, fprintf('AD val for 1 division: %d\n',AD_val); end
bitLen      = fread(fid,1,'*uint8');           if VERBOSE==2, fprintf('bit length of one sample: %d\n',bitLen); end
comFlag     = fread(fid,1,'*uint8');           if VERBOSE==2, fprintf('data compression: %d\n',comFlag); end
numChannels = fread(fid,1,'*uint8');           if VERBOSE==2, fprintf('number of RAW recordings: %d\n',numChannels); end


if (numChannels==1 & numSamples-actSamplerate==0) & NEW_FORMAT==0, fprintf('\n expecting old format, but 1 channel for 1 second'); keyboard; end
if (numChannels>1)                                & NEW_FORMAT==1, fprintf('\n expecting new format, but >1 channel ');           keyboard; end

if NEW_FORMAT | (numChannels==1 & numSamples-actSamplerate==0),

    if VERBOSE, fprintf('** New File Format **'); end
    
    %- seek the file location of the new wave data... need to make a pit stop in the new EEG2 header, which will provide the direct address
    
    waveformBlockOldFormat = 39 + 10 + 2*actSamplerate + double(M)*actSamplerate; %- with new format the initial waveform block contains 1 channel (10 bytes of info) for 1 second (2bytes x 1000)
    controlBlockEEG1new    = 1072;
    %controlBlockEEG2new    = 20+24*double(numberOfBlocks); % this isn't working, so read the wave start location from controlBlockEEG2
    blockAddressEEG2       = blockAddress + waveformBlockOldFormat + controlBlockEEG1new;% + controlBlockEEG1new + controlBlockEEG2new;
    
    
    
    %%- brute force: search for strings expected in each control header
    %     fseek(fid,0,'bof');
    %     x=fread(fid,inf,'*char')';
    %     iEEG  = strfind(x,'EEG-');
    %     iTIME = strfind(x,'TIME');
    %     disp(iTIME)  % 6144       17405
    %     disp(iEEG)   %  1         130         151        1026        1047       10193       10218       11265       11292
    %
    %
    %     addTry = blockAddress; %- old wave format (entire old wave is 4049... as expected)
    %     addTry = 10191;  %- EEG1-prime format     (will be 1072... as expected)
    %     addTry = 10216;  %- non-sense
    %     addTry = 11263;  %- EEG2-prime format     (will be 6014... should be 44... seems that I need to read the "address of block XXX")
    %     addTry = 11290;  %- non-sense
    %     addTry = 17403;  %- EEG-prime wave data
    
    
    
    %%- Use the following sections to examine the brute force addresses...
    %     %- EEG1' format
    %     fprintf('\n\n EEG1-prime format\n');
    %     fseek(fid,addTry,'bof');
    %     x=fread(fid,1,'*uint8');                if VERBOSE==2, fprintf('block ID: %d\n',x); end
    %     x=fread(fid,16,'*char');                if VERBOSE==2, fprintf('data format: %s\n',x); end
    %     x=fread(fid,1,'*uint8');                if VERBOSE==2, fprintf('number of waveform blocks: %d\n',x); end;
    %     x=fread(fid,1,'*int64');ii=1;           if VERBOSE==2, fprintf('address of block %d: %d\n',ii,x); end
    %     x=fread(fid,16,'*char');                if VERBOSE==2, fprintf('name of waveform block: %s\n',x); end
    %     x=fread(fid,1,'*int64');ii=2;           if VERBOSE==2, fprintf('address of block %d: %d\n',ii,x); end;
    %     x=fread(fid,16,'*char');                if VERBOSE==2, fprintf('name of waveform block: %s\n',x); end
    %
    %     %- EEG2' format
    %     addTry = blockAddressEEG2;
    %     fprintf('\n\n EEG2-prime format\n');
    %     fseek(fid,addTry,'bof');
    %     x=fread(fid,1,'*uint8');                if VERBOSE==2, fprintf('block ID: %d\n',x); end
    %     x=fread(fid,16,'*char');                if VERBOSE==2, fprintf('data format: %s\n',x); end
    %     x=fread(fid,1,'*uint16');               if VERBOSE==2, fprintf('number of waveform blocks: %d\n',x); end;
    %     x=fread(fid,1,'*char');                 if VERBOSE==2, fprintf('reserved: %s\n',x); end
    %     x=fread(fid,1,'*int64');ii=1;           if VERBOSE==2, fprintf('address of block %d: %d\n',ii,x); end
    %     waveBlockNew = x;
    %     x=fread(fid,16,'*char');                if VERBOSE==2, fprintf('name of waveform block: %s\n',x); end
    %     x=fread(fid,1,'*int64');ii=2;           if VERBOSE==2, fprintf('address of block %d: %d\n',ii,x); end;
    %     x=fread(fid,16,'*char');                if VERBOSE==2, fprintf('name of waveform block: %s\n',x); end
    %
    %
    %     addTry = waveBlockNew;
    %     %- EEG2' waveform format
    %     fprintf('\n\n EEG2-prime waveform format\n');
    %     fseek(fid,addTry,'bof');
    %     x=fread(fid,1,'*uint8');            if VERBOSE==2, fprintf('block ID: %d\n',x); end
    %     x=fread(fid,16,'*char');            if VERBOSE==2, fprintf('data format: %s\n',x); end
    %     x=fread(fid,1,'*uint8');            if VERBOSE==2, fprintf('data type: %d\n',x); end
    %     L=fread(fid,1,'*uint8');            if VERBOSE==2, fprintf('byte length of one data: %d\n',L); end
    %     M=fread(fid,1,'*uint8');            if VERBOSE==2, fprintf('mark/event flag: %d\n',M); end
    %     x=fread(fid,20,'*char');            if VERBOSE==2, fprintf('start time string: %s\n',x); end
    
    
    
    
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


%- parse the channel names -- connect .21E information with .EEG information
listChanStringCode = {};
listActualName     = {};
for k=1:numChannels
    x=fread(fid,1,'*int16');  %reads in 1 byte every time you iterate the loop
    chanCode(k)=x; %and stores it in chanCode(k)
    if (VERBOSE) fprintf(' Index %d ''name'': Channel %d\n',k,x); end
    chanCodeString=sprintf('%04d',x); %format data into string. Same as chanCode except the format is string.
    matchingRow=find(strcmp(chanCodeString,allCodes)); %looks for this particular string in allCodes and stores its locations in matchingRow
    actualName=allNames{matchingRow};
    
    listChanStringCode{end+1} = chanCodeString;
    listActualName{end+1} = actualName;
    
    if ~ismember(chanCode(k),goodCodes) %if not a member of goodCodes
        if (VERBOSE) fprintf(' chan %d (%s) is a bad channel code and excluded\n',chanCode(k),actualName); end;
        goodElec(k)=false;
    elseif any(strcmp(actualName,badNames)) %or if it's part of badNames
        if (VERBOSE) fprintf(' chan %d (%s) is a bad address\n',chanCode(k),actualName); end;
        goodElec(k)=false;
    else
        if (VERBOSE) fprintf(' chan %d (%s) is good!\n',chanCode(k),actualName); end
        goodElec(k)=true;
    end
    
    % save out the names for the jacksheet
    if goodElec(k); actualName_ALL(end+1)=allNames(matchingRow); actualCode_ALL{end+1}=chanCodeString; end %if it is a good electrode, append it to the jacksheet
    actualNameWbad_ALL(end+1)=allNames(matchingRow);
    
    fseek(fid,6,'cof'); %skipping the six most sig. bits of 'name'
    
    %finds the channel sensitivity
    chan_sensitivity = fread(fid,1,'*uint8');   if VERBOSE==2, fprintf('channel sensitivity: %d\n',chan_sensitivity); end
    chan_unit        = fread(fid,1,'*uint8');   if VERBOSE==2, fprintf('         unit: %d\n',chan_unit); end
    switch chan_unit,
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
%disp([listChanStringCode' listActualName']);

%- starting point of filepointer for reading the data
fStart = ftell(fid);

tReadAll = tic;
%fprintf('\nReading Data...') %\n means new line
d=fread(fid,[double(numChannels+1) double(numSamples)],'*uint16'); %reads the content into an array
%fprintf('done reading in %.3fs\n', toc(tReadAll))

dEvntMrk = d((numChannels+1),:);  %additional element in time series (chan+1) is 16-bit event/mark data, where bits 7-14 encode DC09-DC13 triggers
trigDC09 = bitget(dEvntMrk,7);
trigDC10 = bitget(dEvntMrk,8);
trigDC11 = bitget(dEvntMrk,9);
trigDC12 = bitget(dEvntMrk,10);
trigDC13 = bitget(dEvntMrk,11);
trigDC14 = bitget(dEvntMrk,12);
trigDC15 = bitget(dEvntMrk,13);
trigDC16 = bitget(dEvntMrk,14);

d=d([goodElec],:);
%fprintf('Removing offsets... total time %.3f s\n', toc(tReadAll))
mark1  = int16(d(find(~cellfun('isempty',strfind(actualCode_ALL,'76'))),:));  %mark channels 76 and 77 are signed
mark2  = int16(d(find(~cellfun('isempty',strfind(actualCode_ALL,'77'))),:));

d_int16=int16(int32(d)+int32(AD_off)); %convert to int16
%the line below proves the above is lossless
%assert(isequal(d,uint16(double(d_int16)-double(AD_off))))
%clear d

%GAIN_DC = 500 / 2730 ; % E11FFmt.pdf says "Ox0555 corresponds to 500 mV"; Ox555 = 1365;  looks like actually OxAAA-->500mV (2730)
GAIN_DC = 500 / 1365 ; % E11FFmt.pdf says "Ox0555 corresponds to 500 mV"; Ox555 = 1365;  looks like actually OxAAA-->500mV (2730)

%%- Now it finds the EKG channels and returns the waveforms
if iscell(ekgTagName) & length(ekgTagName)==2,
    iTemp1 = find(~cellfun('isempty',strfind(actualName_ALL,ekgTagName{1})));
    iTemp2 = find(~cellfun('isempty',strfind(actualName_ALL,ekgTagName{2})));
    if isempty(iTemp1) | isempty(iTemp2),
        fprintf('\nERROR: cant find sync pulse tag %s or %s in the following list:\n', ekgTagName{1},ekgTagName{2});
        disp([listChanStringCode' listActualName']);
        error('revise sync pulse tag name(s) and call eegPulseVisualize again');
    elseif length(iTemp1)>1 & length(iTemp2)>1,
        %designed to catch error with NIH017, where both EKG lines were labeled 'EKG' instead of 'EKG1' and 'EKG2'
        fprintf('\nWARNING: sync pulse tag %s and %s both produce multiple hits... assuming chaCodeString missed suffix:\n', ekgTagName{1},ekgTagName{2});
        iTemp1 = iTemp1(1);
        iTemp2 = iTemp2(2);
    end
    idx(1) = iTemp1;
    idx(2) = iTemp2;
    EKG1 = double(d_int16(idx(1),:))*GAIN_DC; %convert to volts
    EKG2 = double(d_int16(idx(2),:))*GAIN_DC;
else
    iTemp1 = find(~cellfun('isempty',strfind(actualName_ALL,ekgTagName{1})));
    if isempty(iTemp1),
        fprintf('\nERROR: cant find sync pulse tag %s in the following list:\n', ekgTagName{1});
        disp([listChanStringCode' listActualName']);
        error('revise sync pulse tag name(s) and call eegPulseVisualize again');
    end
    idx = iTemp1;
    EKG1 = double(d_int16(idx(1),:))*GAIN_DC; %convert to volts
    EKG2 = zeros(size(EKG1));
end
sampRate = actSamplerate;


%%- Grab info from the LOG file if present
annOut.samp = [];
annOut.text = {};
if ~isempty((trigDC10 > 0) | (trigDC11 > 0) | (trigDC12 >0))
    annStruct = nk_parseAnnotation(eegRoot);
    annTimes = [];
    annStr   = {};
    for iAnn=1:length(annStruct),
        annTimes(iAnn) = (annStruct(iAnn).timeSec+1)*actSamplerate;  %-add 1 sample to avoid indexing 0 (could cause problem for end of file?)
        annStr{iAnn}   = sprintf('  %s',annStruct(iAnn).str);
    end
    annOut.samp = annTimes;
    annOut.text = annStr;
end


%keyboard
%%%%-- following code extracts just a single channel... ends up being much slower than code above! --%%%%
% tReadSelective = tic;
% idx = find(~cellfun('isempty',strfind(actualNameWbad_ALL,ekgTagName)));
% fseek(fid,fStart + (idx(1)-1)*2,-1);  % data is written one time point at a time (all channels) in 2-byte words... offset channNum * 2bytes
% EKG1a = int16(fread(fid,numSamples,'uint16=>int32',numChannels*2)+int32(AD_off));
% fseek(fid,fStart + (idx(2)-1)*2,-1);  % data is written one time point at a time (all channels) in 2-byte words... offset channNum * 2bytes
% EKG2a = int16(fread(fid,numSamples,'uint16=>int32',numChannels*2)+int32(AD_off));
% fprintf('Selective read + offset removal in %.3f\n', toc(tReadSelective));


%%- use the following code to test digital pulses from DC09
TESTING_DIGITAL_PULSES = 0;

if TESTING_DIGITAL_PULSES,
    thisAx = [];
    
    figure(90); clf
    subplot(5,1,1);  thisAx(end+1) = gca;
    plot(mark1);      title('mark1');
    subplot(5,1,2);   thisAx(end+1) = gca;
    plot(mark2);       title('mark2');
    subplot(5,1,3);   thisAx(end+1) = gca;
    plot(trigDC09,'r');  title('trig DC09');
    subplot(5,1,4);   thisAx(end+1) = gca;
    plot(EKG1,'b'); hold on; plot(trigDC09*200,'r');     title(ekgTagName{1});
    subplot(5,1,5);   thisAx(end+1) = gca;
    plot(EKG2);      title(ekgTagName{2});
    linkaxes(thisAx,'x')
    
    figure(91); clf
    plot(EKG1,'b'); hold on; plot(trigDC09*200,'r');     title(ekgTagName{1});
    
    figure(92); clf
    plot(dEvntMrk,'b'); hold on; plot(trigDC09,'r');     title('all mark events');
    
    %keyboard
    filestem = eegRoot;
    if find(trigDC09>0),
        updowns = [trigDC09(1) diff(trigDC09)];
        uptimes = find(updowns==1);
        fprintf('Digital pulse trigger found... extracting sync file:');
        chanfile = sprintf('%s.trigDC09.sync.txt', filestem);
        fchan = fopen(chanfile,'w','l');
        fprintf(fchan,'%d\n',uptimes);
        fclose(fchan);
        fileattrib(chanfile, '+x', 'a'); %JW - change files to "executable"... helps for sorting in mac finder
    end
end
