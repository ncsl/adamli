function [nkfilestemorig]=nk_split_dbs_wrapper(homeDir, subject, session)
% extracts nk data collected during dbs surgeries
%
% INPUT ARGs:
% subject        - subject ID ('DBS006')
% homeDir        - DBS home directory ('/Volumes/shares/FRNU/dataworking/dbs/')
% session        - the session name ('0')

% OUTPUT ARGs:
% nkfilesemorig  - the filestem under which nksplit saves the data

nk_split(subject, [homeDir '/' subject '/raw/nk/session_' session],{'foo'}); %extract the data. the foo arguement is just because the final input can't be empty.
t=dir(fullfile(homeDir, subject, 'eeg.noreref', ['*' '.trigDC09.sync.txt' ])); %find the nk data's sync file so you can get the file stem
nkfilestemorig=t.name(1:regexp(t.name, '.trigDC09.sync.txt')-1); % get the filestem. 
nkfiles=dir(fullfile(homeDir, subject, 'eeg.noreref', [nkfilestemorig '.*'])); % get the nk files
nkfiles=nkfiles(cellfun('isempty', regexp({nkfiles.name}, '.txt')));  % exclude the text files (params, jacksheet, sync)
chan=cell(length(nkfiles),1);
%load the data
for c = 1:length(nkfiles)
    fchan = fopen(fullfile(homeDir, subject, 'eeg.noreref',nkfiles(c).name), 'r','l');
    chan{c} =  fread(fchan, inf, 'int16')';
    fclose(fchan);
end

% make non-reref and reref files
samprate = GetRateAndFormat( fullfile(homeDir, subject, 'eeg.noreref', [nkfilestemorig '.params.txt' ]));
if samprate~=1000;
    warning('The samplerate is not 200 Hz for the ecog data. I will resample to 1000Hz'); 
    % resample the ecog data
    [fsorig, fsres] = rat(samprate/1000);
    for c=1:length(chan)
        chan{c}=resample(chan{c},fsres,fsorig);
    end
    % load and resample the trig data then save it
    syncFile=fullfile(homeDir, subject, 'eeg.noreref', [nkfilestemorig '.trigDC09.sync.txt' ]);
    trigorig=textread(syncFile,'%n%*[^\n]','delimiter','\t');
    trig1000=round(trigorig*fsres/fsorig);
    fileOut = fopen(syncFile,'w','l');
    fprintf(fileOut,'%i \n', trig1000);
    fclose(fileOut);
    samprate=1000;
end

nyquist_freq=samprate/2; 
wo=[1 nyquist_freq*(1-.00001)]/nyquist_freq; % bandpass 1Hz to Nyquist*(1-.00001)
[b, a] = butter(2,wo);

%get common average across recorded channels
commonav=mean(cell2mat(chan),1); 
for c=1:length(chan)
    chanfile = sprintf('%s.%03i', fullfile(homeDir, subject, 'eeg.noreref',nkfilestemorig),c);
    delete(chanfile); % delete the original nk_split file        
    fchan = fopen(chanfile,'w','l');
    fwrite(fchan,filtfilt(b,a,chan{c}),'int16');
    fclose(fchan);
    % export data rereferenced to common average
    chanfile_reref = sprintf('%s.%03i', fullfile(homeDir, subject, 'eeg.reref',nkfilestemorig),c);
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
    chanfile_reref = sprintf('%s.%03i-%03i', fullfile(homeDir, subject, 'eeg.reref',nkfilestemorig),c_reref(1,c),c_reref(2,c));
    fchan_reref = fopen(chanfile_reref,'w','l');
    fwrite(fchan_reref,filtfilt(b,a,chan{c_reref(1,c)}-chan{c_reref(2,c)}),'int16');
    fclose(fchan_reref);
end

%make params.txt
paramsFile=fullfile(homeDir, subject, 'eeg.noreref','params.txt' );
fileOut = fopen(paramsFile,'w','l');
if fileOut==-1; error('params output directory is not found.'); end;
fprintf(fileOut,'samplerate %0.11f\n',samprate);
fprintf(fileOut,'dataformat ''int16''\n');
fprintf(fileOut,'gain %d\n',1);
fclose(fileOut);

