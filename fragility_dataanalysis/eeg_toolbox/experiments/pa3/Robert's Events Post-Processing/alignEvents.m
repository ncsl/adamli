function alignedEvents = alignEvents(sortedEvents)
    %This function aligns the events so that each encoding event is aligned
    %with the proper recall event
    alignedEvents = sortedEvents;
    alignedStudyPair = sortedEvents.STUDY_PAIR;
    alignedTestProbe = sortedEvents.TEST_PROBE;
    alignedStudyOrient = sortedEvents.STUDY_ORIENT;
    alignedTestOrient = sortedEvents.TEST_ORIENT;
    
    recEvents = sortedEvents.REC_EVENT;
    for e = 1:numel(recEvents)
        recEvent = recEvents(e);
        sess = recEvent.session;
        list = recEvent.list;
        serialpos = recEvent.serialpos;
        thisEv = filterStruct(sortedEvents.STUDY_PAIR,['session==' num2str(sess) '&list==' num2str(list) '&serialpos==' num2str(serialpos)]);
        alignedStudyPair(e) = thisEv;
        thisEv = filterStruct(sortedEvents.TEST_PROBE,['session==' num2str(sess) '&list==' num2str(list) '&serialpos==' num2str(serialpos)]);
        alignedTestProbe(e) = thisEv;
        thisEv = filterStruct(sortedEvents.STUDY_ORIENT,['session==' num2str(sess) '&list==' num2str(list) '&serialpos==' num2str(serialpos)]);
        alignedStudyOrient(e) = thisEv;
        thisEv = filterStruct(sortedEvents.TEST_ORIENT,['session==' num2str(sess) '&list==' num2str(list) '&serialpos==' num2str(serialpos)]);
        alignedTestOrient(e) = thisEv;
    end
    alignedEvents.STUDY_PAIR = alignedStudyPair;
    alignedEvents.TEST_PROBE = alignedTestProbe;
    alignedEvents.STUDY_ORIENT = alignedStudyOrient;
    alignedEvents.TEST_ORIENT = alignedTestOrient;
    
end