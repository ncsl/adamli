function [ceq, c] = confun_grid(x,v_new,y)
%% constraint function for ellipse optimization. Constraints points to
%% closest point on the brian surface
c = sqrt(sum((x-findSurface_grid(x,v_new,y)).^2,2)) -3;
ceq = [];