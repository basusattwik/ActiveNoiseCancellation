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
fxlmsProp.filterLen  = 200;

lmsProp.step = 0.04;
lmsProp.leak = 0.00001;
lmsProp.normweight = 0.1;
lmsProp.smoothing  = 0.997;
lmsProp.filterLen  = 200;

%% Run algorithm

disp('Setting up the algorithms');
anc = classAncSim(simInput);
anc = anc.setupSystemObj(fxlmsProp, lmsProp);

disp('Measuring Impulse Response');
anc = anc.measureIr();

disp('Running Simulation');
anc = anc.ancSimCore();

%% Generate plots


