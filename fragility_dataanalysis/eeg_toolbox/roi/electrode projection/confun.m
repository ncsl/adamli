function [ceq, c] = confun(x,pts)
%% constraint function for ellipse optimization. Constraints points to
%% closest point on the brian surface

c = sqrt(sum((x-findSurface(x,pts)).^2,2));
ceq = [];