function ao_split(homeDir, subject, T_date, traj, dataFile, tFlag)
% The old extraction file for the old alpha omega machine that is no longer used
% script retired Dec 2015. Kept in eeg_extract in case anyone wants to
% extract old alpha omega data someday

% raw data into non-reref (bandpass 1-500Hz) & spiking (300-3000Hz)
%
% INPUT ARGs:
% subject        - subject ID ('DBS006')
% T_date         - date of recording for filename in eeg.noreref (060911)
% traj           - trajectory directory for raw data (1 to 12)
% dataFile       - name of raw data file based on depth (-00990)
% homeDir        - DBS home directory ('Users/yangai/Desktop/DBStest')
% tFlag          - flag for whether there was an associated task w/ pulses

% 0. define indices based on readme file, if available
if exist(fullfile(homeDir,subject,'docs','dbs_readme.mat'))
    load(fullfile(homeDir,subject,'docs','dbs_readme.mat'))
    no=DBS_params.tracks.no; traj_no=str2num(traj);
    if ~isempty(find(no==traj_no)) && isempty(find(no==(traj_no+1))) && isempty(find(no==(traj_no+2)))
    	LFP_index=[1 4];
        reref_LFP_index=[];
        spike_index=1;
    elseif ~isempty(find(no==traj_no)) && ~isempty(find(no==(traj_no+1))) && isempty(find(no==(traj_no+2)))
    	LFP_index=[1 2 4 5];
        reref_LFP_index=[1 4];
        spike_index=1:2;
    elseif ~isempty(find(no==traj_no)) && ~isempty(find(no==(traj_no+1))) && ~isempty(find(no==(traj_no+2)))
        LFP_index=1:6;
        reref_LFP_index=1:6;
        spike_index=1:3;
    elseif isempty(find(no==traj_no)) && isempty(find(no==(traj_no+1))) && isempty(find(no==(traj_no+2)))
        LFP_index=[];
        reref_LFP_index=[];
        spike_index=[];
    else
    	disp('error'); keyboard;
    end
else
    LFP_index=1:6;
    reref_LFP_index=1:6;
    spike_index=1:3;
end

% 1. define and create directories
outputDir = fullfile(homeDir, subject, 'eeg.noreref/'); %define LFP output directory
outputDir_reref = fullfile(homeDir, subject, 'eeg.reref/'); %define re-referenced LFP output directory
spikeDir = fullfile(homeDir, subject, 'spikes/'); %define MUA output directory
rawData = load(fullfile(homeDir,subject,'raw', ['traj' traj],[dataFile '.mat'])); %location of raw data
electrodeDepth = dataFile;

if ~isfield(rawData,'CLFP1_KHz'); return; end;
if ~exist(outputDir); mkdir(outputDir); disp('eeg.noreref directory has been created'); end;
if ~exist(outputDir_reref); mkdir(outputDir_reref); disp('eeg.reref directory has been created'); end;
if ~exist(spikeDir); mkdir(spikeDir); disp('spikes directory has been created'); end;

sessName=sprintf('%s_%s_%s_%s',subject,T_date,traj,electrodeDepth);
filestem=fullfile(outputDir,sessName);
filestem_reref=fullfile(outputDir_reref,sessName);

% 2. extract data from raw files & resample (1kHz for LFP, 25kHz for MUA)
samprate_LFP=rawData.CLFP1_KHz*1000;
samprate_LFP_new=1000;
[fsorig_LFP, fsres_LFP] = rat(samprate_LFP/samprate_LFP_new);
chan{4}=resample(rawData.CLFP1,fsres_LFP,fsorig_LFP);
chan{5}=resample(rawData.CLFP2,fsres_LFP,fsorig_LFP);
chan{6}=resample(rawData.CLFP3,fsres_LFP,fsorig_LFP);

% early subjects didn't have "CRaw" electrode.
samprate_spikes_new=25000;
if ~isfield(rawData,'CRaw1_KHz')
    rawData.CRaw1_KHz=rawData.CElectrode1_KHz;
    rawData.CRaw1=rawData.CElectrode1;
    rawData.CRaw2=rawData.CElectrode2;
    rawData.CRaw3=rawData.CElectrode3;
end
samprate_Raw = rawData.CRaw1_KHz*1000;
[fsorig_spikeLFP, fsres_spikeLFP] = rat(samprate_Raw/samprate_LFP_new);
[fsorig_spike, fsres_spike] = rat(samprate_Raw/samprate_spikes_new);
chan{1}=resample(rawData.CRaw1,fsres_spikeLFP,fsorig_spikeLFP);
chan{2}=resample(rawData.CRaw2,fsres_spikeLFP,fsorig_spikeLFP);
chan{3}=resample(rawData.CRaw3,fsres_spikeLFP,fsorig_spikeLFP);
spikeData{1}=resample(rawData.CRaw1,fsres_spike,fsorig_spike);
spikeData{2}=resample(rawData.CRaw2,fsres_spike,fsorig_spike);
spikeData{3}=resample(rawData.CRaw3,fsres_spike,fsorig_spike);

if tFlag
    samprate_trig=rawData.C1_DI005_KHz*1000;
    [fsorig_trig, fsres_trig] = rat(samprate_trig/samprate_LFP_new);
    chan{9}=round(rawData.C1_DI005_Up*fsres_trig/fsorig_trig);
end

clear data

% 3. make jacksheet.txt
jackFile=sprintf('%s.jacksheet.txt',filestem);
fileOut = fopen(jackFile,'w','l');

if fileOut==-1; error('Jacksheet output directory is not found.'); end;

if find(LFP_index==1); fprintf(fileOut,'%d %s\n',1,['microLFP1_traj' traj]); end
if find(LFP_index==2); fprintf(fileOut,'%d %s\n',2,['microLFP2_traj' traj]); end
if find(LFP_index==3); fprintf(fileOut,'%d %s\n',3,['microLFP3_traj' traj]); end
if find(LFP_index==4); fprintf(fileOut,'%d %s\n',4,['LFP1_traj' traj]); end
if find(LFP_index==5); fprintf(fileOut,'%d %s\n',5,['LFP2_traj' traj]); end
if find(LFP_index==6); fprintf(fileOut,'%d %s\n',6,['LFP3_traj' traj]); end
if tFlag; fprintf(fileOut,'%d %s\n',9,'TTL_Up'); end
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
    syncPulses=double(chan{9})';
    fileOut = fopen(syncFile,'w','l');
    fprintf(fileOut,'%i \n', syncPulses);
    fclose(fileOut);
    %     fprintf('sync.txt is made\n')
end

% 6. make non-reref, reref, MUA data files
nyquist_freq_LFP=samprate_LFP_new/2; 
wo_LFP=[1 nyquist_freq_LFP*(1-.00001)]/nyquist_freq_LFP; % bandpass 1Hz to Nyquist*(1-.00001)
[b_LFP, a_LFP] = butter(2,wo_LFP);

%get common average across recorded channels
commonav_macro=mean(reshape(cell2mat(chan(LFP_index(LFP_index>3))),[length(chan{4}) length(LFP_index(LFP_index>3))]),2)'; 
commonav_micro=mean(reshape(cell2mat(chan(LFP_index(LFP_index<4))),[length(chan{1}) length(LFP_index(LFP_index<4))]),2)';
for c=LFP_index
    chanfile = sprintf('%s.%03i', filestem,c);
    fchan = fopen(chanfile,'w','l');
    fwrite(fchan,filtfilt(b_LFP,a_LFP,chan{c}),'int16');
    fclose(fchan);
    % export data rereferenced to common average
    chanfile_reref = sprintf('%s.%03i', filestem_reref,c);
    fchan_reref = fopen(chanfile_reref,'w','l');
    if c>3
        fwrite(fchan_reref,filtfilt(b_LFP,a_LFP,chan{c}-commonav_macro),'int16');
    else
    	fwrite(fchan_reref,filtfilt(b_LFP,a_LFP,chan{c}-commonav_micro),'int16');
    end
    fclose(fchan_reref);
end

c_reref=[1 2 1 4 5 4;2 3 3 5 6 6];
for c=reref_LFP_index
    chanfile_reref = sprintf('%s.%03i-%03i', filestem_reref,c_reref(1,c),c_reref(2,c));
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
    fwrite(fid,data','int16');  %Save for plexon. written column by column.  
    fclose(fid);
end

fprintf('Data Extraction for traj %s, depth %s Complete\n\n',traj, dataFile)