function [alignInfo,rawDevs]=logalign(beh_ms,eeg_offset,eeg_files,log_files,ms_field)
%LOGALIGN - Fit line to EEG sync and add files and offsets to logs.
%
% You provide matched EEG(offsets) and behavioral(ms) sync pulses
% and this function regresses a line for conversion from ms to eeg
% offsets.  Then it goes through each log file and appends the
% correct eeg file and offset into that file for each one.  You
% must specify a sample eeg file for each set of eeg offsets so
% that it can calculate the duration of each file.
%
% Note: The function can now append the eegfile and eegoffset to
% events structures passed in to the log_files cell array.  You
% must specify the field containing the ms data using the ms_field
% variable.
%
% Note2: ....Modification by JHW 11/2013...
%      log_files that are NOT event.mat files will be copied to logfile.align, and the
%      align version will be modified to indicate alignment offsets.
%      This differs from original implementation of this function, where log files
%      were backed up to logfile.old, and then the logfile itself was modified
%
%
% FUNCTION:
%   logalign(beh_ms,eeg_offset,eeg_files,log_files)
%
% INPUT ARGS:
%   beh_ms = {ms};   % Cell array of beh_ms vectors
%   eeg_offset = {offset}; % Cell array of eeg sync offsets
%   eeg_files = {'/data/eeg/scalp/fr/500/eeg/dat/eeg0.022'};  %
%                           % Cell array of sample files for
%                           % matching each eeg_offset.
%   log_files = {'session0.log','events.mat'};  % Cell array of log files
%                                               % to process
%   ms_field = 'mstime';   % This is the default ms_field name
%
% RETURN VARIABLES:
%   alignInfo: structure created for each eeg_offset file submitted
%            : contains info about the regresssion that can be used for
%            : quality control or reporting in the calling function  (JHW repaced "meddev" 11/2013)
%
%   rawDevs  : raw deviation values; used to compute max deviation, etc.
%

if ~exist('ms_field','var')
    ms_field = 'mstime';
end

if length(eeg_offset)>1,   %% added 11/2013... JHW... code, as is, doesn't properly handle multiple behavioral-eeg pairs (ball dropped in log file section), so spit an error to protect
    error('LOGALIGN: this version of logalign can only handel 1 pair of pulse files (1 behavioral and 1 eeg), though multiple log files can be modified based on that pair');
end

%%- pull the behavioral directory from the logfile path for error plot naming
[path, name, ext] = fileparts(log_files{1});
strTaskSess = sprintf('[%s]',path(strfind(path,'behavioral/')+11:end));


% allocate for stuph
b = zeros(2,length(eeg_offset));
eeg_start_ms = zeros(length(eeg_offset),1);
eeg_stop_ms  = zeros(length(eeg_offset),1);

strWarning = '';    %this will hold the warning messages if any are generated
strStats = ''; %this will hold a copy of the stats dumped to the screen

% loop over beh and eeg sync and get slopes
for f = 1:length(eeg_offset)
    % get slope and offset for each eeg file
    bfix = beh_ms{f}(1);
    [b(:,f),bint,r,rin,stats] = regress(eeg_offset{f}, [ones(length(beh_ms{f}),1) beh_ms{f}-bfix]);
    b(1,f) = b(1,f) - bfix*b(2,f);
    
    % calc max deviation
    act=[ones(length(beh_ms{f}),1) beh_ms{f}]*b(:,f);
    maxdev = max(abs(act - eeg_offset{f}));
    meddev{f} = median(abs(act - eeg_offset{f}));
    rawDevs{f}=act - eeg_offset{f};
    
    % calc the start and end for that file
    % make a fake event to load data fromg gete
    [path,efile,ext] = fileparts(eeg_files{f});
    fileonly{f} = efile;
    fileroot{f} = fullfile(path,efile);
    if ispc, fileroot{f}(find(fileroot{f}=='\'))='/'; end %force forward slashes as pathdelimiter on pc... makes rereferencing events.mat clean and easy
    
    chan = str2num(ext(2:end));
    event = struct('eegfile',fileroot{f});
    eeg = gete(chan,event,0);
    duration = length(eeg{1});
    
    % get start and stop in ms
    eeg_start_ms(f) = round((1 - b(1,f))/b(2,f));
    eeg_stop_ms(f)  = round((duration - b(1,f))/b(2,f));
    
    
    % save regression stats in string that is dumped at the end of the function
    %fprintf('%s:\n', eeg_files{f});
    fprintf('\tRegression Slope  = %f\n', b(2,f));
    fprintf('\tR^2               = %f\n', stats(1));
    fprintf('\tMedian Deviation  = %f ms\n', meddev{f});
    fprintf('\tMax Deviation     = %f ms\n', maxdev);
    fprintf('\tEEG duration      = %.3f minutes\n', (duration)/1000/60);
    fprintf('\tBehav Pulse range = %.3f minutes\n', range(beh_ms{f})/1000/60);
    %fprintf('\t95th pctile. = %f ms\n', prctile(rawDevs{f},95));
    %fprintf('\t99th pctile. = %f ms\n', prctile(rawDevs{f},99));
    
    
    % look for red flags and provide additional plots if helpful
    if maxdev>5,       strWarning = sprintf('%s WARNING: max deviation (%f ms) is >5 ms\n', strWarning, maxdev);    end;
    if stats(1)<0.98,  strWarning = sprintf('%s WARNING: regression R^2 (%f)   is <0.98\n', strWarning, stats(1));  end;
    if length(strWarning)>0,
        figure(100); clf
        set(gcf,'name','Alignment Regression Residuals')
        hist(rawDevs{f},100);
        xlabel('regression residuals (ms)');
        ylabel('occurances');
        [path, name, ext] = fileparts(eeg_files{f});
        strTitle = sprintf('Alignment: [%s] <--> %s',name,strTaskSess);
        strTitle(find(strTitle=='_'))='-';  %replace underscore with dash to avoid tex interpreter error
        title(strTitle,'fontsize',15)
        hold on
        plot([1 1]*-5,get(gca,'ylim'),'r--');
        plot([1 1]*5,get(gca,'ylim'),'r--');
    end
    
    %%- 11/2013 JHW created a new struct, alignInfo, that can be passed to the calling function for further analysis
    alignInfo(f).eeg_file        = eeg_files{f};
    alignInfo(f).eeg_file        = strTaskSess;
    alignInfo(f).reg_numPointFit = length(eeg_offset{f});
    alignInfo(f).reg_intercept   = b(1,f);
    alignInfo(f).reg_slope       = b(2,f);
    alignInfo(f).reg_Rsquare     = stats(1);
    alignInfo(f).reg_maxDev      = maxdev;
    alignInfo(f).reg_medianDev   = meddev{f};
    alignInfo(f).behDurationMin  = range(beh_ms{f})/1000/60;
    alignInfo(f).eegDurationMin  = duration/1000/60;
    alignInfo(f).eeg_start_ms    = eeg_start_ms(f);
    alignInfo(f).eeg_stop_ms     = eeg_stop_ms(f);
    alignInfo(f).eventMat_total  = -1; %if passed in an event.mat log file, how many entries?
    alignInfo(f).eventMat_skipped= -1; %number of entries in event.mat that were NOT within the range of the eeg
    alignInfo(f).pulseLog_total  = -1; %if passed in an eeg.eeglog(.up) log file, how many entries?
    alignInfo(f).pulseLog_skipped= -1; %number of entries in eeg.eeglog(.up) that were NOT within the range of the eeg
    
    %%- select lines for stats string that can easily be dumped to text file as record of alignment stats.
    %strStats = sprintf('%s%s:\n', strStats, eeg_files{f});
    strStats = sprintf('%s\tRegression Slope  = %f\n', strStats, b(2,f));
    strStats = sprintf('%s\tR^2               = %f\n', strStats, stats(1));
    %strStats = sprintf('%s\tMedian Deviation  = %f ms\n', strStats, meddev{f});
    strStats = sprintf('%s\tMax Deviation     = %f ms\n', strStats, maxdev);
    %strStats = sprintf('%s\tEEG duration      = %.3f minutes\n', strStats, (duration)/1000/60);
    %strStats = sprintf('%s\tBehav Pulse range = %.3f minutes\n', strStats, range(beh_ms{f})/1000/60);
    alignInfo(f).strStats = strStats;
    
end

%keyboard
% loop over log files
for f = 1:length(log_files)
    
    [path, name, ext] = fileparts(log_files{f});
    log_file_name = [name ext];
    check_file_name = log_file_name;
    
    % see if is logfile or events structure
    if strfound(log_files{f},'.mat')
        % is events struct
        dostruct = 1;
        
        events = loadEvents(log_files{f});
        
        % save a backup of the file
        try
            % this fails with the permissions setup on rhino:
            copyfile(log_files{f},[log_files{f} '.old'],'f');
        catch
            % calling unix directly works
            unix(sprintf('cp %s %s.old', log_files{f}, log_files{f}));
        end
        
        % get the ms field from the struct
        ms = getStructField(events,ms_field);
        
        %%- looks like info for multiple eeg or behav files is lost around this point (variable f doesn't loop through eeg_start_ms)... so just update alignTool's first entry
        alignInfo(1).eventMat_total   = length(ms);
        alignInfo(1).eventMat_skipped = length(ms) - length( intersect(find(ms>=eeg_start_ms),find(ms<=eeg_stop_ms)) );
        
    else
        % is a text logfile
        dostruct = 0;
        
        % load the file
        [ms,therest] = textread(log_files{f},'%n%[^\n]','delimiter','\t');
        
        % save a backup of the file
        [success, message, messageID] = copyfile(log_files{f},[log_files{f} '.align'],'f');
        if ~success, error(sprintf('LogAlign: copyfile failed on %s',log_files{f})); end   %%- JHW added this error check on 11/2013
        
        % open the new file
        %fid = fopen([log_files{f}],'w');                %%- old version... open up the original file and modify it
        fid = fopen([log_files{f} '.align'],'w');        %%- new version... open up the new copy and modify it      JHW 11/2013
        
        check_file_name = [log_file_name '.align'];
        
        %%- looks like info for multiple eeg or behav files is lost around this point (variable f doesn't loop through eeg_start_ms)... so just update alignTool's first entry
        if strfind(log_files{f},'eeg.eeglog'),
            alignInfo(1).pulseLog_total   = length(ms);
            alignInfo(1).pulseLog_skipped = length(ms) - length( intersect(find(ms>=eeg_start_ms),find(ms<=eeg_stop_ms)) );
        end
    end
    
    % check number of events that fall within range of the eeg file... save warning string if necessary
    numEventsTotal   = length(ms);
    numEventsAligned = length(intersect(find(ms>=eeg_start_ms),find(ms<=eeg_stop_ms)));
    numEventsSkipped = numEventsTotal-numEventsAligned;
    strStats = sprintf('%s\tEvents aligned    = %d of %d [%s]\n',strStats, numEventsAligned, numEventsTotal, log_file_name);
    fprintf('\tEvents aligned    = %d of %d [%s]\n',numEventsAligned, numEventsTotal, log_file_name);
    if  numEventsTotal > numEventsAligned
        strWarning = sprintf('%s WARNING: %d of %d events in %s occurred beyond duration of EEG file \t[check %s]\n', strWarning, numEventsSkipped, numEventsTotal,log_file_name, check_file_name);
    end
    
    % loop over each line
    for l = 1:length(ms)
        % figure out which eeg it's in
        ef = intersect(find(ms(l)>=eeg_start_ms),find(ms(l)<=eeg_stop_ms));
        
        if isempty(ef)
            if dostruct
                %fprintf('WARNING - Out of bounds of eeg files:\n');
                %        events(l);
                % add in a blank eegfile and offset
                events(l).eegfile = '';
                events(l).eegoffset = 0;
            else
                %fprintf('WARNING - Out of bounds of eeg files:\n\t%ld\t%s\n',ms(l),therest{l});
                
                fprintf(fid,'%s\t\t <%s> \t\t\t%s\n',num2str(ms(l),16),'not in eeg',therest{l});  % new version: just add the EEG filename to the .align logs (as a reference for alignment) JHW 11/2013
            end
            
        else
            % calc the beh_offsets
            beh_offset = round(ms(l)*b(2,ef) + b(1,ef));
            
            if dostruct
                % append the fields
                %events(l).eegfile = fileonly{ef};                                       % old version: point to noreref
                events(l).eegfile = regexprep(fileroot{ef}, 'eeg.noreref', 'eeg.reref'); % new version: point to reref---added by Zar 09/17/13
                events(l).eegoffset = beh_offset;
            else
                % write it to file
                fprintf(fid,'%s\t <%s\t%ld> \t\t%s\n',num2str(ms(l),16),fileonly{ef},beh_offset,therest{l});  % new version: just add the EEG filename to the .align logs (as a reference for alignment) JHW 11/2013
                %fprintf(fid,'%s\t%s\t%s\t%ld\n',num2str(ms(l),16),therest{l},fileroot{ef},beh_offset); % old version: add the full EEG filepath
            end
        end
    end
    
    if dostruct
        % save the new events
        saveEvents(events,log_files{f});
    else
        % close the file
        fclose(fid);
    end
end

alignInfo(1).strStats   = strStats;
alignInfo(1).strWarning = strWarning;
fprintf('\n%s', strWarning);

