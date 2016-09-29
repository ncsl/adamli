function [events] = createStimEvents_v1a(sessLogFile, subject, sessionName, sessionNum)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  Function for extracting behavioral data from stimMapping session. %%%%
%%%%
%%%%    how to use this code:
%%%%     1) use eegStimPrep to create trigUpDown and annotation files... 
%%%%     2) create behavioral/stimMapping/session_X folder, copy updown file there
%%%%     3) rename behavioral updown file with stim on/off pulses "session.log"
%%%%     4) hand-edit session.log file so annotations occur within pulse (or before?), change ANNOTATION to ELECTRODES where applicable 
%%%%         (Cocjin's annotations (>=NIH024) easy to tweak... do find/replace  "ANNOTATE 	 i" --> "STIM_LEVEL     ",   "ANNOTATE    c" --> "ELECTRODES     "
%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%- uncomment following lines to directly run script
% clear all
% 
% rootEEGdir  = '/Users/wittigj/DataJW/AnalysisStuff/dataLocal/eeg';
% subject     = 'NIH022stim';   % EEG002  NIH016
% sessionName = 'session_0'; sessionNum = 0;
% 
% sessionDir  = fullfileEEG(rootEEGdir,subject,'behavioral/stimMapping',sessionName);
% sessLogFile = fullfileEEG(sessionDir,'session.log');
% eventFile   = fullfileEEG(sessionDir,'events.mat');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



fid = fopen(sessLogFile,'r'); %if loops check to see that sessFile exists
if (fid==-1)
    
    fprintf('\n\n ********** Session.log not found: %s  **********', sessLogFile); 
    
    dc10file = dir( fullfileEEG(fileparts(sessLogFile),'*.trigDC10.updown.txt') );
    if isempty(dc10file)
        fprintf('\n And no trigDC10.updown.txt file available to create one! Rerun eegStimPrep or create session.log from another trigDC file.\n Exiting\n\n');
        events = [];
        return ;
    end
    
    
    %- create session.log by copying the contents of trigDC10.  If John C was annotating, the file will be automatically modified to facilitiate extraction
    fin  = fopen(fullfileEEG(fileparts(sessLogFile),dc10file.name),'r'); %if loops check to see that sessFile exists
    fout = fopen(sessLogFile,'w+');
    modFile=0;
    while ~feof(fin)
        s = fgetl(fin);
        sMod = strrep(s, 'ANNOTATE 	 c', 'ELECTRODES     ');  if ~strcmp(s,sMod), s=sMod; modFile=modFile+1; end
        sMod = strrep(s, 'ANNOTATE 	 i', 'STIM_LEVEL     ');  if ~strcmp(s,sMod), s=sMod; modFile=modFile+1; end
        sMod = strrep(s, 'ANNOTATE 	 b', 'BEHAVIORAL     ');  if ~strcmp(s,sMod), s=sMod; modFile=modFile+1; end
        fprintf(fout,'%s\n',s);
        %disp(s)
    end
    fclose(fin);
    fclose(fout);
    
    fprintf('\n  session.log created from a copy of %s; \n %d modifications made based on John Cs annotation style \n ',dc10file.name, modFile);
    if modFile==0,
        fprintf('\n  *** Zero automatic modifications were made: must do it by hand ***');
        fprintf('\n  *** Open new session.log and hand-edit so annotations occur within (or before?) pulses. ***');
        fprintf('\n  *** if subject>= NIH024, do find/replace:\n   "ANNOTATE 	 i" --> "STIM_LEVEL     "\n   "ANNOTATE 	 c" --> "ELECTRODES     "\n   "ANNOTATE     b" --> "BEHAVIORAL     "');
        fprintf('\n  *** paused in createStimEvents... edit file and continue to run for first pass extraction.\n\n');
        fclose('all');
        keyboard;
    end
    
    fid = fopen(sessLogFile,'r'); %- open the newly minted session.log file and attempt to process it below
    
end




%-initialize variables
serverDataPath = '/Volumes/Shares/FRNU/data/eeg/';      %- always point eegfile to this location
experiment    = 'stimMapping';
subject       = subject   ;
sessionName   = sessionName ;
sessionNum    = sessionNum ;
pulseFilename = '?';

%-params that vary
type          = '';
mstime        = -1;
eegfile       = '';

%-pulse params
isPulseEvent  = -1;
pulseStartTime = -1;
pulseStopTime  = -1;
pulseDuration  = -1;
electrodePair = '?';
stimulusLevel = '?';
stimResponse  = '';
annotation    = '';

%- 
inPulse       = 0;




%- Read session.log line-by-line and convert to events structure
events      = struct([]);
index       = 0;
while true
    thisLine            = fgetl(fid);
    if ~ischar(thisLine); break; end
    
    
    %- Generic text scan to get time, offset, and type
    [xTOT, pos]         = textscan(thisLine,'%d %s',1);
    mstime              = xTOT{1}(1);   %- must add (1) because numbers after the string in the above line cause overflow to first %f
    type                = xTOT{2}{1};
    info                = strtrim(thisLine(pos+1:end)); %trim leading/trailing spaces
    info                = info(find(info));             %trim empty (null) entries from end
    
    %-
    isPulseEvent        = 0; %-set to 0 every iteration... only PULSE_LO will set high (and increment index so event is created)
    isChannelChange     = 0; %-set to 0 every iteration... only PULSE_LO will set high (and increment index so event is created)

    %- default Parameters (details will be filled out/altered based on type)    
    switch type
        case 'FILENAME'
            pulseFilename  = info;
            
        case 'EEGSTEM'
            eegfile        = fullfileEEG(serverDataPath,subject,'eeg.reref',info);
            type  = 'SESS_START' ; 
            index = index+1;        %-create session start event once the eegfile is logged            
            
        case 'PULSE_HI'
            if inPulse==1, fprintf('ERROR: pulse up, but was already up'); keyboard; end
            inPulse = 1;
            pulseStartTime = mstime;
            pulseStopTime  = -1;
            stimResponse   = '';    %-reset this param at begining of pulse
            annotation     = '';
            
        case 'PULSE_LO'
            if inPulse==0, fprintf('ERROR: pulse down, but wasnt regsitered as being up'); keyboard; end
            inPulse = 0;
            pulseStopTime  = mstime;
            isPulseEvent   = 1;
            index = index+1;        %-pulse complete... create info that has all its info... after all events created will double events to create ups and down
         
        case 'ELECTRODES'
            electrodePair = info;
            annotation    = info;
            isChannelChange = 1;
            index = index+1;
        
        case 'STIM_LEVEL'
            stimulusLevel = info;
            annotation    = info;
            
        case 'STIM_RESPONSE'
            stimResponse  = info;
            annotation    = info;
            
        case 'BEHAVIORAL'
            stimResponse  = info;
            annotation    = info;
            
        case 'ANNOTATE'
            %- user should replace ANNOTATION with ELECTRODES, STIM_LEVEL, RESPONSE... or make it automated here?
            annotation    = info;
            if inPulse==0, index=index+1; fprintf('Warning: annotation at %d not within stim pulse: "%s" \n', mstime, annotation); end
        
        case 'SESS_END'
            %- user should replace ANNOTATION with ELECTRODES, STIM_LEVEL, RESPONSE... or make it automated here?
            index=index+1; 
        
        otherwise
            fprintf('WARNING: %s not expected type\n',type);

    end
    
    
    %- asign values to events array
    if index>length(events),
        
        clear thisEvent
        %-params that are fixed for the session
        thisEvent.experiment        = experiment  ;
        thisEvent.subject           = subject     ;
        thisEvent.sessionName       = sessionName ;
        thisEvent.sessionNum        = sessionNum  ;
        thisEvent.pulseFilename     = pulseFilename ;
        
        %-params that vary
        thisEvent.type              = type        ;
        thisEvent.mstime            = mstime      ;
        thisEvent.msduration        = nan         ;
        thisEvent.eegoffset         = mstime      ;
        thisEvent.eegfile           = eegfile     ;
        
        %-pulse params
        thisEvent.isPulseEvent      = isPulseEvent  ; %0-no, 1=stim start, 2=stim stop
        thisEvent.pulseStartTime    = pulseStartTime;
        thisEvent.pulseStopTime     = pulseStopTime ;
        thisEvent.pulseDuration     = pulseStopTime-pulseStartTime;
        thisEvent.isChannelChange   = isChannelChange;
        thisEvent.electrodePair     = electrodePair ;
        thisEvent.stimulusLevel     = stimulusLevel ;
        thisEvent.stimResponse      = stimResponse  ;
        thisEvent.annotation        = annotation    ;
        
        
        %-save to events structure array
        if (index==1)
            events        = thisEvent; %- before events defined must convert to structure
        else
            events(index) = thisEvent;
        end
        
        
        %-make stim start and stim stop events
        if isPulseEvent,
            thisEvent.type          = 'PULSE_LO';
            thisEvent.isPulseEvent  = 1;
            thisEvent.mstime        = pulseStartTime;
            thisEvent.msduration    = pulseStopTime-pulseStartTime;
            thisEvent.eegoffset     = pulseStartTime;
            events(index)           = thisEvent;
            
            thisEvent.type          = 'PULSE_HI';
            thisEvent.isPulseEvent  = 2;
            thisEvent.mstime        = pulseStopTime;
            thisEvent.msduration    = pulseStopTime-pulseStartTime;
            thisEvent.eegoffset     = pulseStopTime;
            index=index+1;
            events(index)           = thisEvent;
        end
    end
   
end
fclose(fid);  % close session.log


%%- now cleanup event timing... session
iChanChange  =  find( [events.isChannelChange]==1 );
for ii=1:length(iChanChange)-1,
    events(iChanChange(ii)).msduration     =  events(iChanChange(ii+1)).mstime - events(iChanChange(ii)).mstime;
    events(iChanChange(ii)).pulseStartTime =  nan;
    events(iChanChange(ii)).pulseStopTime  =  nan;
    events(iChanChange(ii)).pulseDuration  =  nan;
end
events(iChanChange(end)).msduration     =  events(end).mstime - events(iChanChange(end)).mstime;
events(iChanChange(end)).pulseStartTime =  nan;
events(iChanChange(end)).pulseStopTime  =  nan;
events(iChanChange(end)).pulseDuration  =  nan;


%%- SESS_START duration should equal entire eeg timeseries
events(1).msduration = events(end).mstime;


%%- only should be executed when running as script (not as function)
if exist('eventFile','var'),
    fprintf('running jwAttnTaskEvents directly: \n --> extracted %d events to %s\n', length(events), sessionDir);
    save(eventFile,'events');
end
