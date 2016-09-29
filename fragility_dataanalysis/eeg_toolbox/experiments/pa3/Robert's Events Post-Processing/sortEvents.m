function sortedEvents = sortEvents(events)
    %This function sorts the events into five different categories. The
    %events are stored in a struct called sortedEvents that has the
    %following fields:
    %'STUDY_ORIENT','TEST_ORIENT','STUDY_PAIR','TEST_PROBE','REC_EVENT'
    types = {'STUDY_ORIENT','TEST_ORIENT','STUDY_PAIR','TEST_PROBE','REC_EVENT'};
    sortedEvents = struct();
    for t = types
        sortedEvents.(t{1}) = filterStruct(events,'strcmp(type,varargin{1})',t{1});
    end
end