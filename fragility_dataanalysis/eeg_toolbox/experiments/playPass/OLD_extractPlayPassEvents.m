function events=extractPlayPassEvents(subject,expDir,session)


% expDir   = '/Users/damerasr/Sri/data/eeg/';
% sessFile = '/Users/dongj3/Desktop/session.log'

% sessFile = fullfile(expDir,subject,'behavioral',['session_' num2str(sessNum)],'session.log');
sessFile = fullfile(expDir,['session_' num2str(session)],'session.log');

fid = fopen(sessFile,'r'); %if loops check to see that sessFile exists
if fid==-1
    fprintf('session %d..no session.log file found.\n',session);
    fprintf('EXITING\n\n');
    return
else
    %disp(['The session.log file is located in: '  sessFile])
end

index = 1;
while true
    thisLine = fgetl(fid);
    if ~ischar(thisLine);return;end
    % get the third string before the underscore
    xTOT=textscan(thisLine,'%f%d%s');
    
    mstime              = xTOT{1}(1);   %- must add (1) because numbers after the string in the above line cause overflow to first %f
    msoffset            = xTOT{2}(1);
    type                = xTOT{3}{1};
    
    
    switch type
        
        case 'B'
            xTOT=textscan(thisLine,'%f%d%s%d');
            events(index).experiment = 'playpass';
            events(index).subject = subject;
            events(index).session = session;
            events(index).msoffset = msoffset;
            events(index).mstime = mstime;
            events(index).type = xTOT{3}{1};
            events(index).img1file = -9999;
            events(index).img2file = -9999;
            events(index).img3file = -9999;
            events(index).img4file = -9999;
            events(index).inputvaluesrow = -9999;
            events(index).suit = '';
            events(index).rewardtype = -9999;
            events(index).rewardvalue = -9999;
            events(index).delaytype = -9999;
            events(index).delayvalue = -9999;
            events(index).choice = '';
            events(index).totalreward = -9999;
%             events(index).reactiontime = -9999;
            index=index+1;
            
        case 'Img1'
            xTOT=textscan(thisLine,'%f%d%s%d%s%d%s%d%s%d%s%d');
            events(index).experiment = 'playpass';
            events(index).subject = subject;
            events(index).session = session;
            events(index).msoffset = msoffset;
            events(index).mstime = mstime;
            events(index).type = xTOT{3}{1};
            events(index).img1file = xTOT{4};
            events(index).img2file = xTOT{6};
            events(index).img3file = xTOT{8};
            events(index).img4file = xTOT{10};
            events(index).inputvaluesrow = xTOT{12};
            events(index).suit = '';
            events(index).rewardtype = -9999;
            events(index).rewardvalue = -9999;
            events(index).delaytype = -9999;
            events(index).delayvalue = -9999;
            events(index).choice = '';
            events(index).totalreward = -9999;
%             events(index).reactiontime = -9999;            
            index=index+1;
            
        case 'CUE'
            
            
            xTOT=textscan(thisLine,'%f%d%s%s');
            events(index).experiment = 'playpass';
            events(index).subject = subject;
            events(index).session = session;
            events(index).mstime = mstime;
            events(index).type = xTOT{3}{1};
            events(index).img1file = -9999;
            events(index).img2file = -9999;
            events(index).img3file = -9999;
            events(index).img4file = -9999;
            events(index).inputvaluesrow = -9999;
            events(index).suit = '';
            events(index).rewardtype = -9999;
            events(index).rewardvalue = -9999;
            events(index).delaytype = -9999;
            events(index).delayvalue = -9999;
            events(index).choice = '';
            events(index).totalreward = -9999;
%             events(index).reactiontime = -9999;
            index=index+1;
            
        case 'SECOND_VIEW'
            
            
            xTOT=textscan(thisLine,'%f%d%s%s%d%d%d%d');
            events(index).experiment = 'playpass';
            events(index).subject = subject;
            events(index).session = session;
            events(index).mstime = mstime;
            events(index).type = xTOT{3}{1};
            events(index).img1file = '';
            events(index).img2file = '';
            events(index).img3file = '';
            events(index).img4file = '';
            events(index).inputvaluesrow = -9999;
            events(index).suit = xTOT{4};
            events(index).rewardtype = xTOT{5};
            events(index).rewardvalue = xTOT{6};
            events(index).delaytype = xTOT{7};
            events(index).delayvalue = -9999;
            events(index).choice = '';
            events(index).totalreward = -9999;
%             events(index).reactiontime = -9999;
            index=index+1;
            
        case 'USER_CHOICE'
            
            xTOT=textscan(thisLine,'%f%d%s%d');
            
            
            
            if xTOT{4} == 0
                
                xTOT=textscan(thisLine,'%f%d%s%d%s%d%d%d%d');
                events(index).experiment = 'playpass';
                events(index).subject = subject;
                events(index).session = session;
                events(index).mstime = mstime;
                events(index).type = xTOT{3}{1};
                events(index).suit = xTOT{5};
                events(index).img1file = '';
                events(index).img2file = '';
                events(index).img3file = '';
                events(index).img4file = '';
                events(index).inputvaluesrow = -9999;
                events(index).rewardtype = xTOT{6};
                events(index).rewardvalue = xTOT{7};
                events(index).delaytype = xTOT{8};
                events(index).delayvalue = xTOT{9};
                events(index).choice = xTOT{4};
                events(index).totalreward = -9999;
                %events(index).reactiontime = -xTOT{10}; %uncomment when RT
              
                index=index+1;

                
            elseif xTOT{4} == 1
                    
                    xTOT=textscan(thisLine,'%f%d%s%d%s%d%d%d%d');
                    events(index).experiment = 'playpass';
                    events(index).subject = subject;
                    events(index).session = session;
                    events(index).mstime = mstime;
                    events(index).type = xTOT{3}{1};
                    events(index).suit = xTOT{5};
                    events(index).img1file = '';
                    events(index).img2file = '';
                    events(index).img3file = '';
                    events(index).img4file = '';
                    events(index).inputvaluesrow = -9999;
                    events(index).rewardtype = xTOT{6};
                    events(index).rewardvalue = xTOT{7};
                    events(index).delaytype = xTOT{8};
                    events(index).delayvalue = xTOT{9};
                    events(index).choice = xTOT{4};
                    events(index).totalreward = -9999;
                    %events(index).reactiontime = -xTOT{10}; %uncomment when RT
                    index=index+1;
                    
                else
                    xTOT=textscan(thisLine,'%f%d%s%s');
                    events(index).experiment = 'playpass';
                    events(index).subject = subject;
                    events(index).session = session;
                    events(index).mstime = mstime;
                    events(index).type = xTOT{3}{1};
                    events(index).suit = '';
                    events(index).img1file = '';
                    events(index).img2file = '';
                    events(index).img3file = '';
                    events(index).img4file = '';
                    events(index).inputvaluesrow = -9999;
                    events(index).rewardtype = -9999;
                    events(index).rewardvalue = -9999;
                    events(index).delaytype = -9999;
                    events(index).delayvalue = -9999;
                    events(index).choice = 2;
                    events(index).totalreward = -9999;
%                     events(index).reactiontime = -9999;
                    index=index+1;
                end
          
           
            
        case 'WINNINGS_DISPLAY'
            
            
            xTOT=textscan(thisLine,'%f%d%s%d%d');
            events(index).experiment = 'playpass';
            events(index).subject = subject;
            events(index).session = session;
            events(index).mstime = mstime;
            events(index).type = xTOT{3}{1};
            events(index).suit = '';
            events(index).img1file = '';
            events(index).img2file = '';
            events(index).img3file = '';
            events(index).img4file = '';
            events(index).inputvaluesrow = -9999;
            events(index).rewardtype = -9999;
            events(index).rewardvalue = xTOT{4};            
            events(index).delaytype = -9999;
            events(index).delayvalue = -9999;
            events(index).choice = '';
            events(index).totalreward = xTOT{5};
%             events(index).reactiontime = -9999;
            index=index+1;
                    
            
        case 'E'
            events(index).experiment = 'playpass';
            events(index).subject = subject;
            events(index).session = session;
            events(index).msoffset = msoffset;
            events(index).mstime = mstime;
            events(index).type = xTOT{3}{1};
            %break
    end
end
%disp('done')
