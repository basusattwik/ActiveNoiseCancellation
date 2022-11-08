% Startup script for the ANC simulation framework

close all
clearvars
clc

% Add all folders to path
addpath("Examples/");
addpath(genpath("Generate/"));
addpath("Algorithms/")

disp("ActiveNoiseCancellation: Ready to run!");