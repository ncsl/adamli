function alpha = alphaMake(dataDir,grid,subj,corticalElecLabels)

%% Constructs alpha matrix(connectivity matrix) for each set of patients electrodes

alpha = zeros(size(grid,1));
fid = fopen(fullfile(dataDir,subj,'tal','leads_bp.txt'));
if fid ==-1
    alpha = alphaMakeBipolar(grid);
else
    
    leads = textscan(fid,'%d%*c%d');
    leads = [leads{1} leads{2}];
    corticalElecLabels = corticalElecLabels.';
    subjDir=fullfile(dataDir, subj);
    docsDir = fullfile(subjDir,'docs');
    depthFile = fullfile(docsDir,'depth_el_info.txt');
    depthExist = exist(depthFile,'file');
    if depthExist
        fid = fopen(depthFile);
        depthInfo = textscan(fid,'%d8%*s%*s%*s%*s%*s');
        fclose(fid);
        depthElecs = depthInfo{1,1};
        foo = ismember(double(leads),double(depthElecs));
        leads = [leads(~foo(:,1),1) leads(~foo(:,2),2)];
    end

    for j = 1:size(leads,1) 
        alpha(leads(j,1)==corticalElecLabels,leads(j,2)==corticalElecLabels) = 1;
    end
end