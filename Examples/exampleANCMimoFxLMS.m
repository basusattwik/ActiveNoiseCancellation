close all
clearvars
clc

%% Setup

fs = 4000; % 4 kHz sampling rate
noiseType = 'tonal';
boolMeasureSecPath = false;

stepFxlms = 20;
leakFxlms = 0.00001;
normK     = 0.01;
numIrTaps = 200;
noiseTime = 30; % sec


%% Create Transfer Functions

disp('Generating Room Impulse Responses...');

roomDim  = [4, 3, 2];                % Room dimensions    [x y z] (m)
sources  = [2, 3.5, 2];              % Source position    [x y z] (m)
refmics  = [3, 0.1, 2; 3, 0.1, 2.1]; % Reference mic position [x y z] (m)
errmics  = [3, 1.5, 2; 3, 1.8, 2];   % Error mic position [x y z] (m)
speakers = [3, 3.5, 2; 3, 3.8, 2];   % Speaker position   [x y z] (m)
numtaps    = 300;                    % Number of samples
soundspeed = 340;                    % Speed of sound in (m/s)
reverbtime = 0.1;                    % Reverberation time (s)

% Primary Paths: Source to Error Mics
priPathParams.fs     = fs;
priPathParams.srcPos = sources;           
priPathParams.micPos = errmics;          
priPathParams.c      = soundspeed;         
priPathParams.beta   = reverbtime;         
priPathParams.n      = numtaps;                  
priPathParams.L      = roomDim;             

priPathFilt = genRirFilters(priPathParams);

% Secondary Paths: Speakers to Error Mics
secPathParams.fs     = fs;
secPathParams.srcPos = speakers; 
secPathParams.micPos = errmics; 
secPathParams.c      = soundspeed;         
secPathParams.beta   = reverbtime;         
secPathParams.n      = numtaps;                  
secPathParams.L      = roomDim;             

secPathFilt = genRirFilters(secPathParams);

% Reference Paths: Source to Reference Mics
refPathParams.fs     = fs;
refPathParams.srcPos = sources;  
refPathParams.micPos = refmics; 
refPathParams.c      = soundspeed;         
refPathParams.beta   = reverbtime;         
refPathParams.n      = numtaps;                  
refPathParams.L      = roomDim;             

refPathFilt = genRirFilters(refPathParams);

%% Estimate Secondary Path

% System setup
numSrc = size(sources,  1);  % Number of sources
numRef = size(refmics,  1);  % Number of reference mics
numSpk = size(speakers, 1);  % Number of antinoise speakers
numErr = size(errmics,  1);  % Number of error mics

%%%%%%%%%%%%%%%%%%%%%%%%
%                      %
% LMS Adaptive Filter  %
%                      %
%%%%%%%%%%%%%%%%%%%%%%%%

if ~boolMeasureSecPath
    secPathEstCoef = zeros(numSpk, numErr, numIrTaps);
    for spk = 1:numSpk
        for err = 1:numErr
            secPathEstCoef(spk, err, :) = secPathFilt{spk, err}.Numerator(1:numIrTaps);
        end
    end
else
    disp('Measuring secondary path impulse responses...');
    % Initialize excitation signal
    extime = 10; % 10 sec
    randNoise = randn(fs * extime, numSpk);
    
    % Setup LMS system object
    lmsSysObj = classLMSFilter('numSpk', numSpk, 'numErr', numErr, 'stepsize', 0.04, 'leakage', 0.001, 'normweight', 1, 'smoothing', 0.97, 'filterlen', numIrTaps);
    
    % Adaptively estimate secondary paths
    xexfilt = zeros(1, numErr);
    for i = 1:length(randNoise)
    
        % Simulate secondary path
        for err = 1:numErr
            for spk = 1:numSpk
                xexfilt(1, err) = xexfilt(1, err) + secPathFilt{spk, err}(randNoise(i, spk));
            end
        end
    
        % Call LMS algorithm 
        lmsSysObj.step(randNoise(i,:), xexfilt);
        xexfilt(:) = 0;
    end
    secPathEstCoef = lmsSysObj.coeffs;
end

%% Noise signal

% Create primary noise at the source
if strcmpi(noiseType, 'rand')
    noise = 0.1 * randn(noiseTime * fs, 1);

elseif strcmpi(noiseType, 'tonal')

    f0 = 150;
    t  = 0:1/fs:(noiseTime)-1/fs;
    A  = [.01 .02 .02];
    k  = 1:length(A);
    
    f  = 100 * k;
    phase = rand(1, length(A)); % Random initial phase
    
    sigLen = length(t);
    noise = zeros(sigLen, 1);
    for i = 1:length(A)
        noise = noise + A(i) * sin(2*pi*f(i)*t + phase(i)).';
    end
end

%% FxLMS Loop

disp('Running FxLMS ANC simulation...');

% Preallocate memory
saveError      = zeros(noiseTime * fs, numErr);
outputFxlms    = zeros(noiseTime * fs, numSpk);
saveAntinoise  = zeros(noiseTime * fs, numErr);
savePrinoise   = zeros(noiseTime * fs, numErr);
saveReference  = zeros(noiseTime * fs, numRef);
primaryFxlms   = zeros(1, numErr);
errorFxlms     = zeros(1, numErr);
antinoiseFxlms = zeros(1, numErr);
referenceFxlms = zeros(1, numRef);

% Setup FxLMS system object
fxlmsSysObj = classMimoFxLMSFilter('numRef', numRef, 'numErr', numErr, 'numSpk', numSpk, 'stepsize', stepFxlms, 'leakage', leakFxlms, ...
                                   'normweight', normK, 'smoothing', 0.97, 'estSecPathCoeff', secPathEstCoef, 'filterLen', 200, ...
                                   'estSecPathFilterLen', numIrTaps);

for i = 1:sigLen

    % Simulate primary noise
    for err = 1:numErr
        for src = 1:numSrc
            primaryFxlms(1, err) = primaryFxlms(1, err) + priPathFilt{src, err}(noise(i, 1));
        end
    end
    savePrinoise(i, :) = primaryFxlms;

    % Calc error i.e. residual noise
    errorFxlms = primaryFxlms - antinoiseFxlms;
    saveError(i, :) = errorFxlms;

    % Simulate reference path acoustics
    for ref = 1:numRef
        for src = 1:numSrc
            referenceFxlms(1, ref) = referenceFxlms(1, ref) + refPathFilt{src, ref}(noise(i, 1));
        end
    end
    saveReference(i, :) = referenceFxlms;

    % Call FxLMS algorithm
    outputFxlms = fxlmsSysObj(referenceFxlms, errorFxlms); 

    % Simulate secondary path acoustics
    antinoiseFxlms(:) = 0; 
    for err = 1:numErr
        for spk = 1:numSpk
            antinoiseFxlms(1, err) = antinoiseFxlms(1, err) + secPathFilt{spk, err}(outputFxlms(1, spk));
        end
    end
    saveAntinoise(i, :) = antinoiseFxlms;

    % Clear values
    primaryFxlms(:)   = 0;    
    referenceFxlms(:) = 0;
end

%% Generate all plots

% Calculate frequency domain data
winLen  = 1024;
overlap = 512;
fftLen  = 2048;

% for residual noise, wait for a few seconds and then compute PSD to ensure
% convergence
waitTime = 10; % sec

[psd_prinoise,  fxx] = pwelch(primaryFxlms, winLen, overlap, fftLen, fs);
[psd_antinoise, ~]   = pwelch(saveAntinoise, winLen, overlap, fftLen, fs);
[psd_error, ~] = pwelch(saveError(waitTime * fs:end, 1), winLen, overlap, fftLen, fs);

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
plot(1:filtLen_lms, squeeze(secPathEstCoef), 'LineWidth', 1.1); 
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
plot(txx, primaryFxlms);
hold on;
plot(txx, -saveAntinoise);
plot(txx, saveError);
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
    audiowrite('noiseAncOff_rand.wav', primaryFxlms ./ max(abs(primaryFxlms)), fs);
    audiowrite('noiseAncOn_rand.wav', saveError ./ max(abs(saveError)), fs);
elseif strcmpi(noiseType, 'tonal')
    audiowrite('noiseAncOff_tonal.wav', primaryFxlms ./ max(abs(primaryFxlms)), fs);
    audiowrite('noiseAncOn_tonal.wav', saveError ./ max(abs(saveError)), fs);
end