% function:
% To build a time varying compartmental model for a dendrite tree. This
% builds it for 1 dendrite branch and can be called multiple times to build
% A for each dendrite.
% 
% 
function A = buildTimeVaryingCompartment(Gm, Gi, Cm, n, d0, a, delta_x)
    % membrance conductance
    gm = Gm * (pi*d0*exp(-a.*index*delta_x)) * delta_x; % conducatnace
    
    % axial conductance
    gi = Gi * pi * (d0/2*exp(-a.*index*delta_x)).^2 / (delta_x); % constant axial conductance
    
    A = zeros(n,n);
    % create A matrix
    A(1,1) = -(gm(1) + gi(2)) / Cm;
    A(1,2) = gi(2) / Cm;
    for j=2:n-1
        A(j, j-1) = gi(j) / Cm;
        A(j, j)   = -(gi(j) + gm(j) + gi(j+1)) / Cm;
        A(j, j+1) = gi(j+1) / Cm;
    end
    A(n,n-1) = gi(n) / Cm;
    A(n,n)   = - (gi(n) + gm(n)) / Cm;
end