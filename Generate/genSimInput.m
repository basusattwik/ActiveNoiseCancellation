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
fs = 3000;

% Acoustic properties
roomDim    = [6, 6, 4];                                           % Room dimensions    [x y z] (m)
sources    = [1.8, 1.5, 2; 1.8, 3, 2; 1.8, 4.5, 2]; % Source position    [x y z] (m)
refMics    = [2, 2, 2; 2, 3, 2; 2, 4, 2; 2, 5, 2];                     % Reference mic position [x y z] (m)
errMics    = [4.5, 2, 2; 4.5, 4, 2];                            % Error mic position [x y z] (m)
speakers   = [4.3, 1.8, 2; 4.3, 2.2, 2];                          % Speaker position   [x y z] (m)
numTaps    = 1024;                                                % Number of samples in IR
soundSpeed = 340;                                                 % Speed of sound in  (m/s)
reverbTime = 0.2;                                                 % Reverberation time (s)                  
simTime    = 10; 

% Simulate headphones with a LPF
bSimheadphones = false;
lpfCutoff = 800; % Hz
lpfOrder  = 8;

%% Input signals (sources)

numSrc = size(sources,  1);  % Number of sources
numRef = size(refMics,  1);  % Number of reference mics
numSpk = size(speakers, 1);  % Number of antinoise speakers
numErr = size(errMics,  1);  % Number of error mics

noise  = zeros(simTime * fs, numSrc);

% Source 1
% f   = [80, 150, 200, 250, 300];
% amp = [0.1, 0.08, 0.07, 0.065, 0.06];
% phs = [0, 0, 0, 0, 0];
% 
% noise(:, 1) = imag(complexsin(fs, f, amp, phs, simTime));
h = fir1(64, 300/(0.5 * fs));
noise(:, 1) = 0.6 * filter(h, 1, rand(simTime * fs, 1));

% Add other sources below:
% You can also add .wav files

% Source 2
% f   = [80, 150, 200, 250, 300];
% amp = [0.1, 0.08, 0.07, 0.065, 0.06];
% phs = [30, 24, 60, 10, 20];
% 
% noise(:, 2) = real(complexsin(fs, f, amp, phs, simTime));
h = fir1(64, 300/(0.5 * fs));
noise(:, 2) = 0.6 * filter(h, 1, rand(simTime * fs, 1));

% Source 3
h = fir1(64, 200/(0.5 * fs));
noise(:, 3) = 0.6 * filter(h, 1, rand(simTime * fs, 1));

% Source 4
h = fir1(64, 800/(0.5 * fs));
noise(:, 4) = 0.1 * filter(h, 1, rand(simTime * fs, 1));

% Source 5
[cry, cryFs] = audioread('Input/Signals/noise_train.wav');
[p, q] = rat(fs / cryFs);
cry    = resample(cry, p, q);
noise(:, 5) = cry(1:simTime * fs, 1);

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
ancSimInput.acoustics.numTaps    = numTaps;
ancSimInput.acoustics.bSimheadphones = bSimheadphones;
ancSimInput.acoustics.lpfCutoff = lpfCutoff;
ancSimInput.acoustics.lpfOrder  = lpfOrder;

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

%% Plots of data

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

figure(2)
rectangle('Position',[0 0 roomDim(1) roomDim(2)]');
hold on;
for src = 1:numSrc
    plot(sources(src, 1), sources(src, 2), '.', 'MarkerSize', 25, 'Color', [0 0.4470 0.7410], 'DisplayName', ['S', num2str(src)]);
%     text(sources(src, 1), sources(src, 2)-0.3, ['S', num2str(src)]);
end
for ref = 1:numRef
    plot(refMics(ref, 1), refMics(ref, 2), '.', 'MarkerSize', 25, 'Color', [0.8500 0.3250 0.0980], 'DisplayName', ['R', num2str(ref)]);
%     text(refMics(ref, 1), refMics(ref, 2)-0.3, ['R', num2str(ref)]);
end
for err = 1:numErr
    plot(errMics(err, 1), errMics(err, 2), '.', 'MarkerSize', 25, 'Color', [0.9290 0.6940 0.1250], 'DisplayName', ['E', num2str(err)]);
%     text(errMics(err, 1), errMics(err, 2)-0.3, ['E', num2str(err)]);
end
for spk = 1:numSpk
    plot(speakers(spk, 1), speakers(spk, 2), '.', 'MarkerSize', 25, 'Color', [0.4940 0.1840 0.5560], 'DisplayName', ['Sp', num2str(spk)]);
%     text(speakers(spk, 1), speakers(spk, 2)-0.3, ['Sp', num2str(spk)]);
end
axis([0 roomDim(1) 0 roomDim(2)]);
xlabel('Length'); ylabel('Width');
legend('show');
grid on; grid minor;