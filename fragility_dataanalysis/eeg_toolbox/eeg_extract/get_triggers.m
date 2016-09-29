function [events,triggers]=get_triggers(trig,rate)
%This function was written by John Britton of Oxford university to decode his binary script
%encoding for the flanker task.  
% Zar Zavala modified it to extract the Blackrock analogue pulses. 
% Though I only plan on using it to extract single pulses, it can be used
% to extract pulses from several channels and use those channels to decode
% an binary signal carried by the channels. For example a pulse  

%function [events,triggers]=get_triggers(trig,rate)
%
% Input parameters
%	trig	analogue trace of continuous triggers
%	rate	Sampling rate
%
%function [events,triggers]=get_triggers(trig,rate)
% Preprocess (nb: some channels may have no events)

M=size(trig,2);                 % Trigger channels
trig=trig-min(trig(:));
trig=trig/max(trig(:));
trig1=zeros(size(trig));
% keyboard
trig1(trig>.23)=1;
% trig1(trig==0)=1;  % In case the trigger saturates and goes to zero
trig=trig1;

trig=diff(trig,[],1);			% Differentiate trig channels
trig=trig/max(trig(:));			% Normalise trigger diffs
% Isolate low-high transitions
for ind=(1:M)
    trans{ind}=find(trig(:,ind)>0.5);
    repeats=find(diff(trans{ind})<100); % in case the full pulse is recorded as two pulses.
    trans{ind}(repeats+1)=[];
end;
% Construct trigger channel (permitting 5msec error between channels)
triggers=zeros(size(trig,1),1);
triggers(trans{1})=1;
% Add trigger lines (summate if pulse exists within 5ms)
for ch=(2:M)
    bit=2^(ch-1);
    triglist=find(triggers);
    for ind=(1:length(trans{ch}))
	index=find(abs(triglist-trans{ch}(ind))<=(0.005*rate));
	if (~isempty(index))
	    triggers(triglist(index))=triggers(triglist(index))+bit;
	else
	    triggers(trans{ch}(ind))=bit;
	end;
    end;
end;

% Generate events structure
for ind=(1:((2^M)-1))
    events{ind}=find(triggers==ind);
end;
