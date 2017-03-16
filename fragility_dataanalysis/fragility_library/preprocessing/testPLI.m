addpath(genpath('/Users/adam2392/Documents/adamli/fragility_dataanalysis/eeg_toolbox/'));
close all
fs = 500;
n = 120*fs; %2-min sequence	
t = 2*pi*(1:n)/fs;
fline = 60 + randn; %ramdom interference frequency
s = filter(1,[1,-0.99],100*randn(1,n)); %1/f PSD
p = 80*sin(fline*t+randn) + 50*sin(2*fline*t+randn)...
  + 20*sin(3*fline*t+randn); % interference	
x = s + p;

sbar = removePLI(x, fs, 3, [60,0.01,4], [0.1,2,5], 3);
pwelch(s,[],[],[],fs); title('PSD of the original signal')
figure; pwelch(x(fs:end),[],[],[],fs); 
title('PSD of the contaminated signal');
figure; pwelch(sbar(fs:end),[],[],[],fs); 
title('PSD after interference cancellation');

figure;
s = filter(1,[1,-0.99],100*randn(1,n)); %1/f PSD
fline = 60;
p = 80*sin(fline*t+randn) + 50*sin(2*fline*t+randn)...
  + 20*sin(3*fline*t+randn); % interference	
x = s + p;
filterx = buttfilt(x,[59.5 60.5], fs,'stop',1);
pwelch(filterx(fs:end), [],[],[], fs);
title('PSD after notch');


