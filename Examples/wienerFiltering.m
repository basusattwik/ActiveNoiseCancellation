close all
clearvars
clc

%% Create signals

% Load speech recording
[sn, fs] = audioread('Data/Input/Speech/male.wav');
len = length(sn);

% Generate Gaussian noise
snr_dB = 1; % dB
snr_ln = 10^(snr_dB/10);

vars = var(sn);
varn = vars / snr_ln;
wn = sqrt(varn) * rand(len, 1);

% Noise speech signal
xn = sn + wn;

%% Wiener filter

yn = optimalWienerFilter(xn, sn, fs, 0.020);

%% Plots

winLen  = fix(0.020 * fs); % 20 ms
tx = 0:1/fs:length(yn)/fs-1/fs;

figure(1)
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
