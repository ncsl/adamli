function Data = Simulation(alpha, beta, W, P, h, t_end, bin_delta, link)
t_end

N = length(P);

rand('twister', sum(97*clock));

if (islogical(P))
    x0 = P;
else
    x0 = logical(rand(N,1) <= P);
end

times = [];
index = [];
type = [];

t = 0;
x = x0;

while (t < t_end)

    r = ResponseFunction(beta, (W*x)+h, link, 0);
    r(x) = alpha;

    dt = -log(rand)/sum(r);
    i = find(cumsum(r)/sum(r) >= rand, 1);

    x(i) = ~x(i);
    t = t+dt;

    times = [times t];
    index = [index i];
    type = [type x(i)];
end

times = times(1:end-1);
index = index(1:end-1);
type = logical(type(1:end-1));
rasterx = ceil(times(type)/bin_delta);
rastery = index(type);

rate = histc(rasterx, 0:1/bin_delta:t_end/bin_delta)/N;
win = gausswin(301,3);                          % Gaussian window, sig = 50ms, window length = 6*sigma
win = win/sum(win);                             % normalize filter
rate = conv(win, rate);                         % apply Gaussian smoothing
rate = rate(151:(length(rate)-150));            % trim edge effects

p = zeros(N,1);
fr = zeros(N,1);

for i = 1:N
    atimes = times(type==1 & index==i);
    qtimes = times(type==0 & index==i);
    if (~isempty(atimes))
        if (qtimes(1) < atimes(1))
            atimes = [0 atimes];
        end
        if (atimes(end) > qtimes(end))
            qtimes = [qtimes t_end];
        end
        fr(i) = 1/mean(diff(atimes));
        p(i) = sum(qtimes-atimes)/t_end;
    end
end

Data.times = times;
Data.index = index;
Data.type = type;
Data.init = x0;
Data.final = x;
Data.rasterx = rasterx;
Data.rastery = rastery;
Data.rate = rate;
Data.p = p;
Data.fr = fr;

end
