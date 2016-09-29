function prunedEvents = pruneEvents(alignedEvents,evIds)
    recEvents = alignedEvents.REC_EVENT;
    num_events = numel(recEvents);
    evs_to_use = false(num_events,1);
    for id = evIds
        ev_inds = find(inStruct(recEvents,'strcmp(id,varargin{1})',id{1}));
        event_to_use = [];
        for ind = ev_inds
            event = recEvents(ind);
            %Find if any of the matching events are a correct,
            %intrusion, or pass
            %If intrusion, check if the resp_word is the same as the
            %cue word. If there is no correct, intrusion, or pass,
            %mark the trial as a pass
            if event.correct==1
                event_to_use = ind;
                alignedEvents.REC_EVENT(ind).pass = 0;
                alignedEvents.REC_EVENT(ind).intrusion = 0;
            elseif ~strcmp(event.resp_word,'PASS') && ~strcmp(event.resp_word,'') && ~strcmp(event.resp_word,'<>') && isempty(event_to_use)
                if ~strcmp(event.probe_word,event.resp_word)
                    event_to_use = ind;
                    alignedEvents.REC_EVENT(ind).pass = 0;
                    alignedEvents.REC_EVENT(ind).intrusion = 1;
                end
            elseif isfield(event,'pass')
                if event.pass==1
                    event_to_use = ind;
                    alignedEvents.REC_EVENT(ind).intrusion = 0;
                end
            end
        end
        if isempty(event_to_use)
            %keyboard
            event_to_use = ind;
            alignedEvents.REC_EVENT(ind).pass = 1;
            alignedEvents.REC_EVENT(ind).intrusion = 0;
        end
        if alignedEvents.REC_EVENT(event_to_use).pass==1
            if ~strcmp(alignedEvents.REC_EVENT(event_to_use).resp_word,'PASS')
                alignedEvents.REC_EVENT(event_to_use).RT = nan;
            end
        end
        if alignedEvents.REC_EVENT(event_to_use).RT==0
            alignedEvents.REC_EVENT(event_to_use).RT = nan;
        end
        if evs_to_use(event_to_use)
            keyboard
        end
        evs_to_use(event_to_use) = true;
    end
    prunedEvents = alignedEvents;
    for name = fieldnames(alignedEvents)'
        prunedEvents.(name{1}) = prunedEvents.(name{1})(evs_to_use);
    end
end