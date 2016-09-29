function [sessName]=br_split(homeDir, subject, T_date, dataFile, tFlag)
% raw data into non-reref (bandpass 1-500Hz) & spiking (300-3000Hz)
%
% INPUT ARGs:
% subject        - subject ID ('DBS006')
% T_date         - date of recording for filename in eeg.noreref (060914)
% dataFile       - name of raw data file  based on time and date ('20140425-103248-001')
% homeDir        - DBS home directory ('/Volumes/shares/FRNU/dataworking/dbs/')
% tFlag          - flag for whether there was an associated task w/ pulses

% 1. define and create directories
inputDir=fullfile(homeDir, subject, 'raw/br/');
outputDir = fullfile(homeDir, subject, 'eeg.noreref/'); %define LFP output directory
outputDir_reref = fullfile(homeDir, subject, 'eeg.reref/'); %define re-referenced LFP output directory
if ~exist(outputDir); mkdir(outputDir); disp('eeg.noreref directory has been created'); end;
if ~exist(outputDir_reref); mkdir(outputDir_reref); disp('eeg.reref directory has been created'); end;

t=dir([inputDir dataFile '.ns3']);
sessName=sprintf('%s_%s_%s',subject,T_date,regexprep(t.date(end-7:end-3), ':', ''));
filestem=fullfile(outputDir,sessName);
filestem_reref=fullfile(outputDir_reref,sessName);


% 2. extract data from raw files & resample 
NSxdata = openNSx([inputDir dataFile '.ns3']); % load the data
channellabels={NSxdata.ElectrodesInfo.Label};
samprate_orig=NSxdata.MetaTags.SamplingFreq; % find sample rate
samprate_new=1000;
[fsorig, fsres] = rat(samprate_orig/samprate_new); % resample
chan=cell(length(NSxdata.ElectrodesInfo),1);
for channel=1:length(NSxdata.ElectrodesInfo)
    chan{channel}=resample(double(NSxdata.Data(channel,:)),fsres,fsorig);
end

clear NSxdata

% 3. make jacksheet.txt
jackFile=sprintf('%s.jacksheet.txt',filestem);
fileOut = fopen(jackFile,'w','l');
if fileOut==-1; error('Jacksheet output directory is not found.'); end;
for channel=1:length(chan)
    fprintf(fileOut,'%d %s\n',channel,channellabels{channel}); 
end
fclose(fileOut);


% 4. make params.txt
paramsFile=fullfile(outputDir,'params.txt');
fileOut = fopen(paramsFile,'w','l');
if fileOut==-1; error('params output directory is not found.'); end;

fprintf(fileOut,'samplerate %0.11f\n',samprate_new);
fprintf(fileOut,'dataformat ''int16''\n');
fprintf(fileOut,'gain %d\n',1);
fclose(fileOut);

system(sprintf('cp %s %s',paramsFile,fullfile(outputDir_reref,'params.txt')));
% fprintf('params.txt is made\n')

% 5. make sync.txt
if tFlag
    % find the pulses
    trigchan=find(~cellfun('isempty', regexp(channellabels, 'ainp1')));
    [syncPulses]=get_triggers(chan{trigchan}',samprate_new);
    syncFile=sprintf('%s.sync.txt',filestem);
    fileOut = fopen(syncFile,'w','l');
    fprintf(fileOut,'%i \n', syncPulses{1});
    fclose(fileOut);
    %     fprintf('sync.txt is made\n')
end

% 6. make non-reref and reref files
nyquist_freq=samprate_new/2; 
wo=[1 nyquist_freq*(1-.00001)]/nyquist_freq; % bandpass 1Hz to Nyquist*(1-.00001)
[b, a] = butter(2,wo);

%get common average across recorded channels
nontrigchans=find(cellfun('isempty', regexp(channellabels, 'ainp1')));
commonav=mean(cell2mat(chan(nontrigchans)),1); 
for c=nontrigchans
    chanfile = sprintf('%s.%03i', filestem,c);
    fchan = fopen(chanfile,'w','l');
    fwrite(fchan,filtfilt(b,a,chan{c}),'int16');
    fclose(fchan);
    % export data rereferenced to common average
    chanfile_reref = sprintf('%s.%03i', filestem_reref,c);
    fchan_reref = fopen(chanfile_reref,'w','l');
    fwrite(fchan_reref,filtfilt(b,a,chan{c}-commonav),'int16');
    fclose(fchan_reref);
end

if length(chan)>7
    c_reref=[1 2 3 4 5 7 8 9 10 11 12 13;2 3 4 5 6 8 9 10 11 12 13 14]; % this is if the IFG was also recorded
else
    c_reref=[1 2 3 4 5;2 3 4 5 6];
end
for c=1:size(c_reref,2)
    chanfile_reref = sprintf('%s.%03i-%03i', filestem_reref,c_reref(1,c),c_reref(2,c));
    fchan_reref = fopen(chanfile_reref,'w','l');
    fwrite(fchan_reref,filtfilt(b,a,chan{c_reref(1,c)}-chan{c_reref(2,c)}),'int16');
    fclose(fchan_reref);
end


fprintf('Data Extraction for Blackrock File %s Complete\n\n', dataFile)
 