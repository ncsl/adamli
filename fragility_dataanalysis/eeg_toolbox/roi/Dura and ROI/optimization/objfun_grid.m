function f = objfun_grid(x,x0,d0,a)
%% objective function that tries to minimize distortions from the
%% equilibrium position defined by x0 and d0

% if exist('/Users/damerasr/Sri/Matlab Analysis/All Purpose/VisualizeTask/Grid/Ellipse Contours/d0.mat','file')
%     
% else
%     save('/Users/damerasr/Sri/Matlab Analysis/All Purpose/VisualizeTask/Grid/Ellipse Contours/d0.mat','d0')
%     d = findDistMat_grid(x,0);
% end
d = findDistMat_grid(x,1);
y = sum(sum((x-x0).^2,2));
z = sum(sum((a.*(d-d0).^2),2));
% disp(['z_old: ' num2str(z)]);
% disp(['y_old: ' num2str(y)]);
if y ~= 0 && z~=0
    foo = floor(log10(z));
    foo2 = round(log10(y))-foo;
    y = y/10^foo2;
end
% disp(['z_new: ' num2str(z)]);
% disp(['y_new: ' num2str(y)]);

alpha = 1;
f = y+z*alpha;