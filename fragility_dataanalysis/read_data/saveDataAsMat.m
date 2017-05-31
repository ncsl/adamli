clear all
close all
format long g

patients = {'PY04N012', 'PY11N007', 'PY11N008', 'PY11N009', 'PY11N010', ...
    'PY11N011', 'PY11N012', 'PY11N013', 'PY11N014', 'PY11N015', ...
    'PY12N005', 'PY12N008', 'PY12N010', 'PY12N012', ...
    'PY13N001', 'PY13N003', 'PY13N004', 'PY13N010', 'PY13N011', ...
    'PY14N004', 'PY14N005', 'PY15N003', 'PY15N004'};


for iPat=1:1%length(patients)
    patient = 'PY04N007';
    patient = patients{iPat};
    pos = 0;

    % root directory of source files
    rootDir = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/data/';
    rootDir = '/media/ali39/TOSHIBA EXT/';

    patDir = fullfile(rootDir, patient, 'edf2');

    metaDir = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/read_data/meta data/';
    InfoTime = load(fullfile(metaDir, 'infotime.mat'));     %- meta data for all recordings
    InfoEvent = load(fullfile(metaDir, 'infoevent.mat'));   %- meta data for all sz events
    PatTime = InfoTime.(patient);
    PatEvent = InfoEvent.(strcat('event',patient));



    [numsz, s2] = size(PatEvent.code);
    timeSz = PatEvent.time;
    timeAll = PatTime.time;

    %- load in the clinical data for this patient
    % patientmeta = clinicaldata.(patient);
    % fs = patientmeta.frequency;
    % seizure_eonset_ms = patientmeta.seizure_eonset_ms;
    % seizure_eoffset_ms = patientmeta.seizure_eoffset_ms;
    % seizure_conset_ms = patientmeta.seizure_conset_ms;
    % seizure_coffset_ms = patientmeta.seizure_coffset_ms;
    % % number_of_samples = patientmeta.recording_duration_sec * fs;
    % outcome = patientmeta.outcome;
    % engelscore = patientmeta.engelscore;
    % num_channels = patientmeta.numChans;
    engelscore = nan;
    outcome = nan;

    % loop through # of seizures there are
    for kk=1:numsz
        % set seizure start and end time
        SZstartPP(kk) = max(find(timeSz(kk,1) >= timeAll(:,1)));
        SZendPP(kk)   = min(find(timeSz(kk,2) <= timeAll(:,2)));
    end

    % extract formatting information about the iEEG data recordings
    hdr = readhdr(sprintf('%s/eeg.hdr', patDir));

    % extract the number of recording channels
    num_channels = hdr.file_fmt.Numb_chans; 

    % extract the format of the data in the *.rec file
    format_file  = hdr.file_fmt.File_format;    

    % extract the offset in the *.rec file required for the EDF header
    offset  = hdr.file_fmt.Data_offset;    

    % extract the sampling frequency (in # of samples) in the *.rec file
    Fs = hdr.file_fmt.Samp_rate;

    % extract the list of the objects
    tmp = dir(sprintf('%s',patDir, '/*.rec'));

    %- extract meta data from hdr and Info files
    elec_labels = hdr.channels.labels;
    fs = Fs;
    fileTimes = PatTime;
    szEvents = PatEvent;

    %%- save meta data
    matDir = fullfile(patDir, 'matfiles');
    if ~exist(matDir, 'dir')
        mkdir(matDir);
    end
    save(fullfile(matDir, strcat(patient, '_metadata')), 'elec_labels', 'fs', 'outcome', 'engelscore', 'fileTimes', 'szEvents');


    % run through each rec file -> convert to .mat file recording
    %- patDir
    %- filename (get inside for loop)
    %- format_file
    %- num_channels
    %- Fs
    %- offset
    %- pos
    for j=1:length(tmp)
        filename = tmp(j).name;

        % check if the file is corrupted and extract the length of the file (in
        % number of bytes)
        fid = fopen(sprintf('%s/%s',patDir,filename),'rb');
        fseek(fid,0,'eof');
        lengthfile = ftell(fid);
        if (lengthfile==-1)
            fclose(fid); clear fid
            error('Error: file not open correctly'); 
        end

    %     %--------------------------------------------------------------------------
    %     % initialize the environment variables
    %     %--------------------------------------------------------------------------
    %     % notch filter (stop frequency: 60Hz; stop-band: 4Hz)
    %     if (Fs==1000)
    % 
    %         % sampling frequency: 1000Hz). Note that the filter induces a transient
    %         % oscillation of about 400 samples which must be removed from the data
    %         dennotch = [1 -1.847737249430546 0.987291867964730];
    %         numnotch = [0.993645933982365 -1.847737249430546 0.993645933982365];
    %         Ns = 400;
    % 
    %     else if (Fs==200)
    % 
    %             % sampling frequency: 200Hz). Note that the filter induces a
    %             % transient oscillation of about 100 samples which must be removed
    %             % from the data 
    %             dennotch = [1 0.598862049930572 0.937958302720205];
    %             numnotch = [0.968979151360102 0.598862049930572 0.968979151360103];
    %             Ns = 100;
    %         else
    %             error('Error: notch filter not available');
    %         end
    %     end

    %     % open the log file
    %     fid0 = fopen(sprintf('%s/%s_log.dat',patDir,filename),'w');

        %--------------------------------------------------------------------------
        % main loop
        %--------------------------------------------------------------------------
        tic
        FileName = fullfile(patDir, tmp(j).name);
        fid  = fopen(FileName,'rb'); 
        fseek(fid,offset,'bof');
        data = fread(fid,[num_channels inf],format_file);

        varinfo = whos('data');
        saveopt='';
        if varinfo.bytes >= 2^31
            saveopt='-v7.3';
        end
        save(fullfile(matDir, strcat(patient, '_', num2str(j), '.mat')), 'data', saveopt);
        %- save the file
%         try
%             save(fullfile(matDir, strcat(patient, '_', num2str(j), '.mat')), 'data');
%         catch e
%              save(fullfile(matDir, strcat(patient, '_', num2str(j), '.mat')), 'data', '-v7.3');
%         end

        clear data

        % save the CPU time required for the computation in the log file and close
        % the log file
        t = toc
    end
end