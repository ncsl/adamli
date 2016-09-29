function elecs2 = bipolarElecOptimize(eegToolDir,serverDir,subjects)
% Input: homeDir = '/Users/damerasr/Sri'
% Input: subj = 'NIH001'
% Input: iFlag = 1 if you are projecting innerhemispheric electrodes

% Output: saves out projected electrodes and bipolar electrodes in talSurf
% and talBipolar respectively
dataDir = fullfile(serverDir,'dataWorking','eeg');

for s = 1:length(subjects)
    subj = subjects{s};
    subjDir=fullfile(dataDir, subj);
    talDir=fullfile(subjDir,'tal');
    talSurfDir=fullfile(dataDir,'tal','bipolar','talSurf');
    
    bpFlag = 1;
    coordFile=fullfile(talDir,'RAW_coords.txt');
    [elecLabels,x, y, z] = textread(coordFile,'%f%f%f%f');
    elecs = [x, y, z];
    chanFile = fullfile(talDir,'leads_bp.txt');
    gl=textscan(fopen(chanFile),'%d%*c%d');
    gl = [gl{1} gl{2}];
    
    [~,idx] = ismember(gl(:,1),elecLabels);
    [~,idx2] = ismember(gl(:,2),elecLabels);
    gl = [idx, idx2];
    foo = elecs(gl(:,1),:);
    foo2 =elecs(gl(:,2),:);
    elecs = (foo+foo2)/2; % gets bipolar coordinates
    
    %% remove depth electrodes
    docsDir = fullfile(subjDir,'docs');
    depthFile = fullfile(docsDir,'depth_el_info.txt');
    depthExist = exist(depthFile,'file');
    
    
    if depthExist
        fid = fopen(depthFile);
        depthInfo = textscan(fid,'%d8%*s%*s%*s%*s%*s');
        fclose(fid);
        depthElecs = depthInfo{1,1};
        [~,depthIdx] = ismember(depthElecs,elecLabels);
        idx = ~ismember(double(gl(:,1)),double(depthIdx));
        corticalElecs = elecs(idx,:);
        corticalElecLabels = find(idx==1);
        depthElecs = find(idx==0);
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
    a = alphaMakeBipolar(x1);
    
    x0 = x1;
    
    x2 = fmincon(@(x)objfun(x,x0,d0,a),x1,[],[],[],[],[],[],@(x)confun(x,pts),options);
    elecs2 = x2;
    elecs2 = findNewPts(elecs2,brainShell);
    %% adds on depth electrodes
    if depthExist
        elecs3= zeros(size(elecs));
        elecs3(corticalElecLabels,:) = elecs2;
        elecs3(depthElecs,:) = elecs(depthElecs,:);
        elecs2 = elecs3;
    end
    elecs2 = [(1:size(elecs2,1))' elecs2];
    elecs2 = elecs2';
    
    coordFile=fullfile(talDir,'RAW_SURF_BIPOLAR_coords.txt');
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
    %     copyfile(fullfile(talDir,'*.montage'), talGenSubjTalDir);
    
    coordFile2=fullfile(talGenSubjTalDir,'RAW_SURF_BIPOLAR_coords.txt');
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
