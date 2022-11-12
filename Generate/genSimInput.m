close all
clearvars
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                          %
% GENERATE DATA FOR SIM    %
%                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Simulation setup

% Sampling Rate
fs = 6000;

% Acoustic properties
roomDim    = [4, 3, 2];                % Room dimensions    [x y z] (m)
sources    = [2, 3.5, 2; 3, 3.5, 1];   % Source position    [x y z] (m)
refmics    = [3, 0.1, 2; 3, 0.1, 2.1]; % Reference mic position [x y z] (m)
errmics    = [3, 1.5, 2; 3, 1.8, 2];   % Error mic position [x y z] (m)
speakers   = [3, 3.5, 2; 3, 3.8, 2];   % Speaker position   [x y z] (m)
numtaps    = 300;                      % Number of samples in IR
soundspeed = 340;                      % Speed of sound in  (m/s)
reverbtime = 0.1;                      % Reverberation time (s)
sourcetype = 'tonal';                  
simtime    = 30; 

%% Input signals (sources)

numSrc = size(sources,  1);  % Number of sources
numRef = size(refmics,  1);  % Number of reference mics
numSpk = size(speakers, 1);  % Number of antinoise speakers
numErr = size(errmics,  1);  % Number of error mics

noise  = zeros(simtime * fs, numSrc);

% Source 1
f   = [150, 150, 150, 150];
amp = [1, 1, 1, 1];
phs = [0, 0, 0, 0];

t = (0:1/fs:(simtime)-1/fs).';
noise(:, 1) = real(complexsin(fs, f, amp, phs, simtime));

% Add other sources below:
% You can also add .wav files

% Source 2
noise(:, 2) = 0.1 * randn(simtime * fs, 1);

%% Transfer functions

disp('Generating Room Impulse Responses...');

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

%% Save all parameters in a mat file

% Hardware config
ancSimInput.numSrc = size(sources,  1);
ancSimInput.numRef = size(refmics,  1) ;
ancSimInput.numErr = size(errmics,  1);
ancSimInput.numSpk = size(speakers, 1);

% Acoustic config
ancSimInput.acoustics.roomDim  = roomDim;
ancSimInput.acoustics.sources  = sources;
ancSimInput.acoustics.refmics  = refmics;
ancSimInput.acoustics.errmics  = errmics;
ancSimInput.acoustics.speakers = speakers;

% All IRs
ancSimInput.priPathFilters = priPathFilt;
ancSimInput.refPathFilters = refPathFilt;
ancSimInput.secPathFilters = secPathFilt;

% Input signals (sources)
ancSimInput.noiseSource = noise;
ancSimInput.simTime = simtime;

folderName = 'InputFiles';
if ~exist(folderName, 'dir')
   mkdir(folderName);
   addpath(genpath(folderName));
end

save([folderName, '/ancSimInput.mat'], "ancSimInput");

%% Generate frequency domain data for transfer functions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                          %
% ANALYZE DATA FOR SIM     %
%                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fftLen = 1024;
df  = fs / fftLen;  % frequency spacing
fx  = 0:df:fs/2;  % frequency axis

% Primary paths
priPathFftMag = zeros(numSrc, numErr, fftLen/2+1);
priPathFftPhs = zeros(numSrc, numErr, fftLen/2+1);
for src = 1:numSrc
    for err = 1:numErr
        h = priPathFilt{src, err}.Numerator;
        H = fft(h, fftLen) / fftLen;
        priPathFftMag(src, err, :) = abs(H(1:fftLen/2+1));
        priPathFftPhs(src, err, :) = angle(H(1:fftLen/2+1));
    end
end
priPathFftMag(:, :, 2:end-1) = 2 * priPathFftMag(:, :, 2:end-1); % Correct mag for one sided view

% Reference paths
refPathFftMag = zeros(numSrc, numRef, fftLen/2+1);
refPathFftPhs = zeros(numSrc, numRef, fftLen/2+1);
for src = 1:numSrc
    for ref = 1:numRef
        h = refPathFilt{src, ref}.Numerator;
        H = fft(h, fftLen) / fftLen;
        refPathFftMag(src, ref, :) = abs(H(1:fftLen/2+1));
        refPathFftPhs(src, ref, :) = angle(H(1:fftLen/2+1));
    end
end
refPathFftMag(:, :, 2:end-1) = 2 * refPathFftMag(:, :, 2:end-1); % Correct mag for one sided view

% Secondary paths
secPathFftMag = zeros(numSpk, numErr, fftLen/2+1);
secPathFftPhs = zeros(numSrc, numErr, fftLen/2+1);
for spk = 1:numSpk
    for err = 1:numErr
        h = secPathFilt{spk, err}.Numerator;
        H = fft(h, fftLen) / fftLen;
        secPathFftMag(spk, err, :) = abs(H(1:fftLen/2+1));
        secPathFftPhs(spk, err, :) = angle(H(1:fftLen/2+1));
    end
end
secPathFftMag(:, :, 2:end-1) = 2 * secPathFftMag(:, :, 2:end-1); % Correct mag for one sided view

%% Plots of data

% Sources
figure(1)
tl = tiledlayout('flow');

for i = 1:numSrc
    % Generate plots
    nexttile
    plot(t, noise(:, i));
    xlabel('time (s)'); ylabel('Amplitude');
    grid on; grid minor;
    title(['Source ', num2str(i)]);
end
title(tl, 'Noise sources');

% ToDO: Find a good way to plot all the FFTs
