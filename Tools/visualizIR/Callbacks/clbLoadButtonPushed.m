function app = clbLoadButtonPushed(app)
%CALLBACKLOADBUTTONPUSHED Load simulation input mat files and save struct
%to the app

[file, path] = uigetfile;
if file ~= 0 % protect if user hits cancel/close
    load(fullfile(path, file), 'ancSimInput');
else
    return;
end

uiDisplayStatus(app, 'Loading...', [0.64,0.08,0.18]); % red color

% Initialize app class properties
fcnInitProperties(app, ancSimInput);

% Calculate frequency domain data and store in app
fcnGenFftData(app);

% Update UI
uiUpdateDropdowns(app);
uiDisplayConfig(app);

% Display Plots
uiDisplayFigures(app);

uiDisplayStatus(app, 'Done!', [0.47,0.67,0.19]); % green color
end

