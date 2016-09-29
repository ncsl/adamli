function pt =  findSurface_grid(x,v_center,y)
%% Finds the closest point on the surface. It is used in the fmincon
%% optimization technique. More specifically it is called by the constraint 
%% function


alpha =.5;
locale = v_center(abs(v_center(:,2)-y)< alpha,:);

d = pdist2(x,locale);
[~,idx] = sort(d,2);
pt = locale(idx(:,1),:);
pt = (pt+x)/2;


% parfor k = 1:size(x,1)
%     x_temp = x(k,:);
%     x_temp = repmat(x_temp,size(locale,1),1);
%     dist = locale-x_temp;
%     dist = dist.^2;
%     dist = sum(dist,2);
%     dist = sqrt(dist);
%     [~,idx] = sort(dist);
%     pt(k,:) = locale(idx(1),:);
% end
% toc