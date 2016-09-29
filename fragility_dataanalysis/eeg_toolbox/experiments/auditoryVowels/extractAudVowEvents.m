function events=extractAudVowEvents(subj,behDir,sessNum)

experiment = 'auditoryVowels';

% behDir   = '/Users/damerasr/Sri/data/eeg/';
% sessFile = '/Users/dongj3/Desktop/session.log'

% sessFile = fullfile(behDir,subj,'behavioral',['session_' num2str(sessNum)],'session.log');
sessFile = fullfile(behDir,['session_' num2str(sessNum)],'session.log');
%sessFile = fullfile(behDir,[subj '/session_' num2str(sessNum)],'sessNum.log');

keyFile = fullfile(behDir,['session_' num2str(sessNum)],'keyboard.keylog');
%keyFile = fullfile(behDir,[subj '/session_' num2str(sessNum)],'keyboard.keylog');


fid = fopen(sessFile,'r'); %if loops check to see that sessFile exists
if fid==-1
    fprintf('session %d..no session.log file found.\n',sessNum);
    fprintf('EXITING\n\n');
    return
end

logfile = textscan(fid, '%s', 'delimiter', '\n');
logfile = logfile{1};

%             1     2       3   4           5       6           7   8           9  10         11     12       13    14
% 1405377699675     1	TRIAL	0	STIM_FILE	1-1-1	STIM_TYPE	1	STIM_CODE	1	STIM_DUR	136	STIM_ISI	40	

task_active = false;
skip_this_line = false;
for ii = 1:length(logfile) 
    thisLine = textscan(logfile{ii},'%f%f%s',1);
    if strcmp(thisLine{3},'CUE_ON')
        task_active = true;
        skip_this_line = true;
        index = 0;
        start = thisLine{1};
    elseif any(strcmp(thisLine{3},{'CUE_OFF','E'}))
        task_active = false;
        stop = thisLine{1};
    end
    if task_active && ~skip_this_line
        index=index+1;

        thisLine = textscan(logfile{ii},'%f%f%s%f%s%s%s%f%s%f%s%f%s%f');

        events(index).subj                 = subj;
        events(index).experiment              = experiment;
        events(index).session                 = sessNum;
        
        events(index).eventType               = 's';
        events(index).mstime                  = thisLine{1};
        events(index).stim_event_onset_error  = thisLine{2};
        events(index).stim_event_number       = thisLine{4};
        events(index).stim_file               = thisLine{6}{1};
        events(index).stim_type               = thisLine{8};
        events(index).stim_code               = thisLine{10};
        events(index).stim_duration           = thisLine{12};
        events(index).isi                     = thisLine{14}; % value does not include jitter, only min coded ISI value
    end
    skip_this_line = false;
end
fclose(fid);

fid = fopen(keyFile,'r'); %if loops check to see that sessFile exists
if fid==-1
    fprintf('session %d..no keyboard.keylog file found.\n',sessNum);
    fprintf('EXITING\n\n');
    return
end

logfile = textscan(fid, '%s', 'delimiter', '\n');
logfile = logfile{1};

%             1 2   3                4
% 1405377652655	0	B	Logging Begins
% 1405377664828	0	P	SPACE
% 1405377664828	55	R	SPACE
% 1405377673745	0	P	SPACE
% 1405377673817	0	R	SPACE
% 1405377705423	0	P	F1
% 1405377705511	0	P	ESCAPE
% 1405377648895	0	E	Logging Ends


nr=0;
for ii = 1:length(logfile) 
    thisLine = textscan(logfile{ii},'%f%f%s%s','delimiter', '\t');
    if strcmp(thisLine{4},'SPACE') && thisLine{1} > start && thisLine{1} < stop
        if strcmp(thisLine{3},'P')         

            nr = nr + 1;
            index = index + 1;

            events(index).subj                   = subj;
            events(index).experiment                = experiment;
            events(index).session                   = sessNum;

            events(index).eventType                 = 'r';
            events(index).mstime                    = thisLine{1};
            events(index).response_event_number     = nr;

        else  
            if events(index).mstime == thisLine{1}
                events(index).response_event_offset = events(index).mstime + thisLine{2};
            else
                events(index).response_event_offset = thisLine{1};
            end
        end
    end
end
fclose(fid);

return;
