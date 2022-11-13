close all
clearvars
clc

%% Setup

% Simulation input file
simInput = '/Users/sattwikbasu/Repos/ActiveNoiseCancellation/InputFiles/ancSimInput.mat';

% Algorithm tuning
fxlmsProp.step = 20;
fxlmsProp.leak = 0.00001;
fxlmsProp.normweight = 0.01;
fxlmsProp.smoothing  = 0.997;
fxlmsProp.filterLen  = 300;

lmsProp.step = 0.04;
lmsProp.leak = 0.00001;
lmsProp.normweight = 0.1;
lmsProp.smoothing  = 0.997;
lmsProp.filterLen  = 300;

%% Run Algorithm

% Active Noise Cancellation 
anc = classAncSim(simInput);
anc = anc.setupSystemObj(fxlmsProp, lmsProp);
anc = anc.measureIr();
anc = anc.ancSimCore();


