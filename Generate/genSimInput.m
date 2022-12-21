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
roomDim    = [5, 5, 6];                                  % Room dimensions    [x y z] (m)
sources    = [1, 2, 2; 0, 3.5, 2; 2, 2.5, 2; 2, 2.7, 2]; % Source position    [x y z] (m)
refMics    = [4, 2, 2; 4, 2.2, 2];                    % Reference mic position [x y z] (m)
errMics    = [4.4, 2, 2; 4.2, 2.2, 2];                % Error mic position [x y z] (m)
speakers   = [4.2, 2, 2; 4.1, 2.2, 2];   % Speaker position   [x y z] (m)
numTaps    = 1024;                         % Number of samples in IR
soundSpeed = 340;                          % Speed of sound in  (m/s)
reverbTime = 0.4;                          % Reverberation time (s)                  
simTime    = 10; 

%% Input signals (sources)

numSrc = size(sources,  1);  % Number of sources
numRef = size(refMics,  1);  % Number of reference mics
numSpk = size(speakers, 1);  % Number of antinoise speakers
numErr = size(errMics,  1);  % Number of error mics

noise  = zeros(simTime * fs, numSrc);

% % Source 1
f   = [80, 150, 200, 250, 300];
amp = [0.1, 0.08, 0.07, 0.065, 0.06];
phs = [0, 0, 0, 0, 0];

noise(:, 1) = imag(complexsin(fs, f, amp, phs, simTime));

% Add other sources below:
% You can also add .wav files

% Source 2
f   = [60, 150, 200, 250, 300];
amp = [0.1, 0.08, 0.07, 0.065, 0.06];
phs = [30, 24, 60, 10, 20];

noise(:, 2) = real(complexsin(fs, f, amp, phs, simTime));

% Source 3
h = fir1(32, 700/(0.5 * fs));
noise(:, 3) = 0.1 * filter(h, 1, rand(simTime * fs, 1));

% Source 4
[cry, cryFs] = audioread('Input/Signals/noise_train.wav');
[p, q] = rat(fs / cryFs);
cry    = resample(cry, p, q);
noise(:, 4) = cry(1:simTime * fs, 1);

%% Transfer functions

disp('Generating Room Impulse Responses...');

% Primary Paths: Source to Error Mics
priPathParams.fs     = fs;
priPathParams.srcPos = sources;           
priPathParams.micPos = errMics;          
priPathParams.c      = soundSpeed;         
priPathParams.beta   = reverbTime;         
priPathParams.n      = numTaps;                  
priPathParams.L      = roomDim;             

priPathFilt = genRirFilters(priPathParams);

% Secondary Paths: Speakers to Error Mics
secPathParams.fs     = fs;
secPathParams.srcPos = speakers; 
secPathParams.micPos = errMics; 
secPathParams.c      = soundSpeed;         
secPathParams.beta   = reverbTime;         
secPathParams.n      = numTaps;                  
secPathParams.L      = roomDim;             

secPathFilt = genRirFilters(secPathParams);

% Reference Paths: Source to Reference Mics
refPathParams.fs     = fs;
refPathParams.srcPos = sources;  
refPathParams.micPos = refMics; 
refPathParams.c      = soundSpeed;         
refPathParams.beta   = reverbTime;         
refPathParams.n      = numTaps;                  
refPathParams.L      = roomDim;             

refPathFilt = genRirFilters(refPathParams);

%% Save all parameters in a mat file

% Hardware config
ancSimInput.config.numSrc = size(sources,  1);
ancSimInput.config.numRef = size(refMics,  1) ;
ancSimInput.config.numErr = size(errMics,  1);
ancSimInput.config.numSpk = size(speakers, 1);
ancSimInput.config.fs = fs;

% Acoustic config
ancSimInput.acoustics.roomDim  = roomDim;
ancSimInput.acoustics.sources  = sources;
ancSimInput.acoustics.refMics  = refMics;
ancSimInput.acoustics.errMics  = errMics;
ancSimInput.acoustics.speakers = speakers;
ancSimInput.acoustics.soundSpeed = soundSpeed;                      
ancSimInput.acoustics.reverbTime = reverbTime; 

% All IRs
ancSimInput.priPathFilters = priPathFilt;
ancSimInput.refPathFilters = refPathFilt;
ancSimInput.secPathFilters = secPathFilt;

% Input signals (sources)
ancSimInput.noiseSource = noise;
ancSimInput.simTime = simTime;

folderName = 'Data/Input/MATFiles';
if ~exist(folderName, 'dir')
   mkdir(folderName);
   addpath(genpath(folderName));
end

save([folderName, '/ancSimInput.mat'], "ancSimInput");

% %% Generate frequency domain data for transfer functions
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %                          %
% % ANALYZE DATA FOR SIM     %
% %                          %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% fftLen = 1024;
% df  = fs / fftLen;  % frequency spacing
% fx  = 0:df:fs/2;  % frequency axis
% 
% % Primary paths
% priPathFftMag = zeros(numSrc, numErr, fftLen/2+1);
% priPathFftPhs = zeros(numSrc, numErr, fftLen/2+1);
% for src = 1:numSrc
%     for err = 1:numErr
%         h = priPathFilt{src, err}.Numerator;
%         H = fft(h, fftLen) / fftLen;
%         priPathFftMag(src, err, :) = abs(H(1:fftLen/2+1));
%         priPathFftPhs(src, err, :) = angle(H(1:fftLen/2+1));
%     end
% end
% priPathFftMag(:, :, 2:end-1) = 2 * priPathFftMag(:, :, 2:end-1); % Correct mag for one sided view
% 
% % Reference paths
% refPathFftMag = zeros(numSrc, numRef, fftLen/2+1);
% refPathFftPhs = zeros(numSrc, numRef, fftLen/2+1);
% for src = 1:numSrc
%     for ref = 1:numRef
%         h = refPathFilt{src, ref}.Numerator;
%         H = fft(h, fftLen) / fftLen;
%         refPathFftMag(src, ref, :) = abs(H(1:fftLen/2+1));
%         refPathFftPhs(src, ref, :) = angle(H(1:fftLen/2+1));
%     end
% end
% refPathFftMag(:, :, 2:end-1) = 2 * refPathFftMag(:, :, 2:end-1); % Correct mag for one sided view
% 
% % Secondary paths
% secPathFftMag = zeros(numSpk, numErr, fftLen/2+1);
% secPathFftPhs = zeros(numSrc, numErr, fftLen/2+1);
% for spk = 1:numSpk
%     for err = 1:numErr
%         h = secPathFilt{spk, err}.Numerator;
%         H = fft(h, fftLen) / fftLen;
%         secPathFftMag(spk, err, :) = abs(H(1:fftLen/2+1));
%         secPathFftPhs(spk, err, :) = angle(H(1:fftLen/2+1));
%     end
% end
% secPathFftMag(:, :, 2:end-1) = 2 * secPathFftMag(:, :, 2:end-1); % Correct mag for one sided view
% 
% %% Plots of data
% 
% Sources
t = (0:1/fs:(simTime)-1/fs).';
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
% 
% % ToDO: Find a good way to plot all the FFTs
% selcSpk = 1;
% selcSrc = 1;
% 
% for err = 1:numErr 
%     plot(priPathFilt{selcSrc, err}.Numerator);
%     plot(fx, squeeze(priPathFftMag(src, err, :)));
% end