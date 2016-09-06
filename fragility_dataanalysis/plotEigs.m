% define w0/w and sigma for the frequency range to grid search over
w0 = 1;
w = linspace(-1, w0, 101); 
% sigma = linspace(0, sigma0, 100);
sigma0 = 1.1;
sigma = sqrt(sigma0 - w.^2); % move to the unit circle 1, for a plethora of different radial frequencies
b = [0; 1];
perturbationType = 'R';
patient = 'pt1sz2';
included_channels = [1:36 42 43 46:54 56:69 72:95];

% define epileptogenic zone
fid = fopen('./data/pt1sz2/pt1sz2_labels.csv');
labels = textscan(fid, '%s', 'Delimiter', ',');
labels = labels{:}; labels = labels(included_channels);
fclose(fid);
ezone_labels = {'POLPST1', 'POLPST2', 'POLPST3', 'POLAD1', 'POLAD2'};

% define cell function to search for the EZ labels
cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));
ezone_indices = zeros(length(ezone_labels),1);
for i=1:length(ezone_labels)
    indice = cellfun(cellfind(ezone_labels{i}), labels, 'UniformOutput', 0);
    indice = [indice{:}];
    test = 1:length(labels);
    ezone_indices(i) = test(indice);
end

avge_fragility = [];
close all

A_tilda = 0;
count = 0;

frag_time_chan = zeros(size(theta_adj, 1), length(35:84));
colsum_time_chan = zeros(size(theta_adj, 1), length(35:84));
rowsum_time_chan = zeros(size(theta_adj, 1), length(35:84));

% loop through mat files and open them upbcd
iTime = 1;
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
            
            % store fragility, for each node at a certain time point
            frag_time_chan(iNode, iTime) = min(del_size(iNode,:));
            
            % find column for each row of minimum norm perturbation
            [r, c] = ind2sub([N length(w)], find(del_size == min(del_size(iNode, :))));
            r = r(1); c = c(1);
            ek = [zeros(r-1, 1); 1; zeros(N-r, 1)]; % unit vector at this row
            
            fragility_table(iNode) = del_size(iNode, c);
        end % end of loop through channels
        
        % store col/row sum of adjacency matrix
        colsum_time_chan(:, iTime) = sum(theta_adj, 1);
        rowsum_time_chan(:, iTime) = sum(theta_adj, 2);
        
        % update pointer for the fragility heat map
        iTime = iTime+1;
        
        %%- Plot 1 time point
%         figure;
%         subplot(311);
%         titleStr = ['Eigenspectrum of A\b=x for ', patient];
%         plot(eig(theta_adj), 'ko'); hold on;
%         plot(sigma, w, 'ro')
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
        
        max_eig
        i
        max(imag(eig(theta_adj)))
        
        avge_fragility = [avge_fragility; mean(fragility_table)];
    end
end

%%- PLOT THE HEATMAP OF FRAGILITY 
figure;
imagesc(frag_time_chan);
colorbar(); colormap('jet');
title('Fragility From 50 to 1 Seconds Before Seizure For All Chans');
xlabel('Time 50->1 Second');
ylabel('Channels');

for i=1:length(ezone_labels)
    plot(get(gca, 'xlim'), [ezone_labels(i)-0.5 ezone_labels(i)-0.5], 'k');
    plot(get(gca, 'xlim'), [ezone_labels(i)+0.5 ezone_labels(i)+0.5], 'k');
end

figure;
imagesc(colsum_time_chan);
colorbar(); colormap('jet');
title('Column Sum From 50 to 1 Seconds Before Seizure For All Chans');
xlabel('Time 50->1 Second');
ylabel('Channels');

figure;
imagesc(rowsum_time_chan);
colorbar(); colormap('jet');
title('Row Sum From 50 to 1 Seconds Before Seizure For All Chans');
xlabel('Time 50->1 Second');
ylabel('Channels');

figure;
plot(avge_fragility, 'ko');
title('Averaged Fragility From 50 seconds to 1 second before Seizure');
xlabel('50 seconds -> 1 second before seizure');
ylabel('Fragility (Minimum Norm Perturbation)');