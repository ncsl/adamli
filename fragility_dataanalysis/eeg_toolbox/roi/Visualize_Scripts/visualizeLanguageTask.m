function hBrain = visualizeLanguageTask(homeDir,effect,varargin)
%% visualize by ROI method
left = load(fullfile(homeDir,'hnl/matlab/eeg_toolbox/trunk/roi/Pial Surfaces/Colin_27/Left_hemisphere.mat'));
right = load(fullfile(homeDir,'hnl/matlab/eeg_toolbox/trunk/roi/Pial Surfaces/Colin_27/Right_hemisphere.mat'));
V = [left.v;right.v];

f_left= left.f+1;
f_right= right.f+1;
f_right = f_right + length(left.v);
F = [f_left;f_right];

clear left right f_left f_right
figure
%% Formatting Brain
 FVCD = repmat([.5 .5 .5], size(V,1),1);
 hs1 = patch('faces',F,'vertices',V,'edgecolor','none','FaceColor',...
       'flat','FaceVertexCData',FVCD); hold on;
 axis off; axis equal; axis vis3d; rotate3d; 
 set(gca,'XLimMode','manual','YLimMode','manual','ZLimMode','manual',...
     'XLim',[-95 95],'YLim',[-108 72],'ZLim',[-56 88]);
%  set(hs1, 'FaceAlpha', 0.05)

 setBrainProps(hs1); lighting phong
  view([-90 0]);
  view([0 0]);camlight infinite;
 view([-180 -90]); camlight infinite; 
 view([180 0]); camlight infinite;
 view([90 0]); camlight infinite;
view([-180 90]); camlight infinite;
%  set(gca,'cLim',[-5 5]);
 
 %% Setting values at relevant coordinates
D = nan(size(V,1),1);
I = zeros(size(D));


effect(effect==0) = NaN;

%% Assigns vertices values

% if length(varargin)>1
idx = varargin{1};
for j = 1:size(effect,1)
    if ~isempty(idx{j}) % idx contains what vertices fall under each ROI
        avgPower = effect(j);
        if ~isempty(avgPower)&&(~isnan(avgPower))
            avgPower = repmat(avgPower,length(idx{j}),1);
            I(idx{j}) = I(idx{j}) +1;
            D(idx{j}) = nansum([(I(idx{j})-1).*D(idx{j}) avgPower],2)./I(idx{j});
        end
    end
end
% else
%     elecs = varargin{1};
%     d = pdist2(elecs,V);
%     for j = 1:size(effect,1)
%         d_temp = d(j,:);
%         idx = find(d_temp<=12.5);
%         if ~isempty(idx) % idx contains what vertices fall under each ROI
%             avgPower = effect(j);
%             if ~isempty(avgPower)&&(~isnan(avgPower))
%                 avgPower = repmat(avgPower,length(idx),1);
%                 I(idx) = I(idx) +1;
%                 D(idx) = nansum([(I(idx)-1).*D(idx) avgPower],2)./I(idx);
%             end
%         end
%     end    
% end


%%
sigVind = find(~isnan(D));

% only select faces that have all vertices = significant 
sigF    = find(prod(double(ismember(F,sigVind)),2)==1);

% interp the colors of each sig vertex
X = [V(F(sigF,1),1)';V(F(sigF,2),1)';V(F(sigF,3),1)'];
Y = [V(F(sigF,1),2)';V(F(sigF,2),2)';V(F(sigF,3),2)'];
Z = [V(F(sigF,1),3)';V(F(sigF,2),3)';V(F(sigF,3),3)'];
C_raw = [D(F(sigF,1))';D(F(sigF,2))';D(F(sigF,3))'];

hBrain = patch(X,Y,Z,C_raw,'EdgeColor','none');