function EEG=gete2(channel,events,duration,offset,buffer,filtfreq,filttype,filtorder,resampledrate)
%GETE - Get EEG event data.
% 
% Returns data from an eeg file.  User specifies the channel,
% duration, and offset along with an event.  The event struct MUST
% contain both 'eegfile' and 'eegoffset' members.
%
% If the duration is set to 0, then it will return a cell array of
% the entire data from each unique file in the events structure.
% It will ignore the offset and buffer variables.
%
% FUNCTION:
%   EEG=gete(channel,events,duration,offset,buffer,filtfreq,filttype,filtorder,resampledrate)
%
% INPUT ARGS:
%   channel = 3;            % the electrode #
%   events = events(8:12);  % event struct to extract [eegfile eegoffset]
%   duration = 512;         % signal time length in samples (of the
%                           % original duration of the data)
%   offset = 0;             % offset at which to start in samples
%                           % (in units of the original data)
%   buffer = 256;           % buffer (needed for filtering)
%                           %   default is 0
%   filtfreq = [59.5 60.5]; % Filter freq (depends on type, see buttfilt)
%                           %   default is []
%   filttype = 'stop';      % Filter type (see buttfilt)
%   filtorder = 1;          % Filter order (see buttfilt)
%   resampledrate = 256     % (optinal) - resampled the data
%
% OUTPUT ARGS:
%   EEG - The data from the file
%

% 2010/9/28 - JRM: support changing sample rate across sessions
% 2010/7/2 - JRM: return nans if event offset is past the end of the file
% 2006/8/4 - MvV: fixed bug in case of fractionated durations
% 2006/1/20 - MvV: added in resampling, similar to gete_ms.m
% 2004/3/5 - PBS: Now reads in entire unique file if duration is 0
% 2003/12/9 - PBS: Added which event number to read warning

% check the arg
if nargin < 9
    resampledrate = [];
    if nargin < 8
        filtorder = 1;
        if nargin < 7
            filttype = 'stop';
            if nargin < 6
                filtfreq = [];
                if nargin < 5
                    buffer = 0;
                    if nargin<4 
                        offset=0; 
                    end
                end
            end
        end
    end
end



% see if getting for each event or all unique files
if duration == 0
    % getting for all unique files
    uFiles = unique(getStructField(events,'eegfile',''));
    if isempty(uFiles{1})
        uFiles = uFiles(2:end);
    end
    EEG = cell(1,length(uFiles));

    % loop over files
    for f = 1:length(uFiles)
        %update the sampling rate as needed
        [samplerate,~,dataformat,gain] = GetRateAndFormat(uFiles{f});
        samplerate = round(samplerate);

        if isempty(resampledrate)
            resampledrate = samplerate;
        end
        resampledrate = round(resampledrate);
        

        % set the channel filename
        eegfname=sprintf('%s.%03i',uFiles{f},channel);

        eegfile=fopen(eegfname,'r','l'); % NOTE: the 'l' means that it came from a PC!
        if(eegfile==-1)
            eegfname=sprintf('%s%03i',uFiles{f},channel); % now try unpadded lead#
            eegfile=fopen(eegfname,'r','l');
        end
        if(eegfile==-1)
            eegfname=sprintf('%s.%i',uFiles{f},channel); % now try unpadded lead#
            eegfile=fopen(eegfname,'r','l');
        end

        % tell if not open
        if eegfile==-1
            % did not open
            error('ERROR: EEG File not found: %s.\n',eegfname);
        end

        % read the entire file, then close it
        EEG{f} = fread(eegfile,inf,dataformat)';        
        fclose(eegfile);

        % filter the data if needed
        if ~isempty(filtfreq)
            EEG{f} = buttfilt(EEG{f},filtfreq,samplerate,filttype,filtorder);
        end

        % resample if needed
        if resampledrate ~= samplerate            
            EEG{f} = resample(EEG{f},round(resampledrate),round(samplerate));          
        end	

        % apply the gain
        EEG{f} = EEG{f}.*gain;
    end  
else % getting for each event  
    if isfield(events(1),'session')
        SESSION_FIELD = 1;
        sessions = unique([events.session]);
    else
        SESSION_FIELD = 0;
    end
    for s = 1:length(sessions)
        if SESSION_FIELD
            [session_events,session_inds] = filterStruct(events,sprintf('session == %d',sessions(s)));
        else
            session_events = events;
            session_inds = true(size(events));
        end
        [samplerate,nBytes,dataformat,gain] = GetRateAndFormat(session_events(1));
        samplerate = round(samplerate);
        %if resampledRate is not specified, always re-sample to the first
        %session's sampling rate to ensure the same number of samples for all
        %events, across sessions
        if ~exist('EEG','var')
            if isempty(resampledrate)
                resampledrate = samplerate;
            else
                resampledrate = round(resampledrate);
            end

            % base final datasize on resampled data
            final_duration = fix(duration*resampledrate/samplerate);
            final_buffer = fix(buffer*resampledrate/samplerate);

            % allocate space for EEG data
            EEG = zeros(length(events),final_duration);
        end
        
        next_EEG = zeros(length(session_events),final_duration);
        for e = 1:length(session_events)            
            % set the channel filename
            eegfname = sprintf('%s.%03i',session_events(e).eegfile,channel);
            eegfile = fopen(eegfname,'r','l'); % NOTE: the 'l' means that it came from a PC!
            
            if eegfile == -1
                eegfname = sprintf('%s.%i',session_events(e).eegfile,channel); % now try unpadded lead
                eegfile = fopen(eegfname,'r','l');
            end

            % if the file still can't be opened, throw an error
            if eegfile == -1                
                error('ERROR: Missing EEG File for session %d, event %d: %s.\n',session(s),e,session_events(e).eegfile);
            end

            % read the eeg data and close the file
            thetime = offset + session_events(e).eegoffset - buffer;
            status = fseek(eegfile,nBytes*thetime,-1);    
            if status == 0
                readbytes = fread(eegfile,duration+(2*buffer),dataformat)';
            elseif status == -1
                warning('EEGTOOLBOX:GETE:NODATA','%s: eeg data for session %d, event %d were not found',eegfname,sessions(s),e);
                readbytes = nan(1,duration + (2*buffer));
            end
            fclose(eegfile);            

            % filter data if needed
            if ~isempty(filtfreq)
                readbytes = buttfilt(readbytes,filtfreq,samplerate,filttype,filtorder);
            end
            
            % warn about append nans if needed
            if length(readbytes) ~= fix(duration + 2*buffer)
                warning('EEGTOOLBOX:GETE:INCOMPLETEDATA','%s: only %d of %d samples read for session %d, event %d -- appending nans',eegfname,length(readbytes),size(EEG,2),sessions(s),e);
            end
            
            % resample data if needed
            if resampledrate ~= samplerate                
                readbytes = resample(readbytes,round(resampledrate),round(samplerate));
            end
            
            % now actually append nans (if done before filtering, the
            % filter will return all nans.)
            readbytes = [readbytes nan(1,size(next_EEG,2)+(2*final_buffer)+1-length(readbytes))]; %#ok<AGROW>
            next_EEG(e,:) = readbytes(final_buffer+1:end-final_buffer-1).*gain;
        end
        
        EEG(session_inds,:) = next_EEG;
    end  
end




