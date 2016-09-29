function events=extractAudLexEvents(subject,expDir,session)

experiment = 'auditoryLexicalDecision';


%                    1   2           4                                   6               8                  10                12                  14       16                          18  19
%        1405377581164	1	TRIAL	0	STIM_FILE	tactics-B-1-062-PSOLA	STIM_TYPE	1	STIM_CODE	1-062	STIM_DUR	1075	STIM_ISI	1000	KEY	2	KEY_TIME	1405377586053	0        

% expDir   = '/Users/damerasr/Sri/data/eeg/';
% sessFile = '/Users/dongj3/Desktop/session.log'

% sessFile = fullfile(expDir,subject,'behavioral',['session_' num2str(sessNum)],'session.log');
sessFile = fullfile(expDir,['session_' num2str(session)],'session.log');
%sessFile = fullfile(expDir,[subject '/session_' num2str(session)],'session.log');

fid = fopen(sessFile,'r'); %if loops check to see that sessFile exists
if fid==-1
    fprintf('session %d..no session.log file found.\n',session);
    fprintf('EXITING\n\n');
    return
else
    %disp(['The session.log file is located in: '  sessFile])
end

logfile = textscan(fid, '%s', 'delimiter', '\n');
logfile = logfile{1};

task_active = false;
skip_this_line = false;
for ii = 1:length(logfile) 
    thisLine = textscan(logfile{ii},'%s',3);
    if strcmp(thisLine{1}(3),'CUE_ON')
        task_active = true;
        skip_this_line = true;
        index = 0;
    elseif any(strcmp(thisLine{1}(3),{'CUE_OFF','E'}))
        task_active = false;
    end
    if task_active && ~skip_this_line
        index=index+1;

        thisLine = textscan(logfile{ii},'%f%f%s%f%s%s%s%f%s%s%s%f%s%f%s%s%s%f%f');

        events(index).subject                 = subject;
        events(index).experiment              = experiment;
        events(index).session                 = session;
        
        events(index).mstime                  = thisLine{1};
        events(index).event_onset_error       = thisLine{2};
        events(index).stim_event_number       = thisLine{4};
        events(index).stim_file               = thisLine{6}{1};
        events(index).stim_type               = thisLine{8};
        events(index).stim_code               = thisLine{10}{1};
        events(index).stim_duration           = thisLine{12};
        events(index).isi                     = thisLine{14}; % value does not include jitter, only min coded ISI value
        events(index).response_key            = thisLine{16}{1};
        events(index).response_key_time       = thisLine{18};
        events(index).response_key_time_error = thisLine{19};
        events(index).eventType               = 'w';        
    end
    skip_this_line = false;
end
fclose(fid);

root = which('extractAudLexEvents');
root = root(1:end-length('extractAudLexEvents.m'));
load([root '/segmentations.mat']);
for ii = 1:length(events)
    match = strcmp(events(ii).stim_code,stim_codes);
    if sum(match)==1 && ~isempty(onsets{match})
        ons = onsets{match};
        durs = durations{match};
        trans = transcripts{match};
        for jj = 1:length(ons)
            if ~strcmp(trans{jj},'h#')
                index=index+1;

                events(index).subject                 = subject;
                events(index).experiment              = experiment;
                events(index).session                 = session;

                events(index).mstime                  = events(ii).mstime+ons(jj);
                events(index).event_onset_error       = events(ii).event_onset_error;
                events(index).stim_event_number       = events(ii).stim_event_number+jj*1000;
                events(index).stim_file               = events(ii).stim_file;
                events(index).stim_type               = events(ii).stim_type;
                events(index).stim_code               = events(ii).stim_code;
                events(index).stim_duration           = durs(jj);
                events(index).segment                 = trans{jj};
                events(index).eventType               = 's';        
            end
        end
    else
        if ~sum(match)==1
            warning(['Match not found, very sad :.( Item ' events(ii).stim_code]);
        end
    end
end
return;
