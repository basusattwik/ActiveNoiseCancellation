close all
clearvars
clc

%% Create signals

% Load speech recording
[sn, fs] = audioread('Data/Input/Speech/male.wav');
len = length(sn);

% Generate Gaussian noise
SNR = 6; % dB
snr = 10^(SNR/10);

vars = var(sn);
varn = vars / snr;
wn = sqrt(varn) * rand(len, 1);

% Noise speech signal
xn = sn + wn;

%% Wiener filter

winLen  = 2 * fix(0.030 * fs); % 30 ms Note: We use double the required window length because this helps in the xcorr calculations
fftLen  = winLen * 2;
winType = 'rect';
overlap = winLen * 3/4;

[~, ~, ~, ~, xframe]      = getStft(xn, fs, winLen, winType, overlap, fftLen);
[~, ~, ~, padLen, sframe] = getStft(sn, fs, winLen, winType, overlap, fftLen);
numFrame = size(xframe, 2);

yframe = zeros(winLen/2, numFrame);
for n = 1:numFrame
    
    xbuff  = hann(winLen, 'periodic') .* xframe(:,n);
    sbuff  = hann(winLen, 'periodic') .* sframe(:,n);

    xbuffchunk = hann(winLen/2, 'periodic') .* xframe(1:winLen/2,n);

    [rxx, l] = xcorr(xbuffchunk, xbuff, winLen);
    rxx = rxx(l >= 0 & l < winLen/2) ./ (winLen/2);
    
    rxs = xcorr(xbuffchunk, sbuff, winLen);
    rxs = rxs(l >= 0 & l < winLen/2) ./ (winLen/2);

    Rxx  = toeplitz(rxx);
    wopt = Rxx \ rxs; % Optimal filter

    yframe(:,n) = filter(wopt, 1, xbuffchunk);

end

yn = getInvStft(yframe, winLen/2, 'hann', winLen/4, winLen/4, 0, true);

%% Plots

tx = 0:1/fs:length(yn)/fs-1/fs;

figure(1)
plot(wopt);
xlabel('taps');
ylabel('Amplitude');
grid on; grid minor;
title('Wiener Filter');

figure(2)
freqz(wopt, 1, fftLen, fs);

figure(3)
ax1 = subplot(2,1,1);
    plot(tx, xn(1:length(yn)));
    xlabel('Time (s)');
    ylabel('Amplitude');
    grid on; grid minor;
    title('Noisy Speech');
ax2 = subplot(2,1,2); 
    plot(tx, yn);
    xlabel('Time (s)');
    ylabel('Amplitude');
    grid on; grid minor;
    title('Filtered Speech');
linkaxes([ax1, ax2], 'xy');
figure(4)
getStft([xn(1:length(yn)), yn], fs, winLen, winType, overlap, fftLen);
