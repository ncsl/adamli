function [events] = extractFAKEeventPair(sessLogFile, subject, session)
%
% FUNCTION:
%  events=extractFAKEevents(sessLogFile, subject, session)
%
% DESCRIPTION:
%  use this to create a two-item events structure with the first and last mstime of session.log
%    helpful for testing alignment before annotation is complete
%

fprintf('\n WARNING: creating FAKE EVENTS with start and stop time from session.log\n');

[mstimes]   = textread(sessLogFile,'%n%*[^\n]');  %read all ms time from the pulse file

for iE = 1:2,
    events(iE).subject       = subject       ;
    events(iE).session       = session       ;
    events(iE).FAKE_EVENTS   = true          ;
end
events(1).mstime            = mstimes(1)    ;
events(2).mstime            = mstimes(end)  ;

