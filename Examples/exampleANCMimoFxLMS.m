close all
clearvars
clc

%% Define sim constants

% System setup
numSrc = 1; % Number of sources
numRef = 2; % Number of reference mics
numSpk = 2; % Number of antinoise speakers
numErr = 2; % Number of error mics

fs = 6000; % 6 kHz sampling rate
noiseType = 'tonal';
boolMeasureSecPath = false;

%% Algorithm Tuning

if strcmpi(noiseType, 'rand')
    muFxlms    = 0.1; % for rand
    gammaFxlms = 0.001;
    normK = 0.001;

elseif strcmpi(noiseType, 'tonal')
    muFxlms    = 0.9;
    gammaFxlms = 0.00001;
    normK = 0.01;
end

%% Create Transfer Functions

disp('Generating Room Impulse Responses...');

roomDim = [4, 3, 2];                % Room dimensions [x y z] (m)
source  = [2, 3.5, 2];              % Source position   [x y z] (m)
refMics = [3, 0.1, 2; 3, 0.1, 2.1]; % Reference mic position [x y z] (m)
errMics = [3, 1.5, 2; 3, 1.8, 2];   % Error mic position [x y z] (m)
speaker = [3, 3.5, 2; 3, 3.8, 2.1]; % Speaker position [x y z] (m)
numTaps = 300;                      % Number of samples
soundSpeed = 340;                   % Speed of sound in (m/s)
reverbTime = 0.1;                   % Reverberation time (s)

% Primary Paths: Source to Error Mics
priPathParams.fs = fs;
priPathParams.srcPos = source;           
priPathParams.micPos = errMics;          
priPathParams.c    = soundSpeed;         
priPathParams.beta = reverbTime;         
priPathParams.n = numTaps;                  
priPathParams.L = roomDim;             

priPathFilters = genRirFilters(priPathParams);

% Secondary Paths: Speakers to Error Mics
secPathParams.fs = fs;
secPathParams.srcPos = speaker; 
secPathParams.micPos = errMics; 
secPathParams.c    = soundSpeed;         
secPathParams.beta = reverbTime;         
secPathParams.n = numTaps;                  
secPathParams.L = roomDim;             

secPathFilters = genRirFilters(secPathParams);

% Reference Paths: Source to Reference Mics
refPathParams.fs = fs;
refPathParams.srcPos = source;  
refPathParams.micPos = refMics; 
refPathParams.c    = soundSpeed;         
refPathParams.beta = reverbTime;         
refPathParams.n = numTaps;                  
refPathParams.L = roomDim;             

refPathFilters = genRirFilters(refPathParams);

%% Estimate Secondary Path

%%%%%%%%%%%%%%%%%%%%%%%%
%                      %
% LMS Adaptive Filter  %
%                      %
%%%%%%%%%%%%%%%%%%%%%%%%

numIrTaps = 200;

if ~boolMeasureSecPath
    secPathEstCoef = zeros(numSpk, numErr, numIrTaps);
    for spk = 1:numSpk
        for err = 1:numErr
            secPathEstCoef(spk, err, :) = secPathFilters{spk, err}.Numerator(1:numIrTaps);
        end
    end
else
    disp('Measuring secondary path impulse responses...');
    % Initialize excitation signal
    extime = 10; % 10 sec
    randNoise = randn(fs * extime, numSpk);
    
    % Setup LMS system object
    lmsSysObj = classLMSFilter('numSpk', numSpk, 'numErr', numErr, 'stepsize', 0.04, 'leakage', 0.001, 'normweight', 1, 'smoothing', 0.97, 'filterlen', numIrTaps);
    xexfilt = zeros(1, numErr);

    for i = 1:length(randNoise)
    
        % Simulate secondary path
        for err = 1:numErr
            for spk = 1:numSpk
                xexfilt(1, err) = xexfilt(1, err) + secPathFilters{spk, err}(randNoise(i, spk));
            end
        end
    
        % Call LMS algorithm 
        lmsSysObj.step(randNoise(i,:), xexfilt);
        xexfilt(:) = 0;
    end
    secPathEstCoef = lmsSysObj.coeffs;
end

%% Noise signal

% Create filtered primary noise
noiseTime = 30; % sec

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

%% FxLMS Loop

disp('Running FxLMS ANC simulation...');

% Preallocate memory
saveError      = zeros(noiseTime * fs, numErr);
outputFxlms    = zeros(noiseTime * fs, numSpk);
saveAntinoise  = zeros(noiseTime * fs, numErr);
savePrinoise   = zeros(noiseTime * fs, numErr);
saveReference  = zeros(noiseTime * fs, numErr);
prinoiseFxlms  = zeros(1, numErr);
errorFxlms     = zeros(1, numErr);
antinoiseFxlms = zeros(1, numErr);
referenceFxlms = zeros(1, numErr);

% Setup FxLMS system object
fxlmsSysObj = classMimoFxLMSFilter('numRef', numRef, 'numErr', numErr, 'numSpk', numSpk, 'stepsize', muFxlms, 'leakage', gammaFxlms, 'normweight', normK, 'smoothing', 0.97, 'estSecPathCoeff', secPathEstCoef, 'filterLen', 200, 'estSecPathFilterLen', numIrTaps);

for i = 1:length(noise)

    % Simulate primary noise
    for err = 1:numErr
        for src = 1:numSrc
            prinoiseFxlms(1, err) = prinoiseFxlms(1, err) + priPathFilters{src, err}(noise(i, 1));
        end
    end
    savePrinoise(i, :) = prinoiseFxlms;

    % Calc error i.e. residual noise
    errorFxlms = prinoiseFxlms - antinoiseFxlms;
    saveError(i, :) = errorFxlms;

    % Simulate reference path acoustics
    for ref = 1:numRef
        for src = 1:numSrc
            referenceFxlms(1, ref) = referenceFxlms(1, ref) + refPathFilters{src, ref}(noise(i, 1));
        end
    end
    saveReference(i, :) = referenceFxlms;

    % Call FxLMS algorithm
    outputFxlms = fxlmsSysObj(referenceFxlms, errorFxlms); 

    % Simulate secondary path acoustics
    antinoiseFxlms(:) = 0; 
    for err = 1:numErr
        for spk = 1:numSpk
            antinoiseFxlms(1, err) = antinoiseFxlms(1, err) + secPathFilters{spk, err}(outputFxlms(1, spk));
        end
    end
    saveAntinoise(i, :) = antinoiseFxlms;

    % Clear values
    prinoiseFxlms(:)  = 0;    
    referenceFxlms(:) = 0;
end
 
% Calculate frequency domain data
winLen  = 1024;
overlap = 512;
fftLen  = 2048;

% for residual noise, wait for a few seconds and then compute PSD to ensure
% convergence
waitTime = 10; % sec

[psd_prinoise,  fxx] = pwelch(prinoiseFxlms, winLen, overlap, fftLen, fs);
[psd_antinoise, ~]   = pwelch(saveAntinoise, winLen, overlap, fftLen, fs);
[psd_error, ~] = pwelch(saveError(waitTime * fs:end, 1), winLen, overlap, fftLen, fs);

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
plot(txx, prinoiseFxlms);
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
    audiowrite('noiseAncOff_rand.wav', prinoiseFxlms ./ max(abs(prinoiseFxlms)), fs);
    audiowrite('noiseAncOn_rand.wav', saveError ./ max(abs(saveError)), fs);
elseif strcmpi(noiseType, 'tonal')
    audiowrite('noiseAncOff_tonal.wav', prinoiseFxlms ./ max(abs(prinoiseFxlms)), fs);
    audiowrite('noiseAncOn_tonal.wav', saveError ./ max(abs(saveError)), fs);
end