close all
clearvars
clc
%% Setup

% Simulation input file
simInput = '/Users/sattwikbasu/Repos/ActiveNoiseCancellation/Data/Input/ancSimInput.mat';

% Algorithm tuning
fxlmsProp.step = 0.1;
fxlmsProp.leak = 0.00001;
fxlmsProp.normweight = 0.1;
fxlmsProp.smoothing  = 0.997;
fxlmsProp.filterLen  = 300;

lmsProp.step = 0.04;
lmsProp.leak = 0.00001;
lmsProp.normweight = 0.1;
lmsProp.smoothing  = 0.997;
lmsProp.filterLen  = 300;

%% Run algorithm

disp('--- Setting up the algorithms');
anc = classAncSim(simInput);
anc = anc.setupSystemObj(fxlmsProp, lmsProp);

disp('--- Measuring Impulse Response');
anc = anc.measureIr();

disp('--- Running Simulation');
[anc, simData] = anc.ancSimCore();

%% Generate plots

disp('--- Plotting');
plt = classAncPlots(simData);
plt.genTimeDomainPlots();

%%

release(anc.fxlms);
release(anc.lms);
anc = [];
plt = [];