function pt =  findSurface(x,pts)
%% Finds the closest point on the surface. It is used in the fmincon
%% optimization technique. More specifically it is called by the constraint
%% function



% LOAD ELLIPSES
pt = zeros(size(x,1),3);

shell = pts;
% keyboard
% tic
% foo = pdist2(x,shell);
% [~,idx] = sort(foo,2);
% 
% pt = shell(idx(:,1),:);
% toc
% tic
parfor k = 1:size(x,1)
    brainShell = shell{k};
    x_temp = x(k,:);
    dist = pdist2(x_temp,brainShell);
    [~,idx] = sort(dist);
    pt(k,:) = brainShell(idx(1),:);
end
% toc