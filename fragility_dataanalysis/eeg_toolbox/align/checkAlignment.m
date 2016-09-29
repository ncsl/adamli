function checkAlignment(sessionDir, syncFile)
% This function checks to see whether or not the alignment is correct by
% plotting visualizations of behavioral and electrophysio pulse systems side
% by side, from the "time" of first event to the last event, and for the
% beginning and end of the experiment session.
%
%METHOD: Obtains the EEG pulses from the sync file, obtains the behavioral
%pulses from the eeg.eeglog.up file, and plot them for the same times span of the
%experiment

% INPUT:
% sessionDir = '/Users/dongj3/Jian/data/eeg/NIH001/behavioral/pa3/session_0';
% syncFile = '/Users/dongj3/Jian/data/eeg/NIH001/eeg.noreref/NIH001_121211_1655.045.new.sync.txt';
% 
% 
% 



%check to see if inputs are valid:
if ~exist(sessionDir,'dir'); disp(['Bad session directory: ' sessionDir]); return; end;
if ~exist(syncFile,'file'); disp(['Sync file does not exist: ' syncFile]); return; end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Load behavioral pulse data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fid = fopen([sessionDir '/eeg.eeglog.up']);
if fid==0; disp('No eeg.eeglog.up file found.'); return; end;
eegLogFile = textscan(fid,'%f %s %s'); %eegLogFile{1} contains the mstime when pulses are sent
fclose(fid);
events = load([sessionDir '/events.mat']);
events = events.events;
behSampleSpan = events(1).mstime:events(end).mstime; %contains the span of mstime of the entire experiment. aka X axis.
behPulse = zeros([1,length(behSampleSpan)]); %will contain the value at each mstime of the experiment. 1=pulse, 0=no pulse.
[Value,Value1,behPulseIndex] = intersect(eegLogFile{1},behSampleSpan); % finds the similar values.
clear Value Value1 % you don't need the actual values or the index of the similar values on eegLogFile{1}
behPulse(behPulseIndex) = 1; %for all the pulses in the span of mstime, turn it into 1. This is the Y axis.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%load EEG Pulse Data, and do the same thing.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
eegSampleSpan = events(1).eegoffset:events(end).eegoffset; %will store all the sample numbers relevant to entire experiment. This is the X axis.
eegPulse = zeros([1,length(eegSampleSpan)]);
eegSyncSamples = load(syncFile);
[Value,Value1,eegSpanIndex] = intersect(eegSyncSamples,eegSampleSpan); % finds the similar values.
clear Value Value1
eegPulse(eegSpanIndex)=1;
%get sample rate
% samplerate = GetRateAndFormat(fileparts(syncFile)) %looks in params.txt
% for the sample rate
% ratio=samplerate/1000; %the ratio will include how many eeg data points to plot relative to behavioral data points
ratio = length(eegSampleSpan)/length(behSampleSpan);

%%%%%%%%%
%Plotting
%%%%%%%%%
%plot the whole experiment and the pulses that are aligned
keyboard
figure(1); 
subplot(2,1,1); plot(behSampleSpan,behPulse);
xlim([behSampleSpan(round(17/20*length(behSampleSpan))) behSampleSpan(round(18/20*length(behSampleSpan)))]); title('Behavioral pulse')
subplot(2,1,2); plot(eegSampleSpan,eegPulse);
xlim([eegSampleSpan(round(17/20*length(eegSampleSpan))) eegSampleSpan(round(18/20*length(eegSampleSpan)))]); title('EEG pulse')

%plot the first couple of pulses close up to make sure alignment is correct
figure(2)
subplot(2,1,1); plot(behSampleSpan,behPulse);
xlim([behSampleSpan(1) behSampleSpan(40000)]); title('Behavioral pulse beginning')
subplot(2,1,2); plot(eegSampleSpan,eegPulse);
xlim([eegSampleSpan(1) eegSampleSpan(round(40000*ratio))]); title('EEG pulse beginning')

%plot the last couple of pulses close up to make sure alignment is correct
figure(3)
subplot(2,1,1); plot(behSampleSpan,behPulse);
xlim([behSampleSpan(end-7000) behSampleSpan(end)]); title('Behavioral pulse end')
subplot(2,1,2); plot(eegSampleSpan,eegPulse);
xlim([eegSampleSpan(round(end-7000*ratio)) eegSampleSpan(end)]); title('EEG pulse end')
