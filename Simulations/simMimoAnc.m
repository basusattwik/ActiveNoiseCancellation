close all
clearvars
clc
%% Setup

% Simulation input file
simInput = '/Users/sattwikbasu/Repos/ActiveNoiseCancellation/Data/Input/ancSimInput.mat';

% Algorithm tuning
fxlmsProp.step = 0.00002;
fxlmsProp.leak = 0.000001;
fxlmsProp.normweight = 0.1;
fxlmsProp.smoothing  = 0.997;
fxlmsProp.filterLen  = 300;

lmsProp.step = 0.04;
lmsProp.leak = 0.00001;
lmsProp.normweight = 0.1;
lmsProp.smoothing  = 0.997;
lmsProp.filterLen  = 300;

%% Run algorithm

anc = classAncSim(simInput);

disp('--- Setting up the algorithms');
anc = anc.setupSystemObj(fxlmsProp, lmsProp);
anc = anc.resetBuffers();

disp('--- Measuring Impulse Response');
tic;
bCopy = true;
anc   = anc.measureIr(bCopy);
toc;

disp('--- Running Simulation');
tic;
[anc, simData] = anc.ancSimCore();
toc;

%% Generate plots

disp('--- Plotting');
plt = classAncPlots(simData);
plt.genTimeDomainPlots();

%% Close out

release(anc.fxlms);
release(anc.lms);
anc = [];
plt = [];

disp('Done!');