function f = objfun(x,x0,d0,a)
%% objective function that tries to minimize distortions from the
%% equilibrium position defined by x0 and d0
d = findDistMat(x);
y = sum(sum((x-x0).^2,2));
z = sum(sum((a.*(d-d0).^2),2));

lambda = 1;
f = y+z*lambda;
