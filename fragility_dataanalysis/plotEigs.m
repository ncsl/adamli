
% loop through mat files and open them up
for i=35:84
    load(strcat('pt1sz2_', num2str(i)));
    
    figure;
    plot(eig(theta_adj), 'o');
end