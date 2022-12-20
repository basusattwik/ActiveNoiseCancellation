% Startup script for the Active Noise Cancellation simulation framework

close all
clearvars
clc

subfolders = {'Input', 'Output'};
for i = 1:numel(subfolders)
    name = ['Data/', subfolders{i}]; 
    if ~exist(name, 'dir')
       mkdir(name);
       addpath(genpath(name));
    end
end

% Add folders to MATLAB path
folders = {'Examples', 'Generate', 'Algorithms', 'External', ...
           'Helpers', 'Classes', 'Simulations', 'Data', 'Tuning'};
for i = 1:numel(folders)
    addpath(genpath(folders{i}));
end

disp("ActiveNoiseCancellation: Ready to run!");