function no_split(homeDir, subject, T_date, dataFiles)
% THE NEW AND IMPROVED version of ao_split for the new neuroomega machine
    % created Dec 2015
% raw data into non-reref (bandpass 1-500Hz) & spiking (300-3000Hz)
%
% INPUT ARGs:
% subject        - subject ID ('DBS006')
% T_date         - date of recording for filename in eeg.noreref (060911)
% dataFile       - name of raw data file based on depth (-00990)
% homeDir        - DBS home directory ('Users/yangai/Desktop/DBStest')

% 0. define indices based on which channels were recorded. 
% Change these variables here and lower down if there were skipped channels
spike_index=1:3;
LFP_index=4:6;
ecogchannels_index=7:20; 
TTL_index=21;
% the rereference combinations you will use: If you change the channels recorded you will have to edit this. 
c_reref=[1 2; 2 3; 1 3; 4 5; 5 6; 4 6; 7 8; 8 9; 9 10; 10 11; 11 12; 13 14; 14 15; 15 16; 16 17; 17 18; 18 19; 19 20]';  % skip the 6-7 (chan{12}-chan{13} reref combo for ecog

% 1. define and create directories
outputDir = fullfile(homeDir, subject, 'eeg.noreref/'); %define LFP output directory
outputDir_reref = fullfile(homeDir, subject, 'eeg.reref/'); %define re-referenced LFP output directory
spikeDir = fullfile(homeDir, subject, 'spikes/'); %define MUA output directory
if ~exist(outputDir); mkdir(outputDir); disp('eeg.noreref directory has been created'); end;
if ~exist(outputDir_reref); mkdir(outputDir_reref); disp('eeg.reref directory has been created'); end;
if ~exist(spikeDir); mkdir(spikeDir); disp('spikes directory has been created'); end;
electrodeDepth = dataFiles{1}(1:(regexp(dataFiles{1}, 'F')-1));
sessName=sprintf('%s_%s_%s',subject,T_date,electrodeDepth);
% check that this file stem doesn't already exist from a previous recording at the same depth
previousfiles=dir([outputDir sessName '*.jacksheet.txt']);
if ~isempty(previousfiles)
    electrodeDepth=[electrodeDepth '00' num2str(length(previousfiles))]; % append 001 to this repeat
    sessName=sprintf('%s_%s_%s',subject,T_date,electrodeDepth);
end
filestem=fullfile(outputDir,sessName);
filestem_reref=fullfile(outputDir_reref,sessName);

% 2. extract data from raw files & resample (1kHz for LFP, 25kHz for MUA)
chan=cell(max([spike_index LFP_index ecogchannels_index TTL_index]),1);
spikeData=cell(length(spike_index),1);
tFlag=0;
load(fullfile(homeDir,subject,'raw',dataFiles{1}),'CMacro_LFP_01_TimeBegin');  % time of the very first file.
veryfirstfiletime=CMacro_LFP_01_TimeBegin;
for index=1:length(dataFiles)
    
    % check if this file is an extension of the previous recording or a new recording at the same depth
    % If there has been a previous recording, then stop the for loop and
    % call no_split again later 
    load(fullfile(homeDir,subject,'raw',dataFiles{index}),'CMacro_LFP_01_TimeBegin'); 
    if index>1 && (CMacro_LFP_01_TimeBegin-prevfilend)>1 %if longer then 1 second between files, split into two. 1 second cut off arbitrarily chosen
        remainingdataFiles=dataFiles(index:end);
        break
    else % this is either the first file or a continuation of the previous file 
        rawData = load(fullfile(homeDir,subject,'raw',dataFiles{index})); %location of raw data
        if isfield(rawData,'CDIG_IN_1_KHz'); tFlag=1; end % check if there were ttl pulses
        
        samprate_LFP=rawData.CMacro_LFP_01_KHz*1000;
        samprate_LFP_new=1000;
        [fsorig_LFP, fsres_LFP] = rat(samprate_LFP/samprate_LFP_new);
        for LFPchan=LFP_index
            eval(['chan{LFPchan}=[chan{LFPchan} resample(double(rawData.CMacro_LFP_' num2str(LFPchan-LFP_index(1)+1, '%.2d') '),fsres_LFP,fsorig_LFP)];']);
        end

        samprate_ecog=rawData.CECOG_1___01_KHz*1000;
        samprate_ecog_new=1000;
        [fsorig_ecog, fsres_ecog] = rat(samprate_ecog/samprate_ecog_new);
        for ecogchan=ecogchannels_index
            eval(['chan{ecogchan}=[chan{ecogchan} resample(double(rawData.CECOG_1___' num2str(ecogchan-ecogchannels_index(1)+1, '%.2d') '),fsres_ecog,fsorig_ecog)];']);
        end

        samprate_spikes_new=25000;
        samprate_Raw = rawData.CRAW_01_KHz*1000;
        [fsorig_spikeLFP, fsres_spikeLFP] = rat(samprate_Raw/samprate_LFP_new);
        [fsorig_spike, fsres_spike] = rat(samprate_Raw/samprate_spikes_new);
        for spikechan=spike_index
            eval(['chan{spikechan}=[chan{spikechan} resample(double(rawData.CRAW_' num2str(spikechan-spike_index(1)+1, '%.2d') '),fsres_spikeLFP,fsorig_spikeLFP)];']);
            eval(['spikeData{spikechan}=[spikeData{spikechan} resample(double(rawData.CRAW_' num2str(spikechan-spike_index(1)+1, '%.2d') '),fsres_spike,fsorig_spike)];']);
        end
        
        if tFlag && isfield(rawData,'CDIG_IN_1_KHz')
            samprate_trig=rawData.CDIG_IN_1_KHz*1000;
            [fsorig_trig, fsres_trig] = rat(samprate_trig/samprate_LFP_new);
            % each pulse is measured relative to the first pulse in that file. 
            % Therefore, find the time of the first pulse (rawData.CDIG_IN_1_TimeBegin) 
            % relative to overall recording onset time (veryfirstfiletime)
            % and add that time to all subsequent pulses.
            chan{TTL_index}=[chan{TTL_index} 1000*(rawData.CDIG_IN_1_TimeBegin-veryfirstfiletime)+round(double(rawData.CDIG_IN_1_Up)*fsres_trig/fsorig_trig)];
        end    
        
        prevfilend=rawData.CMacro_LFP_01_TimeEnd; % update for the next file in loop.
    end
end


% 3. make jacksheet.txt
jackFile=sprintf('%s.jacksheet.txt',filestem);
fileOut = fopen(jackFile,'w','l');
if fileOut==-1; error('Jacksheet output directory is not found.'); end;
for spikechan=spike_index; fprintf(fileOut,'%d %s\n',spikechan,['microLFP' num2str(spikechan-spike_index(1)+1)]); end
for LFPchan=LFP_index; fprintf(fileOut,'%d %s\n',LFPchan,['LFP' num2str(LFPchan-LFP_index(1)+1)]); end
for ecogchan=ecogchannels_index; fprintf(fileOut,'%d %s\n',ecogchan-ecogchannels_index(1)+501,['ecog chan' num2str(ecogchan-ecogchannels_index(1)+1)]); end
if tFlag; fprintf(fileOut,'%d %s\n',TTL_index,'TTL_Up'); end
fclose(fileOut);
% fprintf('jacksheet.txt is made\n')


% 4. make params.txt
paramsFile=fullfile(outputDir,'params.txt');
fileOut = fopen(paramsFile,'w','l');
if fileOut==-1; error('params output directory is not found.'); end;
fprintf(fileOut,'samplerate %0.11f\n',samprate_LFP_new);
fprintf(fileOut,'dataformat ''int16''\n');
fprintf(fileOut,'gain %d\n',1);
fclose(fileOut);
system(sprintf('cp %s %s',paramsFile,fullfile(outputDir_reref,'params.txt')));
% fprintf('params.txt is made\n')


% 5. make sync.txt
if tFlag
    syncFile=sprintf('%s.sync.txt',filestem);
    syncPulses=double(chan{TTL_index})';
    fileOut = fopen(syncFile,'w','l');
    fprintf(fileOut,'%0.0f \n', round(syncPulses));
    fclose(fileOut);
    %     fprintf('sync.txt is made\n')
end


% 6. make non-reref, reref, MUA data files
nyquist_freq_LFP=samprate_LFP_new/2; 
wo_LFP=[1 nyquist_freq_LFP*(1-.00001)]/nyquist_freq_LFP; % bandpass 1Hz to Nyquist*(1-.00001)
[b_LFP, a_LFP] = butter(2,wo_LFP);

%get common average across recorded channels
commonav_micro=mean(reshape(cell2mat(chan(spike_index)),[length(chan{spike_index(1)}) length(spike_index)]),2)';
commonav_macro=mean(reshape(cell2mat(chan(LFP_index)),  [length(chan{LFP_index(1)})   length(LFP_index)]),2)'; 
commonav_ecog =mean(reshape(cell2mat(chan(ecogchannels_index)),[length(chan{ecogchannels_index(1)}) length(ecogchannels_index)]),2)';
for c=[spike_index LFP_index ecogchannels_index]
    chanfile = sprintf('%s.%03i', filestem,c);
    if c>=(ecogchannels_index(1)); chanfile = sprintf('%s.%03i', filestem,c-ecogchannels_index(1)+501); end % add 501 to the name for ecog
    fchan = fopen(chanfile,'w','l');
    fwrite(fchan,filtfilt(b_LFP,a_LFP,chan{c}),'int16');
    fclose(fchan);
    % export data rereferenced to common average
    chanfile_reref = sprintf('%s.%03i', filestem_reref,c);
    if c>=(ecogchannels_index(1)); chanfile_reref = sprintf('%s.%03i', filestem_reref,c-ecogchannels_index(1)+501); end % add 501 to the name for ecog
    fchan_reref = fopen(chanfile_reref,'w','l');
    if c<=spike_index(end)
        fwrite(fchan_reref,filtfilt(b_LFP,a_LFP,chan{c}-commonav_micro),'int16');
    elseif c>=LFP_index(1) && c<=LFP_index(end)
        fwrite(fchan_reref,filtfilt(b_LFP,a_LFP,chan{c}-commonav_macro),'int16');
    elseif c>=ecogchannels_index(1)
        fwrite(fchan_reref,filtfilt(b_LFP,a_LFP,chan{c}-commonav_ecog),'int16');
    end
    fclose(fchan_reref);
end

for c=1:length(c_reref)
    chanfile_reref = sprintf('%s.%03i-%03i', filestem_reref,c_reref(1,c),c_reref(2,c));
    if c>=(ecogchannels_index(1)); chanfile_reref = sprintf('%s.%03i-%03i', filestem_reref,c_reref(1,c)-ecogchannels_index(1)+501,c_reref(2,c)-ecogchannels_index(1)+501); end % add 501 to the name for ecog
    fchan_reref = fopen(chanfile_reref,'w','l');
    fwrite(fchan_reref,filtfilt(b_LFP,a_LFP,chan{c_reref(1,c)}-chan{c_reref(2,c)}),'int16');
    fclose(fchan_reref);
end

%set up spike filter parameters
nyquist_freq_spikes=(samprate_spikes_new/2);   
wo_spike=[300 3000]/nyquist_freq_spikes; % bandpass 300Hz to 3000HZ
[b_spike,a_spike] = butter(2,wo_spike);

if ~exist([spikeDir sessName]); mkdir([spikeDir sessName]); end; % disp('spikes directory has been created');
for c=spike_index
    data=filtfilt(b_spike,a_spike,spikeData{c});
    if ~exist([spikeDir sessName '/chan_' num2str(c)]);mkdir([spikeDir sessName '/chan_' num2str(c)]); end
    save([spikeDir sessName '/chan_' num2str(c) '/' sessName '.00', num2str(c) '.mat'], 'data');
    fid = fopen([spikeDir sessName '/chan_' num2str(c) '/' sessName '.00', num2str(c) '_plexon.bin'], 'w');
    fwrite(fid,50*data','int16');  %Save for plexon. written column by column.  
    fclose(fid);
end

fprintf('Data Extraction for depth %s Complete\n\n',electrodeDepth)
if exist('remainingdataFiles')% extract the next file at the same depth
    no_split(homeDir, subject, T_date, remainingdataFiles)
end

