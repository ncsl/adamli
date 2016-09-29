function events=AS_extractPlayPassEvents(subject,expDir,session)

%%
% clear all
% close all
% session = 0;
% subject = 'fred28';
% expDir   = '/Users/ammar/Desktop/NIH/playPass/game_code/PlayPass/data/';
% sessFile = fullfile(expDir,subject,['Behavior/playPass/session_' num2str(session)],'session.log');
% vlogFile = fullfile(expDir,subject,['Behavior/playPass/session_' num2str(session)],'video.vidlog');
sessFile = fullfile(expDir,['session_' num2str(session)],'session.log');
vlogFile = fullfile(expDir,['session_' num2str(session)],'video.vidlog');

fidSess = fopen(sessFile,'r'); %if loops check to see that sessFile exists
fidvlog = fopen(vlogFile,'r');
if fidSess==-1
    fprintf('session %d..no session.log file found.\n',session);
    fprintf('EXITING\n\n');
    return
end

if fidvlog==-1
    fprintf('video log for session %d..no video.vlog file found.\n',session);
    fprintf('EXITING\n\n');
    return
else
    %disp(['The session.log file is located in: '  sessFile])
end
%% parse the videolog file
% extract all the image presentations 
% column 7 will contain the type of cue
% column 8 will contain the image path
imgNum = [];
vlogTS = [];
vlogType = {};
index = 0;
while true
    
    thisLine = fgetl(fidvlog);
    if ~ischar(thisLine);
        break;
    end
    % get the third string before the underscore
    inLine=textscan(thisLine,'%f%d%s%s%d%s%s%s%s%s%s','Delimiter','\t');
    
    if strcmp(inLine{7},'IMAGE')
        index = index+1;
        vlogTS(index) = inLine{1}; 
        %get the path of the image displayed
        pathString=strsplit(inLine{8}{1},'/'); 
        imageFileName=strsplit(pathString{end},'.');
        imageName = imageFileName{1};
        
        if strcmp(imageName(1:end-3),'Slide')
            vlogType{index} = 'Cue';
            imgNum(index) = str2double(imageName(end-2:end));
        elseif strcmp(imageName,'goldcoins')
            vlogType{index} = 'Reward';
            imgNum(index) = -1;
        end              
    elseif strcmp(inLine{7},'TEXT')
        if strcmp(inLine{end}{1}(2),'+')
            index = index+1;
            vlogTS(index) = inLine{1};
            vlogType{index} = 'OrientCue';
            imgNum(index) = -1;
        end
    end
end
%% create a matrix for orientation cues timestamps
orientCueSelector = strcmp(vlogType,'OrientCue');
orientCueTS = vlogTS(orientCueSelector);
%% creat similar matrix for cue timestamps... 
% here we need to remove the repeated lines
cueSelector = strcmp(vlogType,'Cue');
rawCueTS = vlogTS(cueSelector);
rawCueImg = imgNum(cueSelector);
% will use the idea that each orientation cue should be followed by a cue
cueTS = zeros(size(orientCueTS)); %initialize matrix
cueImg = zeros(size(orientCueTS));
for j=1:length(orientCueTS)
    tempTS = rawCueTS-orientCueTS(j);
    cueTS(j) = rawCueTS(find(tempTS>0,1));
    cueImg(j) = rawCueImg(find(tempTS>0,1));
end   
%% we need a fix for parsing because of the user choice error log for some
% subjects
orientCueInd = find(orientCueSelector);
userChoice = zeros(size(orientCueInd));%initialize matrix
for j = 2:length(userChoice)
    if strcmp(vlogType(orientCueInd(j)-1),'Reward')
        userChoice(j-1)=1;
    end
end
% test the last trial
if strcmp(vlogType(end),'Reward')
    userChoice(end) = 1;
end    
%% 
index = 1;
cueIndex = 1;
orientCueIndex = 1;
choiceIndex = 1;
events = [];
while true
    thisLine = fgetl(fidSess);
    if ~ischar(thisLine);
        break;
    end
    % get the third string before the underscore
    xTOT=textscan(thisLine,'%f%d%s');
    
    mstime              = xTOT{1}(1);  
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
            events(index).inputvaluesrow = -9999;
            events(index).img1file = -9999;
            events(index).img2file = -9999;
            events(index).img3file = -9999;
            events(index).img4file = -9999;
            events(index).suit = '';
            events(index).rewardtype = -9999;
            events(index).rewardvalue = -9999;
            events(index).delaytype = -9999;
            events(index).delayvalue = -9999;
            events(index).choice = '';
            events(index).totalreward = -9999;
            index=index+1;           
        case 'Img1' 
            xTOT=textscan(thisLine,'%f%d%s%d%s%d%s%d%s%d%s%d');           
            events(index).experiment = 'playpass';
            events(index).subject = subject;
            events(index).session = session;
            events(index).msoffset = msoffset;
            events(index).mstime = mstime;
            events(index).type = 'SETUP';
            events(index).inputvaluesrow = xTOT{12};
            events(index).img1file = xTOT{4};
            events(index).img2file = xTOT{6};
            events(index).img3file = xTOT{8};
            events(index).img4file = xTOT{10};
            events(index).suit = '';
            events(index).rewardtype = -9999;
            events(index).rewardvalue = -9999;
            events(index).delaytype = -9999;
            events(index).delayvalue = -9999;
            events(index).choice = '';
            events(index).totalreward = -9999;
            index=index+1;         
        case 'CUE'         
            xTOT=textscan(thisLine,'%f%d%s%s');
            events(index).experiment = 'playpass';
            events(index).subject = subject;
            events(index).session = session;
            events(index).mstime = orientCueTS(orientCueIndex);
            events(index).type = xTOT{3}{1};
            events(index).inputvaluesrow = -9999;
            events(index).img1file = -9999;
            events(index).img2file = -9999;
            events(index).img3file = -9999;
            events(index).img4file = -9999;
            events(index).suit = '';
            events(index).rewardtype = -9999;
            events(index).rewardvalue = -9999;
            events(index).delaytype = -9999;
            events(index).delayvalue = -9999;
            events(index).choice = '';
            events(index).totalreward = -9999;
            index=index+1;
            orientCueIndex = orientCueIndex+1;          
        case 'SECOND_VIEW'        
            xTOT=textscan(thisLine,'%f%d%s%s%d%d%d%d');
            events(index).experiment = 'playpass';
            events(index).subject = subject;
            events(index).session = session;
            events(index).mstime = cueTS(cueIndex);
            events(index).type = xTOT{3}{1};
            events(index).inputvaluesrow = -9999;
            events(index).img1file = -9999;
            events(index).img2file = -9999;
            events(index).img3file = -9999;
            events(index).img4file = -9999;
            events(index).slidenumber = cueImg(cueIndex);
            events(index).suit = xTOT{4};
            events(index).rewardtype = xTOT{5};
            events(index).rewardvalue = xTOT{6};
            events(index).delaytype = xTOT{7};
            events(index).delayvalue = xTOT{8};
            events(index).choice = '';
            events(index).totalreward = -9999;
            index=index+1;
            cueIndex = cueIndex+1;         
        case 'USER_CHOICE'         
            xTOT=textscan(thisLine,'%f%d%s%d');(find(tempTS>0,1));        
            if xTOT{4} == 0               
                xTOT=textscan(thisLine,'%f%d%s%d%s%d%d%d%d');
                events(index).experiment = 'playpass';
                events(index).subject = subject;
                events(index).session = session;
                events(index).mstime = mstime;
                events(index).type = xTOT{3}{1};
                events(index).suit = xTOT{5};
                events(index).inputvaluesrow = -9999;
                events(index).img1file = -9999;
                events(index).img2file = -9999;
                events(index).img3file = -9999;
                events(index).img4file = -9999;
                events(index).rewardtype = xTOT{6};
                events(index).rewardvalue = xTOT{7};
                events(index).delaytype = xTOT{8};
                events(index).delayvalue = xTOT{9};
                events(index).choice = userChoice(choiceIndex);
                events(index).totalreward = -9999;
            elseif xTOT{4} == 1              
                xTOT=textscan(thisLine,'%f%d%s%d%s%d%d%d%d');
                events(index).experiment = 'playpass';
                events(index).subject = subject;
                events(index).session = session;
                events(index).mstime = mstime;
                events(index).type = xTOT{3}{1};
                events(index).suit = xTOT{5};
                events(index).inputvaluesrow = -9999;
                events(index).img1file = -9999;
                events(index).img2file = -9999;
                events(index).img3file = -9999;
                events(index).img4file = -9999;
                events(index).rewardtype = xTOT{6};
                events(index).rewardvalue = xTOT{7};
                events(index).delaytype = xTOT{8};
                events(index).delayvalue = xTOT{9};
                events(index).choice = userChoice(choiceIndex);
                events(index).totalreward = -9999;                           
            else
                xTOT=textscan(thisLine,'%f%d%s%s');
                events(index).experiment = 'playpass';
                events(index).subject = subject;
                events(index).session = session;
                events(index).mstime = mstime;
                events(index).type = xTOT{3}{1};
                events(index).suit = '';
                events(index).inputvaluesrow = -9999;
                events(index).img1file = -9999;
                events(index).img2file = -9999;
                events(index).img3file = -9999;
                events(index).img4file = -9999;
                events(index).rewardtype = -9999;
                events(index).rewardvalue = -9999;
                events(index).delaytype = -9999;
                events(index).delayvalue = -9999;
                events(index).choice = 2;
                events(index).totalreward = -9999;             
            end
            index=index+1;
            choiceIndex = choiceIndex+1;       
        case 'WINNINGS_DISPLAY'                    
            xTOT=textscan(thisLine,'%f%d%s%d%d');
            events(index).experiment = 'playpass';
            events(index).subject = subject;
            events(index).session = session;
            events(index).mstime = mstime;
            events(index).type = xTOT{3}{1};
            events(index).suit = '';
            events(index).inputvaluesrow = -9999;
            events(index).img1file = -9999;
            events(index).img2file = -9999;
            events(index).img3file = -9999;
            events(index).img4file = -9999;
            events(index).rewardtype = -9999;
            events(index).rewardvalue = xTOT{4};            
            events(index).delaytype = -9999;
            events(index).delayvalue = -9999;
            events(index).choice = '';
            events(index).totalreward = xTOT{5};
            index=index+1;     
        case 'E'
            events(index).experiment = 'playpass';
            events(index).subject = subject;
            events(index).session = session;
            events(index).msoffset = msoffset;
            events(index).mstime = mstime;
            events(index).type = xTOT{3}{1};
    end
end

%% correct the image file names
imgMap = {};
cueInd = 1;
for j = 1:length(events)
    if strcmp(events(j).type,'SECOND_VIEW')
        imgMap{cueInd,1} = events(j).suit{1};
        imgMap{cueInd,2} = events(j).slidenumber;
        cueInd = cueInd+1;
    end
end

%fix the setup event
for j = 1:length(events)
    if strcmp(events(j).type,'SETUP')
        a = strcmp(imgMap(:,1),'Img1');
        a = imgMap(a,2);
        if ~isempty(a)
           events(j).img1file = a{1};
        end
        
        a = strcmp(imgMap(:,1),'Img2');
        a = imgMap(a,2);
        if ~isempty(a)
           events(j).img2file = a{1};
        end
        
        a = strcmp(imgMap(:,1),'Img3');
        a = imgMap(a,2);
        if ~isempty(a)
           events(j).img3file = a{1};
        end
        
        a = strcmp(imgMap(:,1),'Img4');
        a = imgMap(a,2);
        if ~isempty(a)
           events(j).img4file = a{1};
        end
        
    end
end
close all