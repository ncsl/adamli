function createMasterJack(subj, rootEEGdir)
%
% createMasterJack.m
%
% Creates the master jacksheet based on the tagNameOrder and the
% tag labels located in all of the 21E files.  Checks to make sure
% these are the same number of electrodes as located in the
% electrode.m file and in leads.txt, which should be aligned.
%
% FUNCTION:
%    (subj,rootEEGdir)
%
% INPUT ARGs:
% subj = 'TJ022'
%
% Output
%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set home directory
%rootEEGdir='/Users/zaghloulka/Kareem/data/eeg';
subjDir=fullfile(rootEEGdir,subj);
docDir=fullfile(subjDir,'docs');
rawDir=fullfile(subjDir,'raw');
talDir=fullfile(subjDir,'tal');

% Get electrode information and tag names info from docs directory
tagNameFile=fullfile(docDir,'tagNames.txt');
tagNameOrder=textread(tagNameFile,'%s');

elecFile=fullfile(docDir,'electrodes.m');
run(elecFile);

% Get leads info from tal directory
leadsFile=fullfile(talDir,'leads.txt');
leads=textread(leadsFile,'%d');

% Check to make sure that the number of leads equals the number of
% electrodes
if length(leads)~=r(end)
    fprintf('The number of leads in tal does not equal the number of electrodes in electrodes.m for %s Exiting.\n', subj);
    return
end

% Create ideal master list of tag names and numbers
masterNames=[];
masterNums=[];

lastNum=0;
for e=1:size(r,1)
    numElecs=r(e,2)-r(e,1)+1;
    for j=1:numElecs
        masterNums=[masterNums;j+lastNum];
        masterNames{j+lastNum}=tagNameOrder{e};
    end
    lastNum=lastNum+numElecs;
end

if ~exist(rawDir)
    fprintf(['No raw directory for ' subj ', Exiting.\n']);
    return
end

% Now loop through each session and get allCodes and allNames from
% raw 21E files and place in structure called sess
sessNum=1;

% Find list of day directories
stimDir=dir([rawDir '/STIM*']); %add * so dir doesn't look inside STIM directory; STIM is equivalent to DAY_X, in that both contain SESS_X
dayDirs=dir([rawDir '/DAY_*']);
dayDirs(end+1:end+length(stimDir))=stimDir; %concatinate list
if isempty(dayDirs)
    fprintf(['No days containing raw data for ' subj ', Exiting.\n']);
    return
end

for d=1:length(dayDirs)
    
    thisDayDir=fullfile(rawDir,dayDirs(d).name);
    
    % Find sessions within each day
    sessDirs=dir([thisDayDir '/SESS_*']);
    if isempty(sessDirs)
        
        d21=dir([thisDayDir '/*.21E']);
        deeg=dir([thisDayDir '/*.EEG']);
        
        if ~exist(fullfile(thisDayDir,d21.name))
            continue
        else
            elecFileNk=fullfile(thisDayDir,d21.name);
            eegFileNk=fullfile(thisDayDir,deeg.name);
            
            % Get channel names and codes from EEG and 21E file
            allNames=getChanNames(elecFileNk,eegFileNk);
            
            sess(sessNum).allNames=allNames;
            sessNum=sessNum+1;
        end
        
    else
        for s=1:length(sessDirs)
            
            thisSessDir = fullfile(thisDayDir,sessDirs(s).name);
            
            d21  = dir([thisSessDir '/*.21E']);
            deeg = dir([thisSessDir '/*.EEG']);
            
            if length(d21)==0 | ~exist(fullfile(thisSessDir,d21.name))
                fprintf(' didnt find a .21E file in %s\n',fullfile(thisSessDir,d21.name));
                continue
            else
                
                elecFileNk=fullfile(thisSessDir,d21.name);
                eegFileNk=fullfile(thisSessDir,deeg.name);
                %keyboard
                % Get channel names and codes from EEG and 21E file
                allNames=getChanNames(elecFileNk,eegFileNk);
                
                sess(sessNum).allNames=allNames;
                sessNum=sessNum+1;
            end
            
        end
    end
end
sessNum=sessNum-1;


% Create concatenated meta session
concatAllNames = [];
for s=1:length(sess)
    concatAllNames = [concatAllNames; sess(s).allNames'];
end
[concatAllNames,iUnique,iOriginal] = unique(concatAllNames,'stable');   % create unique version of concatAllNames[U]
[countAllNames, iNames] = hist(iOriginal,[1:length(concatAllNames)]);   % count the number of instances of each name in original list

originalTagNames = regexprep(concatAllNames','\d','')';                 % Get names of channels without tag numbers
originalTagNums  = str2double(regexprep(concatAllNames','[\D]',''))';   % Get tag numbers of channels without names

MISSING_INSTANCE = 0; %flag that indicates whether any channels were NEVER represented in the RAW files


% Go through each tag name and find associated names in each
% session to create final list of names for that tag
for t=1:length(tagNameOrder)
    tagName=tagNameOrder{t};
    

    % find the entries that use this tag name
    matchingRow = find(strcmp(tagName,originalTagNames));
    
    newNames    = concatAllNames(matchingRow);
    newNums     = originalTagNums(matchingRow);  %could use this to sort if numbers get out of order
    newCounts   = countAllNames(matchingRow);
    
    [newNums, iSort] = sort(newNums);
    newNames    = newNames(iSort);
    newCounts   = newCounts(iSort);
    
    % Replace master list with these names and codes.  If the tag is
    % an EKG or DC channel, or is otherwise not listed in the
    % original tagNameOrder, add it to the master list
    matchingTag=find(strcmp(tagName,masterNames));
    
    if ~isempty(matchingTag)
        
        % Check to see if raw data files have as many tags as expected.  If not alert user and note in jacksheetMaster.txt
        if length(newNames)<length(matchingTag)
            MISSING_INSTANCE = 1;
            
            fprintf(' SEVERE WARNING: missing 1 or more instances of %s from raw channel list:\n', tagName); 
            for k=length(newNames)+1:length(matchingTag),
                newNames{k}  = sprintf('%s??_neverUsed',tagName);
                newCounts(k) = 0; 
                fprintf('    --> adding surrogate channel ''%s''\n', newNames{k});
            end 
        end
        
        % Replace names in master with tag names found in raw
        for k=1:length(matchingTag),
            masterNames(matchingTag(k))=newNames(k);
            masterCounts(matchingTag(k))=newCounts(k);
        end
        
        
    else
        
        % Add tags not listed in tagNameOrder, but that were present
        % in the raw data, to master list
        addNums=lastNum+length(newNames);
        masterNums=[masterNums;[lastNum+1:addNums]'];
        for k=1:length(newNames)
            masterNames(lastNum+k)=newNames(k);
            masterCounts(lastNum+k)=newCounts(k);
        end
        lastNum=addNums;
    end
end

% Make the master jacksheet
jackFile=fullfile(docDir,'jacksheetMaster.txt');
fout = fopen(jackFile,'w','l');
for c = 1:length(masterNames),
    if masterCounts(c)==sessNum, strCounts = 'FOUND_IN_ALL_RAWS';
    else                         strCounts = sprintf('MISSING_IN_%d_OF_%d_RAWS',sessNum-masterCounts(c),sessNum); end
    strNumName = sprintf('%d %s',masterNums(c),masterNames{c});
    strNumName(end+1:25) = ' ';  % add a buffer so 3rd column lines up nicely
    fprintf(fout,'%s %s\n',strNumName,strCounts);
end
fclose(fout);
fprintf(' jacksheetMaster.txt created with %d unique channel names\n', length(masterNames));

if MISSING_INSTANCE,
    error(' ERROR: Rereferencing will fail until missing channel instances are removed from electrodes.m (and other tal files).\n Overwrite or delete jasksheetMaster.txt after removing channels.');
end
