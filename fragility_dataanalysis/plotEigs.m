close all

A_tilda = 0;
count = 0;
% loop through mat files and open them up
for i=35:84
    count = count +1;
    load(strcat('pt1sz2_', num2str(i)));
    rank(theta_adj)
    
    if (i==35)
        A_tilda = theta_adj;
    else
        A_tilda = A_tilda+theta_adj;
    end
        
    
%     figure;
%     plot(eig(theta_adj), 'o');
%     title('Eigenspectrum of A\b=x matrix');
%     xlabel('Real');
%     ylabel('Imaginary');
%     
%     figure;
%     imagesc(theta_adj);
%     colorbar(); colormap('jet');
%     title('Adjacency Matrix');
%     set(gca,'tickdir','out','YDir','normal');
end

A_tildaa = A_tilda/count;
plot(eig(A_tildaa), 'o')