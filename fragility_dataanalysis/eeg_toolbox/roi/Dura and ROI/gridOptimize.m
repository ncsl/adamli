function x2 = gridOptimize(v,grid)

% v_center = (v(f(:,1),:) + v(f(:,2),:) + v(f(:,3),:))/3;
% v_new = [v_center;v];
v_new = v(abs(v(:,2)-grid(1,2))<=3,:);

options = optimset('Algorithm','interior-point','Display','iter','MaxFunEvals', inf,'MaxIter',50,'TolCon',1e-3,'TolFun',1e-1,'UseParallel','always');

x1 = grid;
d0 =  findDistMat_grid(grid,1);
a = alphaMake_grid(x1);
x0 = x1;


tic
x2 = fmincon(@(x)objfun_grid(x,x0,d0,a),x1,[],[],[],[],[],[],@(x)confun_grid(x,v_new,grid(1,2)),options);
toc
