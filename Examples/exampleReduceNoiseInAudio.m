close all; clearvars; clc

%% Setup

% load audio
[audio, fs] = audioread('Data/Music/pop.wav');
audioLen    = length(audio);

% Create random noise
rng('default');
x = 0.1 * randn(audioLen, 1);

% Create bandpass filter
ord = 128;
lcf = 1000; 
hcf = 3000;
h   = fir1(ord, [lcf hcf] ./ (0.5 * fs));

xfilt = filter(h, 1, x);
d     = 0 * audio + xfilt;

%% Run adaptive filter

% Create LMS object
lms = sysLMS('numSpk',     1, ...
             'numErr',     1, ...
             'stepsize',   0.8, ...
             'leakage',    0.00001, ...
             'normweight', 10, ...
             'smoothing',  0.997, ...
             'filterLen',  ord + 1,...
             'bfreezecoeffs', false);

% Preallocate memory
e = zeros(audioLen, 1);
y = zeros(audioLen, 1);

% Simulate
for n = 1:audioLen
    lms(x(n,1), d(n,1));
    e(n,1) = lms.error;
    y(n,1) = lms.output;
end
w = squeeze(lms.coeffs);

%% Generate plots
tx = 0:1/fs:audioLen/fs-1/fs;

figure(1)
subplot(4, 1, 1)
    plot(tx, xfilt);
    grid on; grid minor;
    xlabel('time (s)');
    ylabel('Amplitude');
    title('Reference');
subplot(4, 1, 2)
    plot(tx, d);
    grid on; grid minor;
    xlabel('time (s)');
    ylabel('Amplitude');
    title('Noisy Audio');
subplot(4, 1, 3)
    plot(tx, e);
    grid on; grid minor;
    xlabel('time (s)');
    ylabel('Amplitude');
    title('Error i.e. Filtered Audio');
subplot(4, 1, 4)
    plot(tx, audio);
    grid on; grid minor;
    xlabel('time (s)');
    ylabel('Amplitude');
    title('Original Audio');

figure(2)
stem(h); hold on;
stem(w);
xlabel('sample'); ylabel('amplitude');
grid on; grid minor;
title('Impulse Response Coeffs');
legend('Actual', 'Adaptive');

%% Close
reset(lms);
delete(lms);