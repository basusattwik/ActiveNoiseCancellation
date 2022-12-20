close all
clearvars
clc

%% Setup

% Simulation input file
simInput = '/Users/sattwikbasu/Repos/ActiveNoiseCancellation/Data/Input/MATFiles/ancSimInput.mat';

%% Run algorithm

% Main ANC class
anc = classAncSim(simInput);

% Set algorithm tuning
[fxlmsProp, lmsProp] = getAncTuning();

% Run simulation
[anc, simData] = anc.runAncSim(fxlmsProp, lmsProp);

%% Generate plots

plt = classAncPlots(simData);
plt.genAllPlots();

%% Close out

release(anc.fxlms);
release(anc.lms);
anc = []; 
plt = [];

disp('Done!');