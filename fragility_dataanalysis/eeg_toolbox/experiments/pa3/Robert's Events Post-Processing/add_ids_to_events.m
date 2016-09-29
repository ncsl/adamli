function events = add_ids_to_events(alignedEvents)
    for name = fieldnames(alignedEvents)'
        ev = alignedEvents.(name{1});
        for e = 1:numel(ev)
            thisEvent = ev(e);
            sess = thisEvent.session;
            list = thisEvent.list;
            spos = thisEvent.serialpos;
            alignedEvents.(name{1})(e).id = ['id' dec2base(sess,10,3) dec2base(list,10,3) dec2base(spos,10,3)];
        end
    end
    events = alignedEvents;
end