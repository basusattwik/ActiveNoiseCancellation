close all
clearvars
clc

%% Setup

% Simulation input file
simInput = '/Users/sattwikbasu/Repos/ActiveNoiseCancellation/Data/Input/MATFiles/ancSimInput.mat';

% Choose Algorithm
ancAlgo = @sysMimoFxLMS;

%% Run algorithm

% Main ANC class
anc = classAncSim(simInput);

% Set algorithm tuning
[ancAlgoTune, msrIrTune] = getAncTuning();

% Run simulation
[anc, simData] = anc.runAncSim(ancAlgo, ancAlgoTune, msrIrTune);

%% Generate plots

plt = classAncPlots(simData);
plt.genAllPlots();

%% Close out

release(anc.ancAlgo);
anc = []; 
plt = [];

disp('Done!');