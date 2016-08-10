%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: ResponseFunction
% DESCRIPTION: Used to evaluate the nonlinear response function for
% neuronal inputs s_i(t).
%
% F = function(W*p + h)
%
%
% INPUT:
% - s = the input to nodes
% - beta = some weighting factor on the nonlinear response function
% - link = 'tanh', or 'sigmoid' to decide which nonlinear function to use
% - deriv = 0, 1, 2, to determine whether to use a derivative of the
% response function or not
% OUTPUT:
% - F = the output of nonlinear response function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function F = ResponseFunction(s, beta, link, deriv)

    %%- type of response function
    if (strcmp(link, 'tanh')) % clamped hyperbolic tangent f(s) = max{0, tanh(s)}
        if (deriv == 0)
            F = tanh(s);
            F(s<0) = 0;
        elseif (deriv == 1)
            F = sech(s).^2;
            F(s<0) = 0;
        elseif (deriv == 2)
            F = -2*tanh(s).*sech(s).^2;
            F(s<0) = 0;
        end
    elseif (strcmp(link, 'sigmoid')) % sigmoid tangent f(s) = sigmoid(s)
        if (deriv == 0)
            F = 1./(1+exp(-s));
        elseif (deriv == 1)
            F = exp(-s)./(1+exp(-s)).^2;
        elseif (deriv == 2)
            F = (exp(-2*s)-exp(-s))./(1+exp(-s)).^3;
        end
    end
    
    F = beta.*F; % multiply by weighting factor
end