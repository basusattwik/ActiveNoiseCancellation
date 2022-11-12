% Startup script for the ANC simulation framework

close all
clearvars
clc

% Add subfolders to MATLAB path
folders = {'Examples', 'Generate', 'Algorithms', 'External', 'Helpers'};

numFolders = numel(folders);
for i = 1:numFolders 
    addpath(genpath(folders{i}));
end

disp("ActiveNoiseCancellation: Ready to run!");