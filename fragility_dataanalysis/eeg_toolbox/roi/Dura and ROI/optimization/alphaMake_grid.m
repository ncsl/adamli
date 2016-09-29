function alpha = alphaMake_grid(grid)

%% Constructs alpha matrix(connectivity matrix) for each set of patients electrodes
foo = ones(size(grid,1)-1,1);
alpha =  diag(foo,1);
alpha(size(alpha,1),1) = 1;

