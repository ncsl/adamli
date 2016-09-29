function [alignInfo] = runAlign(samplerate,beh_file,eeg_file,chan_files,log_files,ms_field,isfrei,isegi,moreAccurateAlign,forBlackrock)
%RUNALIGN - Wrapper for the pulsealign and logalign functions.
%
% This is a relatively specialized wrapper for the EEG toolbox
% alignment functions.  You provide a list of behavioral sync pulse
% files, a list of eeg sync pulse files, a list of matching eeg
% channel files, and a list of log files or files containg events
% structures to process.
%
% This function will modify the files passed into the log_files
% parameters, saving original copies.
%
% FUNCTION:
%   runAlign(samplerate,beh_file,eeg_file,chan_files,log_files,isfrei)
%
% INPUT ARGS:
%   samplerate = 500;
%   beh_file = {'behfile1','behfile2'};
%   eeg_file = {'eegfile1','eegfile2'};
%   chan_files = {'/data/eeg/file1.001','/data/eeg/file2.001'};
%   log_files = {'events.mat'};
%   ms_field = 'mstime';
%   isfrei = 0;       % Read in freiburg format
%   isegi = 0;  %data is EGI formatted
%   moreAccurateAlign = 1; %use fancy alignment script (more accurate, but
%                           slower)
%   forBlackrock = 9, 12 or 0; This is a flag that adapts this function to be used
%   for blackrock pulses. The number is the DC channel number. It's okay if empty. 
%
%
% OUTPUT ARGS:  ... added 11/2013 by JHW...
%    alignInfo: a struct created in "logalign" that contains all alignment stats
%
%

% keyboard;

if nargin < 10
    forBlackrock = 0;
end
        


if ~exist('ms_field','var')
    ms_field = 'mstime';
end

if ~exist('isfrei','var')
    isfrei = 1;
end

if ~exist('isegi','var')
    isegi = 0;
end

if ~exist('moreAccurateAlign','var')
    moreAccurateAlign = 0;
end

threshMS = 10;
window = 100;

% load in the beh_ms and the pulses
beh_ms = [];
for f = 1:length(beh_file)
    % read in free recall data
    beh_ms = [beh_ms ; textread(beh_file{f},'%n%*[^\n]','delimiter','\t')];
end

% sort it
beh_ms = sort(beh_ms);

% loop over pulses and run pulsealign to get sets of matched inputs
beh_in = cell(1,length(eeg_file));
eeg_in = cell(1,length(eeg_file));
for f = 1:length(eeg_file)
    
    % load eeg pulses
    if isfrei
        [s,pulse_str] = system(['grep -i SYNC1 ' eeg_file{f} ' | cut -d, -f 1']);
        pulses = strread(pulse_str,'%u');
    elseif isegi
        % open DIN file
        eegsyncID = fopen(eeg_file{f});
        eegsync = fread(eegsyncID, inf, 'int8');
        fclose(eegsyncID);
        pulses = find(eegsync>0);
    elseif ismac %following system call only works on mac osx
        [s,pulse_str] = system(['cut -f 1 "' eeg_file{f} '"']);
        pulses = strread(pulse_str,'%u');
    else
        pulses = load(eeg_file{f});
    end
    
    pulse_ms = pulses*1000/samplerate;
    
    % remove all pulses under 100ms (Part of Start and End pulses)
    % Only for DC09
    if forBlackrock == 0 || forBlackrock == 9
        dp = diff(pulse_ms);
        yp = find(dp < 100);
        pulse_ms(yp+1) = [];
        pulses(yp+1) = [];
    end
        
    % run pulsealign
    if length(eeg_file)>1, strFile = sprintf(' file %d,', f); else strFile = ''; end
    if ~moreAccurateAlign
        mywin = min(round(length(pulses)/2),window);
        if mywin < 5,  mywin = 5;    end
        if forBlackrock == 0
            [beh_in{f},eeg_in{f}] = pulsealign(beh_ms,pulses,samplerate,threshMS,mywin);
        elseif  forBlackrock == 9 || forBlackrock == 12
            % Need to manually put in all the vars
            threshMS = 10;
            mywin = 200;
            samplerate = 1000;
            [beh_in{f},eeg_in{f}] = pulsealign(beh_ms,pulses,samplerate,threshMS,mywin,0,0,forBlackrock);
        end
        strPulseAlign = sprintf('%s alignment method 1: %d matches of %d recorded pulses',strFile,length(beh_in{f}),length(pulses));
    else
        [beh_in2{f},eeg_in2{f}] = pulsealign2(beh_ms,pulses);
        strPulseAlign = sprintf('%s alignment method 2: %d matches of %d recorded pulses',strFile,length(beh_in2{f}),length(pulses));
    end
    disp(strPulseAlign)
    
    if forBlackrock == 0
        % run logalign with the beh_ms and eeg_offset info
        [alignInfo,err1] = logalign(beh_in,eeg_in,chan_files,log_files,ms_field);
        alignInfo.numPulses_matched  = length(beh_in{f});
        alignInfo.numPulses_recorded = length(pulses);
        alignInfo.strPulseAlign      = strPulseAlign;
        if length(beh_in{f})<window*2,
            alignInfo.strWarning = sprintf('%s WARNING: pulse window reduced from %d to %d in pulsealign (%d total pulses recorded)\n', alignInfo.strWarning, window*2, length(beh_in{f}), length(pulses) );
            fprintf(                         ' WARNING: pulse window reduced from %d to %d in pulsealign (%d total pulses recorded)\n',                      window*2, length(beh_in{f}), length(pulses) );
        end
    else
        alignInfo.beh_in = beh_in{f};
        alignInfo.eeg_in = eeg_in{f};
    end
end

