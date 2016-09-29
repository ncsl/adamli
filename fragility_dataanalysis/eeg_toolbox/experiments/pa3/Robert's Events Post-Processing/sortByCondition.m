function eventsByCondition = sortByCondition(alignedEvents)
    %This function sorts the aligned events by condition. This function
    %returns a cell called eventsByCondition where each cell contains the
    %aligned events for a given condition
    
    %conditions = {'correct==1','intrusion~=0','pass==1','vocalization==1'};
    conditions = {'correct==1','intrusion==1','pass==1'};
    numConditions = length(conditions);
    indicators = cell(numConditions,1);
    eventsByCondition = cell(1,numConditions);
    %indsByCondition = cell(1,numConditions);
    names = fieldnames(alignedEvents); 
    for i = 1:numConditions
        eventsByCondition{i} = alignedEvents;
        indicators{i} = inStruct(alignedEvents.REC_EVENT,conditions{i});
        %indsByCondition{i} = find(indicators{i});
        for n = 1:numel(names)
            eventsByCondition{i}.(names{n}) = alignedEvents.(names{n})(indicators{i});
        end
    end
    %figure out which entries in the struct alignedEvents.REC_EVENT has an
    %empty pass field. Then use that to figure out the right relabeling of
    %passes and intrusions
    
    %keyboard
end