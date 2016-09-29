function finalEllipse = gridMake(toolDir,brainType,interval)
%Function finalEllipse = gridMake(homeDir,iFlag)
%
%   This function creates a 'dural' surface around each hemisphere
%   independently and then concatenates them at the end to evnelop the
%   entire brain
%
%   Inputs:
%           --toolDir = '/Volumes/Kareem/' (where eeg toolbox is located)
%           --brainType = 'Colin_27' (brain that dural surface will cover)
%           --interval = interval at which the Ellipse points and the Ellipses themselves should be created
%
%   Outputs:
%           --the Final surface is outputted
%           --final surface is saved in 'toolDir/trunk/tal/roi/Dura_ROIs/'
%           --single ellipses are saved: 'toolDir/trunk/tal/roi/Dura_ROIs/partial_dura/'


%% opens up matlab pool workers
% matlabpool open 12

%% Loads The Specified Brain's Left And Right Hemisphere's Vertices and Faces
left = load(fullfile(toolDir,'trunk', 'roi','Pial Surfaces',brainType,'Left_hemisphere.mat'));
right = load(fullfile(toolDir,'trunk', 'roi','Pial Surfaces',brainType,'Right_hemisphere.mat'));

%% Actually Creates Dural Surface
count = 1;
inter = interval; % -10 FOR ROIs or -1 FOR ELECTRODE PROJECTION
% Create Dura around left hemisphere
v = left.v;
% v(:,2) = v(:,2)*-1;
% v(:,1) = v(:,1)*-1;
start = max(v(:,2));
finish = min(v(:,2));
leftEllipse = [];

for y = start:inter:finish
    y = 0;
    disp(num2str(y))
    ellipseDir =fullfile(toolDir,'branches', 'left', num2str(inter), num2str(count)); % sets directory where individual ellipses are saved
    if ~exist(ellipseDir,'dir')
        mkdir(ellipseDir)
        ellipse =  projEllipseMake(v,y,inter);
        leftEllipse = [leftEllipse;ellipse];
        save([ellipseDir '/rawEllipse.mat'],'ellipse')
    end
    count = count+1;
end
% Do it for Right hemisphere
v = right.v;
% v(:,2) = v(:,2)*-1;
% v(:,1) = v(:,1)*-1;
start = max(v(:,2));
finish = min(v(:,2));
rightEllipse = [];
count = 1;
for y = start:inter:finish
    disp(num2str(y))
    ellipseDir =fullfile(toolDir,'branches',  'right', num2str(inter), num2str(count));
    if ~exist(ellipseDir,'dir')
        mkdir(ellipseDir)
        ellipse =  projEllipseMake(v,y,inter);
        rightEllipse = [rightEllipse;ellipse];
        save([ellipseDir '/rawEllipse.mat'],'ellipse')
    end
    count = count+1;
end

finalEllipse = [leftEllipse;rightEllipse];

%% Saves Final Dural Surface
if inter ==-10
corticalSurfROI = finalEllipse;
save(fullfile(serverDir,'corticalSurfROI.mat'),'corticalSurfROI');
elseif inter <= 1
shell = finalEllipse;
save(fullfile(serverDir,'elecProjShell.mat'),'shell');
end