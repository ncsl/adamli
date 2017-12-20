function [powMT freqs_FFT t_sec phsMT] = eeg_mtwelch2(eegTrialsxTime,Fs,T,overlap,TW,mtFreqOut,varargin)
%
%eeg_mtwelch
%Written by: Julio I. Chapeton
%
%Calculates the spectrum and t-f representation of a signal using a short time fourier transform (STFT).
%These can be calculated with multitapers, no tapers, or a Hann taper. The spectrum is produced by averaging the STFTs.
%The t-f representation is calculated using multitapers at each STDFT. The amplitdues and power are scaled correctly for all cases except for multitapers
%
%Usage:
%eeg_mtwelch(eeg,Fs,T,overlap,TW,varargin)
%
%Inputs:
%    Required:
%        eeg      = matrix (trials x time)
%        Fs       = scalar (sampling frequency in Hz)
%        T        = scalar (size of the time window in seconds)
%        overlap  = scalar (size of overlap for adjacent windows, as a fraction of T)
%        TW       = scalar (time-bandwidth product, 2*TW-1 will be the number of tapers)
%        freqOut  = vector (range of output frequencies), pass in empty matrix [] for full freqs_FFT output
%   Optional:
%        method   = string ('no tapers' uses rectangular windows,'eigen' will average the...
%                          power over tapers using the eigenvalues as weights,'Hann' uses a Hann window, may change this to be the default)
%
%Outputs:
%        powMT    = matrix (trial x freq x timestep, power has been normalized to conserve the energy in the signal)
%        phsMT    = matrix (trial x freq x timestep, phase from first taper)
%        freqs_FFT= vector (vector of frequencies in Hz where the power was calculated)
%        t_sec    = matrix (window start/stop times)
%  --following are no longer output now that eeg is trials x time--
%        fx       = array  (contains the power of the windowed data, of the form (freq x window x taper) i.e. not averaged over tapers yet)
%        SP       = vector (spectrum up to Fnyquist, these are normalized to give the correct amplitudes in Volts)
%        all_phase=        (Not set yet)
%
%
% JW 2015-- tweaked the comments a bit and added a detrending step before windowing (as is done by Fries)
%          version eeg_mtwelch2 --> takes in eegTrialxTime
%


%- eegTrialxTime should have rows=trials, columns=time
%-  But for backwards compatability allow user to pass in a single trial time series as row or column
NeegSample = size(eegTrialsxTime,2);
if NeegSample==1, eegTrialsxTime = eegTrialsxTime'; end
NeegTrials = size(eegTrialsxTime,1);
NeegSample = size(eegTrialsxTime,2);


%- FFT setup
Nsamples      = round(T*Fs); % if odd, Nyquist component is not evaluated
ovrlp_samples = round(overlap*Nsamples);
% ovrlp_samples = floor(overlap*Nsamples);
freqs_FFT     = linspace(0,Fs/2,Nsamples/2+1);


if isempty(TW)
    TW=1;
end
no_tapers = 2*TW-1; % TW must be multiple of 1/2
if no_tapers<1 || no_tapers>Nsamples
    error('\n there are m DPSSs of length Nsamples, so require the number of tapers <= to the number of samples per window',[])
end

taper_ind=1;
V_weights=1;
if ~isempty(varargin) && ~strcmp(varargin{1},'tapers')
    if strcmp(varargin{1},'eigen')
        %[E V]=dpss(Nsamples,no_tapers/2); % divide by 2 since dpss calculates 2*(x) tapers
        [E V]=dpss(Nsamples,TW,no_tapers); % JHW divide by 2 since dpss calculates 2*(x) tapers
        V_weights=ones(1,ovrlp_samples>0,length(V));
        V_weights(1,1,:)=V/sum(V);
    elseif strcmp(varargin{1},'no tapers')
        no_tapers=1;
        E=ones(Nsamples,1);
        taper_ind=0;
        % reduces to welch's method --- rectangle window
    elseif strcmp(varargin{1},'Hann')
        no_tapers=1;
        E=hann(Nsamples);
        % welch's with Hann window --- smooths to zero at the edges (first taper of multipaer is more like a Hamm then a Hann window)
    else
        fprintf('\n ERROR: method not correctly specified'); keyboard;
    end
else
    %[E V]=dpss(Nsamples,no_tapers/2); % divide by 2 since dpss calculates 2*(x) tapers
    [E V]=dpss(Nsamples,TW,no_tapers); % JHW divide by 2 since dpss calculates 2*(x) tapers
    %E=dpss(N,bandwidth,K,'calc');
end

% coherent gain factors for amplitude and energy
taper_amp_norm=(1-(taper_ind && no_tapers==1))+(taper_ind && no_tapers==1)/mean(E(:));
taper_pow_norm=(1-(taper_ind && no_tapers==1))+(taper_ind && no_tapers==1)/rms(E(:));



% tic
% [Pxx F]=pmtm(eeg,3,[],Fs);
% toc

% pmtm is too slow

%- Loop over trials and compute the spectra
for iTrial=1:NeegTrials,
    
    eeg = eegTrialsxTime(iTrial,:)'; %- create column vector of this trial's time series
    
    %% split signal into windows and apply tapers to each one
    %eeg_windowed = buffer(eeg,Nsamples,ovrlp_samples,'nodelay');
    [eeg_windowed, rem] = buffer(eeg,Nsamples,ovrlp_samples,'nodelay'); %- starts at first sample (nodelay option), and tosses out samples at end if final window is not filled (rem output contains partial)
    eeg_windowed = repmat(detrend(eeg_windowed),[1,1,no_tapers]); %this should be changed to use bsxfun instead  %- JHW added detrend based on Fries methods... no obvious effect
    windows    = size(eeg_windowed,2);
    E_windowed = permute(repmat(E,[1,1,windows]),[1 3 2]);
    
    %- only need to compute t_sec once
    if iTrial==1,
        t_sec    = nan(windows,2);
        t_sec(:) = [((1:windows)-1)*(Nsamples-ovrlp_samples),((1:windows)*(Nsamples-ovrlp_samples)+ovrlp_samples)]/Fs;
    end
    
    
    %% get coefficients, power and phases
    % freq x window x taper
    fx = fft(E_windowed.*eeg_windowed);
    fx = fx(1:length(freqs_FFT),:,:)/sqrt(Nsamples); %%% unitary scaling, this is the fft (freqs x windows x tapers). Can use this as an output instead of all_pow
    
    all_pow   = (fx.*conj(fx));%*(dt.^2);
    all_pow   = [all_pow(1,:,:);2*all_pow(2:Nsamples/2,:,:);all_pow(end,:,:)];
    all_phase = angle(fx); % not correct (says julio... jw think's its ok)
    
    
    %figure(1); clf; 
    %subplot(211); semilogy(squeeze(all_pow(:,1,:))); hold on; loglog(mean(squeeze(all_pow(:,1,:)),2),'k','linewidth',4); 
    %subplot(212); plot(squeeze(all_phase(:,1,:))); hold on; 
    %meanPhase = squeeze(angle(mean(exp(1i*all_phase(:,1,1)).*conj(exp(1i*all_phase(:,1,2))))));
    %meanPhase = squeeze(angle(sum(exp(1i*all_phase(:,1,:)),3)/size(all_phase,3)));
    %meanPhaseAve = squeeze(angle(mean(exp(1i*all_phase(:,1,1)),3)));
    %plot(meanPhaseAve,'k','linewidth',4)
    %meanPhaseSum = squeeze(angle(sum(exp(1i*all_phase(:,1,:)),3)/size(all_phase,3)));
    %plot(meanPhaseSum,'r','linewidth',4)
    
    
    %% mean phase (in rad), amplitude (in Volts) and power (in Volts^2)
    % The energy and amplitudes are properly scaled in the case of one taper, for multitapers the scale is somewhat arbitrary
    
    % average over tapers, weighted by eigen values if varargin{1}='eigen'.
    tf = mean(bsxfun(@times,all_pow,V_weights),3); % will average only if there is a third dim, i.e tapers. This line may not work if there data is not windowed.
    
    % average over windows and scale amplitude
    SP = mean(tf,2);
    SP = [sqrt(SP(1));sqrt(2*SP(2:Nsamples/2));sqrt(SP(end))]/sqrt(Nsamples)*(taper_amp_norm);
    
    % the division by (Nsamples*windows/N) in tf is there to account for
    % windowing, it is not used in SP since SP is an average over all windows,
    % i.e amplitudes for windows aren't added. This is an approximation and may
    % not be useful
    tf = (tf*taper_pow_norm.^2);%/(Nsamples*windows/N);
    
    %- only save trial-by-trial: time x frequency data
    %[fx SP tf freqs_FFT t_sec all_phase]
    %fx_out(iTrial,:,:,:)=fx;  % freq x window x taper
    %SP_out(iTrial,:)=SP;  % vector (spectrum up to Fnyquist
    powMT(iTrial,:,:)=tf; % freq x time
    %all_phase(iTrial,:,:
    
    phsMT(iTrial,:,:)=all_phase(:,:,1); % freq x time x tapers time x freq (only use the first taper... or perhaps use complex average?)
    %phsMT(iTrial,:,:)=squeeze(angle(mean(exp(1i*all_phase(:,:,:)),3))); % mean phase of all tapers in the complex plane; freq x time output
end

if length(mtFreqOut)>0,
    
    if length(setdiff(mtFreqOut,freqs_FFT))>0, fprintf('\n Error: requesting a multitaper frequency that isnt computed'); keyboard; end
    
    [~,~,iFout] = intersect(mtFreqOut,freqs_FFT);
    powMT       = powMT(:,iFout,:); %- trial x freq x time
    phsMT       = phsMT(:,iFout,:); %- trial x freq x time
    freqs_FFT   = freqs_FFT(iFout);  %- freqs
end


%fx = fx_out;
%SP = SP_out;
%powMT = tf_out;
%all_phase -- not set yet anyway
