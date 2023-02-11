%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%-------------------------------------------------------------
% This is the main script for running any ANC simulation
% User has to: 
%   1. choose an input .mat file by providing path
%   2. choose an adaptive algorithm (using a function handle)
%
% Required toolboxes:
%   1. DSP System
%   2. Signal Processing
%   3. Audio
%%-------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all force
clearvars
clc

%% Choose simulation scenario and ANC algorithm

% Choose simulation input file
simInput = '/Users/sattwikbasu/Repos/ActiveNoiseCancellation/Data/Input/MATFiles/ancSimInput_oneSource.mat';

% Choose Algorithm (look at the Algorithms folder for the correct names)
ancAlgo = @sysFxLMS;

%% Run algorithm

% Setup main ANC class
anc = classAncSim(simInput);

% Set algorithm tuning
[ancAlgoTune, msrIrTune] = getAncTuning();

% Run simulation
[anc, simData] = anc.runAncSim(ancAlgo, ancAlgoTune, msrIrTune);

%% Generate plots

% Setup class for plotting
plt = classAncPlots(simData);

% Call function to produce plots
plt.genAllPlots();

%% Close out sim

release(anc.ancAlgo);
anc = []; 
plt = [];

disp('Done!');