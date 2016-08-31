% define w0/w and sigma for the frequency range to grid search over
w0 = 2*pi/10;
w = linspace(0, w0, 101); 
% sigma = linspace(0, sigma0, 100);
sigma0 = 1.25 ;
sigma = sigma0 - w; % move to the unit circle 1, for a plethora of different radial frequencies
b = [0; 1];
perturbationType = 'R';
patient = 'pt1sz2';


avge_fragility = [];
close all

A_tilda = 0;
count = 0;

% loop through mat files and open them upbcd
for i=35:84
    count = count +1;
    load(strcat('pt1sz2_', num2str(i)));

    %%- determine which indices have eigenspectrums that are stable
    max_eig = max(abs(eig(theta_adj)));
    if (max_eig < sigma0) % this is a stable eigenspectrum
        N = size(theta_adj, 1); % number of rows
        del_size = zeros(N, length(w));
        del_table = cell(N, length(w));
        fragility_table = zeros(N, 1);
 
        %%- grid search over sigma and w for each row to determine, what is
        %%- the fragility.
        for iNode=1:N
            ek = [zeros(iNode-1, 1); 1; zeros(N-iNode,1)]; % unit vector at this node
            A = theta_adj; 
            
            for iW=1:length(w) % loop through frequencies
                lambda = sigma(iW) + 1i*w(iW);

                % row perturbation inversion
                if (perturbationType == 'R')
                    C = ek'*inv(A - lambda*eye(N));                
                elseif (perturbationType == 'C')
                    C = inv(A - lambda*eye(N))*ek; 
                end
                Cr = real(C);
                Ci = imag(C);
                B = [Ci; Cr];
                
                del = B'*inv(B*B')*b;
                
                del_size(iNode, iW) = norm(del); % store the norm of the perturbation
                del_table{iNode, iW} = del;
            end
            % find column for each row of minimum norm perturbation
            [r, c] = ind2sub([N length(w)], find(del_size == min(del_size(iNode, :))));
            r = r(1); c = c(1);
            ek = [zeros(r-1, 1); 1; zeros(N-r, 1)]; % unit vector at this row
            
            fragility_table(iNode) = del_size(iNode, c);
        end
        
        %%- Plot 
%         figure;
%         subplot(311);
%         titleStr = ['Eigenspectrum of A\b=x for ', patient];
%         plot(eig(theta_adj), 'ko')
%         title(titleStr);
%         xlabel('Real'); ylabel('Imaginary');
%     
%         subplot(312);
%         imagesc(theta_adj); 
%         colorbar(); colormap('jet');
%         xlabel('Electrodes Affecting Other Channels');
%         ylabel('Electrodes Affected By Other Channels');
%         
%         subplot(313);
%         plot(fragility_table, 'ko');
%         title(['Fragility Per Electrode at ', num2str(85-i), ' seconds before seizure']);
%         xlabel(['Electrodes (n=', num2str(N),')']);
%         ylabel(['Minimum Norm Perturbation at Certain w']);
%         
        max_eig
        i
        max(imag(eig(theta_adj)))
        
        avge_fragility = [avge_fragility; mean(fragility_table)];
    end
end
close all;

figure;
plot(avge_fragility, 'ko');
title('Averaged Fragility From 50 seconds to 1 second before Seizure');
xlabel('50 seconds -> 1 second before seizure');
ylabel('Fragility (Minimum Norm Perturbation)');