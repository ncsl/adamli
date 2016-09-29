function electrodes = reref_Bipolarity(subjDir,eegFilestem)
% function r = reref_Bipolarity(subjDir,threshold_mm,eegFilestem)
%
% Wrapper to extractBipolarity. This function writes out the bipolar data files to the tal directory
%
% INPUT:
%         --subjDir      = subject directory. For example, '/Users/dongj3/Jian/data/eeg/NIH003/'
%         --eegFilestem  = 'NIH001_121211_0933'
%         --relElecs  = which electrodes are actually recorded for a
%         particular filestem
%
% OUTPUT: --electrodes:        list of electrodes (from electrodes.m)
%    
%    new leads_Bipolar.txt files and bipolar rerefrenced files
%         --leads_bp.txt:      contains all possible bipolar pairs
%         --good_leads_bp.txt: contains only those bipolar pairs that contain two good electrodes
%         --bad_leads_bp.txt:  contains  those bipolar pairs that contain even one bad electrode
%    

[eegDir,subj] = fileparts(subjDir);
talDir      = fullfile(subjDir,'tal');
bipolarFile = fullfile(talDir,'leads_bp.txt');
badLeads    = load(fullfile(subjDir,'tal','bad_leads.txt'));
leads       = load(fullfile(subjDir,'tal','leads.txt'));

%-- get bipolar pairs and electrodes... create bipolar text docs 
if ~exist(bipolarFile,'file')
    [bipolarPairs,electrodes] = extractBipolarity(subjDir);
    if length(unique(bipolarPairs)) ~= length(leads)
        keyboard
        error('Some leads were not included in bipolar pairing.');
    end
else
    clear r;
    run(fullfile(subjDir,'docs','electrodes.m')); %creates variable r with all electrode locations
    if ~exist('r','var'), 
        error('No grids found in docs/electrodes.m')
    else
        electrodes = r;
    end
    bipolarPairs = textscan(fopen(bipolarFile),'%d%*c%d');
    fclose('all');
    bipolarPairs = [bipolarPairs{1} bipolarPairs{2}];
end


%checks to see if all the electrodes were used
badLeads_Bipolar = []; goodLeads_Bipolar = [];

%for loop is used to create arrays with good leads and bad leads
for i = 1: length(bipolarPairs)
    if ~isempty(intersect(bipolarPairs(i,1),badLeads)) || ~isempty(intersect(bipolarPairs(i,2),badLeads))
        badLeads_Bipolar = [badLeads_Bipolar; bipolarPairs(i,1), bipolarPairs(i,2);];
    else
        goodLeads_Bipolar = [goodLeads_Bipolar; bipolarPairs(i,1), bipolarPairs(i,2);];
    end
end


% Use the existing good_leads_bp.txt, bad_leads_bp.txt, leads_bp.txt to make
% files in case the new one does not match it.
useExisting = 1;

%checks to see if this current bipolar good leads is the same as the
%existing one, if there is an existing one.
if exist(fullfile(subjDir,'tal','good_leads_bp.txt'),'file')
    [goodBipolar1,goodBipolar2]=textread(fullfile(subjDir,'tal','good_leads_bp.txt'),'%d%d','delimiter','-');
    goodBipolar=[goodBipolar1,goodBipolar2];
    if ~isequal(goodBipolar,goodLeads_Bipolar)
        if useExisting
            disp('Warning: Current good_leads_bp.txt does not equal previous one. Keeping existing one...')
            goodLeads_Bipolar=goodBipolar;
        end
    end
else
    if ~isempty(goodLeads_Bipolar)
        %         keyboard
        fclose('all')
        goodLeadsHandle=fopen(fullfile(subjDir,'tal','good_leads_bp.txt'),'w','l');
        fprintf(goodLeadsHandle,'%d-%d\n',goodLeads_Bipolar');
        fclose(goodLeadsHandle);
    end
end

%checks to see if this current bipolar bad leads is the same as the
%existing one, if there is an existing one.
if exist(fullfile(subjDir,'tal','bad_leads_bp.txt'),'file')
    [badBipolar1,badBipolar2]=textread(fullfile(subjDir,'tal','bad_leads_bp.txt'),'%d%d','delimiter','-');
    badBipolar=[badBipolar1,badBipolar2];
    if ~isequal(badBipolar,badLeads_Bipolar) && (~isempty(badBipolar) && ~isempty(badLeads_Bipolar))
        if useExisting
            disp('Warning: Current bad_leads_bp.txt does not equal previous one. Keeping existing one...')
            badLeads_Bipolar=badBipolar;
        end
    end
else
    if ~isempty(badLeads_Bipolar)
        fclose('all')
        badLeadsHandle = fopen(fullfile(subjDir,'tal','bad_leads_bp.txt'),'w','l');
        fprintf(badLeadsHandle,'%d-%d\n',badLeads_Bipolar');
        fclose(badLeadsHandle);
    end
end

%checks to see if this current bipolar leads is the same as the
%existing one, if there is an existing one.
if exist(fullfile(subjDir,'tal','leads_bp.txt'),'file')
    [allBipolar1,allBipolar2]=textread(fullfile(subjDir,'tal','leads_bp.txt'),'%d%d','delimiter','-');
    allBipolar=[allBipolar1,allBipolar2];
    if ~isequal(allBipolar,bipolarPairs)
        if useExisting
            disp('Warning: Current leads_bp.txt does not equal previous one. Using existing one...')
            bipolarPairs=allBipolar;
        end
    end
else
    fclose('all')
    leadsHandle = fopen(fullfile(subjDir,'tal','leads_bp.txt'),'w','l');
    fprintf(leadsHandle,'%d-%d\n',bipolarPairs');
    fclose(leadsHandle);
end

[~,~,~,bipolarPairs2] = nkElectrodeFilt(eegDir,subj,eegFilestem);
if ~isempty(bipolarPairs2)
    bipolarPairs = bipolarPairs2;
end

%Actually creates the bipolar files...
for i = 1:size(bipolarPairs,1)
    file1 = sprintf([eegFilestem '.' '%03i'], bipolarPairs(i,1));
    file1Dir = fullfile(subjDir,'eeg.noreref',file1);
    
    file2 = sprintf([eegFilestem '.' '%03i'], bipolarPairs(i,2));
    file2Dir = fullfile(subjDir,'eeg.noreref',file2);
    
    dataFormat = 'int16';
    file1Handle = fopen(file1Dir, 'r','l');
    if file1Handle==-1, error( sprintf('  ERROR: reref_Bipolarity cant open %s',file1Dir) ); end
    data1 =  fread(file1Handle, inf, dataFormat);
    fclose(file1Handle);
    
    file2Handle = fopen(file2Dir, 'r','l');
    if file2Handle==-1, error( sprintf('  ERROR: reref_Bipolarity cant open %s',file2Dir) ); end
    data2 =  fread(file2Handle, inf, dataFormat);
    fclose(file2Handle);
    
    chanfile = sprintf('%s.%03i-%03i', fullfile(subjDir, 'eeg.reref',eegFilestem),bipolarPairs(i,1),bipolarPairs(i,2));
    disp(['Making file:' chanfile]);
    chanHandle = fopen(chanfile,'w','l');
    fwrite(chanHandle,data1-data2,dataFormat);
    fclose(chanHandle);
end