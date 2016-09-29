function [x0,x2, elecs2,a] = monopolarElecOptimize(eegToolDir,serverDir,subjects)
% Input: homeDir = '/Users/damerasr/Sri'
% Input: subj = 'NIH001'
% Input: iFlag = 1 if you are projecting innerhemispheric electrodes

% Output: saves out projected electrodes and bipolar electrodes in talSurf
% and talBipolar respectively
dataDir = fullfile('/Volumes/Shares-4/FRNU/dataWorking','eeg');

for s =  1:length(subjects)
    subj = subjects{s};
    subjDir=fullfile(dataDir, subj);
    talDir=fullfile(subjDir,'tal');
    talSurfDir=fullfile(dataDir,'tal','monopolar','talSurf');
    coordFile=fullfile(talDir,'RAW_coords.txt');
    [labels,x, y, z] = textread(coordFile,'%f%f%f%f');
    elecs = [x, y, z];
    %% remove depth electrodes
    docsDir = fullfile(subjDir,'docs');
    depthFile = fullfile(docsDir,'depth_el_info.txt');
    depthExist = exist(depthFile,'file');
    electrodeGroups = fullfile(subjDir,'docs','electrodes.m'); % should not contain the sync channels
    run(electrodeGroups); %creates variable r with all electrode locations
    if depthExist
        fid = fopen(depthFile);
        depthInfo = textscan(fid,'%d8%*s%*s%*s%*s%*s');
        fclose(fid);
        depthElecs = depthInfo{1,1};
        [~,depthIdx] = ismember(depthElecs,labels);
        elecLabels = setdiff(labels,depthElecs);
        [~,corticalElecLabels] = ismember(elecLabels,labels);
        corticalElecs = elecs(corticalElecLabels,:);
    else
        corticalElecs = elecs;
        corticalElecLabels =  1:size(elecs,1);
    end
    
    %% Create Cortical surface
    
    
    brainShell = load(fullfile(eegToolDir, 'trunk/roi/Finalized surfaces/elecUnProjShell.mat'));
    brainShell = brainShell.shell;
    pts = relPtsSelect(corticalElecs,brainShell);
    
    options = optimset('Algorithm','interior-point','Display','iter','MaxFunEvals', inf,'MaxIter',400,'TolCon',1e-2,'TolFun',1e-1,'UseParallel','always');
    %% projects electrode positions
    x1 = corticalElecs;
    d0 = findDistMat(x1);
    a = alphaMake(dataDir,x1,subj,corticalElecLabels);
    x0 = x1;
    
    x2 = fmincon(@(x)objfun(x,x0,d0,a),x1,[],[],[],[],[],[],@(x)confun(x,pts),options);
    
    elecs2 = x2;
    elecs2 = findNewPts(elecs2,brainShell);
    %% adds on depth electrodes
    if depthExist
        elecs3= zeros(size(elecs));
        elecs3(corticalElecLabels,:) = elecs2;
        elecs3(depthIdx,:) = elecs(depthIdx,:);
        elecs2 = elecs3;
    end
    
    elecs2 = [(1:size(elecs2,1))' elecs2];
    elecs2 = elecs2';
    
    coordFile=fullfile(talDir,'RAW_SURF_coords.txt');
    fid = fopen(coordFile,'w');
    fprintf(fid,'%d\t%f\t%f\t%f\n',elecs2);
    fclose(fid);
    
    %% creates event structures and saves
    talGenDir=fullfile(talDir,'talGen');
    talGenSubjDir=fullfile(talGenDir,subj);
    talGenSubjTalDir=fullfile(talGenSubjDir,'tal');
    
    mkdir(talGenDir)
    mkdir(talGenSubjDir)
    mkdir(talGenSubjTalDir)
    
    copyfile(fullfile(talDir,'tal_params.txt'), talGenSubjTalDir);
    copyfile(fullfile(talDir,'good_leads.txt'), talGenSubjTalDir);
%         copyfile(fullfile(talDir,'*.montage'), talGenSubjTalDir);
    
    coordFile2=fullfile(talGenSubjTalDir,'RAW_coords.txt');
    fid = fopen(coordFile2,'w');
    fprintf(fid,'%d\t%f\t%f\t%f\n',elecs2);
    fclose(fid);
    
    chdir(talGenDir)
    preptal('.')
    events=tal_locs_to_events('allTalLocs.txt');
    events=tal2Region(events);
    saveEvents(events,['talSurf_' subj '.mat']);
    
    copyfile(fullfile(talGenDir,['talSurf_' subj '.mat']), talSurfDir);
    chdir(subjDir)
    rmdir(talGenDir,'s')
end