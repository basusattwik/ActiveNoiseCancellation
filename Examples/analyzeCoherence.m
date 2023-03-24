close all force
clearvars
clc

%% Setup
load('Data/Input/MATFiles/ancSimInput_OneSource.mat');

winLen  = 3072;
overlap = 0.5 * winLen;
fftLen  = 4096;

fs  = ancSimInput.config.fs;
len = fs * ancSimInput.simTime;

noise = ancSimInput.noiseSource;

%% Measure Coherence

% Signal at Reference Mic
refPathFilt = ancSimInput.refPathFilters{1, 1};
xref = refPathFilt(noise);

% Signal at Error Mic
priPathFilt = ancSimInput.priPathFilters{1, 1};
xerr = priPathFilt(noise);

cohRefNoise = mscohere(xref, noise, hamming(winLen), overlap, fftLen, fs);
cohRefErr   = mscohere(xref, xerr, hamming(winLen), overlap, fftLen, fs);

%% Plots

df = fs/fftLen;
fx = 0:df:fs/2;
tx = 0:1/fs:ancSimInput.simTime-1/fs;

[refPathFft, fxx] = freqz(refPathFilt, fftLen, fs);
[priPathFft, ~]   = freqz(priPathFilt, fftLen, fs);

figure(1)
plot(tx, noise); hold on;
plot(tx, xref);
plot(tx, xerr);
grid on; grid minor;
xlabel('Time (s)'); 
ylabel('Amplitude');
legend('Noise', 'Reference', 'Error');

figure(2)
subplot(2,1,1)
    plot(fx, cohRefNoise, 'LineWidth', 1.1); hold on;
    ylabel('Mag. Squared Coherence');
    xlim([0 1000]);
    yyaxis right
    plot(fxx, mag2db(abs(refPathFft)), 'LineWidth', 0.9);
    ylabel('Magnitude (dB)');
    xlabel('Frequency (Hz)');
    xlim([0 1000]); %ylim([-60 2]);
    title('Noise Source & Reference Mic');
    legend('', 'Ref. Path Filter', 'Location', 'best');
    grid on; grid minor;
subplot(2,1,2)
    plot(fx, cohRefErr, 'LineWidth', 1.1);
    ylabel('Mag. Squared Coherence');
    yyaxis right
    plot(fxx, mag2db(abs(refPathFft)), 'LineWidth', 0.9); hold on;
    plot(fxx, mag2db(abs(priPathFft)), 'LineWidth', 0.9);
    ylabel('Magnitude (dB)');
    xlabel('Frequency (Hz)');
    xlim([0 1000]);
    title('Error Mic & Reference Mic');
    legend('', 'Ref. Path Filter', 'Pri. Path Filter', 'Location', 'best');
    grid on; grid minor;
sgtitle('Coherence');