%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       ex: computeDTFandPDC
% function: computeDTFandPDC
%
%--------------------------------------------------------------------------
%
% Description:  For a given MVAR model matrices, compute the partial
% directed coherence and directed transfer function at different
% frequencies.
% 
%
%--------------------------------------------------------------------------
%   
%   Input: 
%   1. A: 
%   2. p_opt:
%   3. fs: sampling frequency
%   4. Nf: Number of frequency bins to make
% 
%   Output:
%   1. DTF:
%   2. PDC: 
%                          
%--------------------------------------------------------------------------
% Author: Adam Li
% Reference: http://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=5931445
%
%
% Ver.: 1.0 - Date: 11/23/2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [DTF, PDC] = computeDTFandPDC(A, p_opt, fs, Nf)
    [CH, ~, T] = size(A); % number of channels and number of time points
    
    DTF = zeros(CH, CH, Nf, T); % Directed Transfer Function
    PDC = zeros(CH, CH, Nf, T); % Partial Directed Coherence Function
    H = zeros(CH,CH,Nf);
    
    f = (0:Nf-1)*(fs/2/Nf);
    z = 1i*2*pi/fs;
    
    for iTime=1:T % loop through number of time points
        % create time transformed matrix
        A2 = [eye(CH) - squeeze(A(:,:,t))]; % A2(f) = [I - A1(t) - A2(t) - ... - Ap(t)];
        
        %% Partial Directed Coherence
        for iN=1:Nf % loop through frequency points
            % matrix A(f) -> Summation of AR coefficients matrix in freq.
            Af = zeros(CH);
            for k=1:p_opt+1 % loop through each order
                Af = Af + A2(:, k*CH + (1-CH:0)) * exp(z*(k-1)*f(iN);
            end
            
            % compute PDC Function
%             denom_PDC = zeros(CH, CH);
            for ch=1:CH % loop through each channel
                tmpAf = squeeze(Af(:,ch)); % ith columno f A(f) --> a_j
                denom_PDC(ch) = sqrt(tmpAf'*tmpAf); 
            end
            
            PDC(:,:,iN,iTime) = abs(Af) ./ denom_PDC;
            
            % compute H(f) = Af^(-1) for DTF
            H(:, :, iN) = inv(Af);
        end
        
        %% Directed Transfer Function
        for chi=1:CH % loop through channels for i
            denom_DTF = sum(abs(H(chi, :, :)).^2, 2); % sum((Hij, j).^2)
            
            for chj=1:CH % loop through channels again for j
                % compute Directed Transfer Function
                DTF(chi, chj, :, iTime) = abs(H(chi, chj,:)) ./ sqrt(denom_DTF);
            end
        end
    end
end