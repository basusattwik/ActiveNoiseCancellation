close all
clearvars
clc

%% Choose simulation scenario and ANC algorithm

% Choose simulation input file
simInput = '/Users/sattwikbasu/Repos/ActiveNoiseCancellation/Data/Input/MATFiles/ancSimInput.mat';

% Choose Algorithm (look at the Algorithms folder for the correct names)
ancAlgo = @sysHybridFxLMS;

%% Run algorithm

% Setup main ANC class
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