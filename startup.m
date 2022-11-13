% Startup script for the Active Noise Cancellation simulation framework

close all
clearvars
clc

% Add folders to MATLAB path
folders = {'Examples', 'Generate', 'Algorithms', 'External', ...
           'Helpers', 'Classes', 'Simulations', 'InputFiles'};

numFolders = numel(folders);
for i = 1:numFolders 
    addpath(genpath(folders{i}));
end

disp("ActiveNoiseCancellation: Ready to run!");