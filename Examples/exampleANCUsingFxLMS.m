close all
clearvars
clc

% TODO: Create FxLMS class and rearchitect code

%% Define sim constants

fs = 16000; % 16 kHz sampling rate
noiseType = 'tonal';

%% Algorithm Tuning

if strcmpi(noiseType, 'rand')
    mu_fxlms    = 0.025; % for rand
    gamma_fxlms = 0.001;
    normK = 0.001;

elseif strcmpi(noiseType, 'tonal')
    mu_fxlms    = 0.0019;
    gamma_fxlms = 0.00001;
    normK = 0.001;
end

%% Create Transfer Functions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                %
% Primary path transfer function %
%                                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Np     = 800;  % Length of primary path filters: 0.05 sec
flow   = 50;   % Lower band-edge: 80 Hz
fhigh  = 1000; % Upper band-edge: 4000 Hz
delayP = 20;   % Delay before first peak
Ast    = 20;   % 20 dB stopband attenuation
ford   = 8;    % Filter order

priPathCoef = genBandPassTransferFunction(Np, flow, fhigh, delayP, Ast, ford, fs);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                  %
% Secondary path transfer function %
%                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Ns     = 800;  % Length of secondary path filters: 0.05 sec
flow   = 20;   % Lower band-edge: 80 Hz
fhigh  = 2000; % Upper band-edge: 1200 Hz
delayS = 14;   % Delay before first peak
Ast    = 20;   % 20 dB stopband attenuation
ford   = 8;    % Filter order

secPathCoef = genBandPassTransferFunction(Ns, flow, fhigh, delayS, Ast, ford, fs);

% Calculate Frequency domain data
nfft = 2048;

priPathFft = fft(priPathCoef, nfft) / nfft;
secPathFft = fft(secPathCoef, nfft) / nfft;

priPathMag = abs(priPathFft(1:nfft/2+1));
secPathMag = abs(secPathFft(1:nfft/2+1));

priPathMag(2:end-1) = 2 * priPathMag(2:end-1); % Correct mag for one sided view
secPathMag(2:end-1) = 2 * secPathMag(2:end-1);

priPathPhs = angle(priPathFft(1:nfft/2+1));
secPathPhs = angle(secPathFft(1:nfft/2+1));

%% Estimate Secondary Path

%%%%%%%%%%%%%%%%%%%%%%%%
%                      %
% LMS Adaptive Filter  %
%                      %
%%%%%%%%%%%%%%%%%%%%%%%%

mu_lms      = 0.01;
gamma_lms   = 0.001;
filtLen_lms = 512;

% Preallocate zeros
secPathEstCoef  = zeros(filtLen_lms, 1);
secPathEstState = zeros(filtLen_lms, 1);

% Initialize excitation signal
extime = 10; % 10 sec
xex    = randn(fs * extime, 1);

% Filter excitation signal through actual secondary path
xexfilt = filter(secPathCoef, 1, xex);
xexfilt = xexfilt + 0.001 * randn(fs * extime, 1); % add sensor self noise

for i = 1:length(xex)

    % Update state vector
    secPathEstState = [xex(i, 1); secPathEstState(1:end-1, 1)];

    % Get normalization factor
    powx = norm(secPathEstState); % TODO: Add exponential filter
    normstepsize = mu_lms / powx;

    % Get error signal: desired - output
    error = xexfilt(i, 1) - secPathEstCoef.' * secPathEstState;

    % Update est. secondary path filter coefficients
    secPathEstCoef = secPathEstCoef * (1 - normstepsize * gamma_lms) + ...
                                           normstepsize * error * secPathEstState;
end

%% Noise signal

% Create filtered primary noise
noiseTime = 50; % sec

if strcmpi(noiseType, 'rand')
    noise = 0.1 * randn(noiseTime * fs, 1);

elseif strcmpi(noiseType, 'tonal')
    f0 = 100;
    t  = 0:1/fs:(noiseTime)-1/fs;
    A  = [.01 .02 .02];
    k  = 1:length(A);
    
    f  = 100 * k;
    phase = rand(1, length(A)); % Random initial phase
    
    noise = zeros(length(t), 1);
    for i = 1:length(A)
        noise = noise + A(i) * sin(2*pi*f(i)*t + phase(i)).';
    end
end

% Generate primary noise
prinoise = filter(priPathCoef, 1, noise);

%% FxLMS Loop

filtLen_fxlms = 256;

% Preallocate memory
error_fxlms  = zeros(noiseTime * fs, 1);
output_fxlms = zeros(noiseTime * fs, 1);
antinoise    = zeros(noiseTime * fs, 1);
wfiltState   = zeros(filtLen_fxlms, 1);
wfiltCoef    = zeros(filtLen_fxlms, 1);
filtRefState = zeros(filtLen_fxlms, 1);
secPathState = zeros(Ns, 1);
secPathEstState = zeros(filtLen_lms, 1);

for i = 1:length(noise)

    % Update state vector of W filter and calc antinoise
    wfiltState = [noise(i); wfiltState(1:end-1, 1)];
    output_fxlms(i,1) = wfiltCoef.' * wfiltState;

    % Update state vector of actual secondary path and filter antinoise
    secPathState   = [output_fxlms(i,1); secPathState(1:end-1, 1)];
    antinoise(i,1) = secPathCoef.' * secPathState;

    % Calc error i.e. residual noise
    error_fxlms(i,1) = prinoise(i,1) - antinoise(i,1);

    % Get filtered reference signal
    secPathEstState = [noise(i,1); secPathEstState(1:end-1, 1)];
    filtRefOutput   = secPathEstCoef.' * secPathEstState;
    filtRefState    = [filtRefOutput; filtRefState(1:end-1,1)];

    % Normalize stepsize
    powfiltref   = norm(filtRefState); % TODO: add exponential smoothing
    normstepsize = mu_fxlms / (1 + normK * powfiltref);

    % Update W filter coefficients
    wfiltCoef = wfiltCoef * (1 - normstepsize * gamma_fxlms) + ...
                                 normstepsize * error_fxlms(i,1) * filtRefState;
end
 
% Calculate frequency domain data
winLen  = 1024;
overlap = 512;
fftLen  = 2048;

% for residual noise, wait for a few seconds and then compute PSD to ensure
% convergence
waitTime = 10; % sec

[psd_prinoise,  fxx] = pwelch(prinoise, winLen, overlap, fftLen, fs);
[psd_antinoise, ~]   = pwelch(antinoise, winLen, overlap, fftLen, fs);
[psd_error, ~] = pwelch(error_fxlms(waitTime * fs:end, 1), winLen, overlap, fftLen, fs);

%% Generate all plots

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                %
% Plot Actual Primary and Secondary Path Filters %
%                                                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

txp = (1:Np)/fs;  % time axis
txs = (1:Ns)/fs;  % time axis
df  = fs / nfft;  % frequency spacing
fx  = 0:df:fs/2;  % frequency axis

figure(1)
subplot(3, 2, 1)
    plot(txp, priPathCoef);
    grid on; grid minor;
    xlabel('Time [s]');
    ylabel('Amplitude');
    title('Primary Path IR');
subplot(3, 2, 2)
    plot(txs, secPathCoef);
    grid on; grid minor;
    xlabel('Time [s]');
    ylabel('Amplitude');
    title('Secondary Path IR');
subplot(3, 2, 3)
    plot(fx, mag2db(priPathMag));
    grid on; grid minor;
    xlabel('Frequency [Hz]');
    ylabel('Magnitude [dB]');
    title('Magnitude Response');
subplot(3, 2, 4)
    plot(fx, mag2db(secPathMag));
    grid on; grid minor;
    xlabel('Frequency [Hz]');
    ylabel('Magnitude [dB]');
    title('Magnitude Response');
subplot(3, 2, 5)
    plot(fx, priPathPhs);
    grid on; grid minor;
    xlabel('Frequency [Hz]');
    ylabel('Angle [rad]');
    title('Phase Response');
subplot(3, 2, 6)
    plot(fx, secPathPhs);
    grid on; grid minor;
    xlabel('Frequency [Hz]');
    ylabel('Angle [rad]');
    title('Phase Response');
sgtitle('Transfer Function Characteristics');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                      %
% Plot S(z) with S^(z) for comparison  %
%                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plot for comparison S(z) with S^(z)
figure(2)
plot(1:filtLen_lms, secPathEstCoef, 'LineWidth', 1.1); 
hold on
plot(1:filtLen_lms, secPathCoef(1:filtLen_lms), 'LineWidth', 1.1);
xlabel('Samples'); ylabel('Amplitude');
grid on; grid minor;
legend('Estimated', 'Actual');
title('Comparison of Estimated vs Actual Sec. Path IRs');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                   %
% Plot ANC error with Primary Noise for comparison  %
%                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

txx = (1:noiseTime*fs)/fs;
figure(3)
plot(txx, prinoise);
hold on;
plot(txx, -antinoise);
plot(txx, error_fxlms);
grid on; grid minor;
xlabel('time [s]'); ylabel('Amplitude');
legend('Primary Noise', 'Antinoise', 'Residual Noise');
title('Noise Cancellation');

figure(4)
plot(fxx, 10*log10(psd_prinoise), 'LineWidth', 1.1);
hold on;
plot(fxx, 10*log10(psd_antinoise), 'LineWidth', 1.1);
plot(fxx, 10*log10(psd_error), 'LineWidth', 1.1);
grid on; grid minor;
xlabel('Frequency [Hz]'); ylabel('Power [dB]');
legend('Primary Noise', 'Antinoise', 'Residual Noise');
title('Noise Cancellation Spectrum');

%% Write Audio to disk

if strcmpi(noiseType, 'rand')
    audiowrite('noiseAncOff_rand.wav', prinoise ./ max(abs(prinoise)), fs);
    audiowrite('noiseAncOn_rand.wav', error_fxlms ./ max(abs(error_fxlms)), fs);
elseif strcmpi(noiseType, 'tonal')
    audiowrite('noiseAncOff_tonal.wav', prinoise ./ max(abs(prinoise)), fs);
    audiowrite('noiseAncOn_tonal.wav', error_fxlms ./ max(abs(error_fxlms)), fs);
end