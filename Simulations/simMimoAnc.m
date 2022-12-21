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
[fxlmsProp, msrIrProp] = getAncTuning();

% Run simulation
[anc, simData] = anc.runAncSim(fxlmsProp, msrIrProp);

%% Generate plots

plt = classAncPlots(simData);
plt.genAllPlots();

%% Close out

release(anc.fxlms);
anc = []; 
plt = [];

disp('Done!');