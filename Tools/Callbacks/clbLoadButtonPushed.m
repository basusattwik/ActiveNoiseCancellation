function app = clbLoadButtonPushed(app)
%CALLBACKLOADBUTTONPUSHED Load simulation input mat files and save struct
%to the app

[file, path] = uigetfile;
load(fullfile(path, file), 'ancSimInput');

% Initialize app class properties
fcnInitProperties(app, ancSimInput);

% Calculate frequency domain data and store in app
fcnGenFftData(app);

% Update UI
uiUpdateDropdowns(app);
uiDisplayConfig(app);
uiDisplayStatus(app, 'Done!', [0.47,0.67,0.19]); % green color

% Display Plots
uiDisplayFigures(app);

end

