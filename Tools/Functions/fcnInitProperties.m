function app = fcnInitProperties(app, simInput)
%FCNINITPROPERTIES Summary of this function goes here
%   Detailed explanation goes here

% Assign data to class properties
app.priPath.filt = simInput.priPathFilters;
app.secPath.filt = simInput.secPathFilters;
app.refPath.filt = simInput.refPathFilters;

app.numErr = simInput.config.numErr;
app.numRef = simInput.config.numRef;
app.numSrc = simInput.config.numSrc;
app.numSpk = simInput.config.numSpk;
app.fs     = simInput.config.fs;

fftLen = str2double(app.FFTLenDropDown.Value);

% if ~isempty(app.priPath)
%     app.priPath.mag = zeros(app.numSrc, app.numErr, fftLen/2+1);
%     app.priPath.phs = zeros(app.numSrc, app.numErr, fftLen/2+1);
% end
% if ~isempty(app.refPath)
%     app.refPath.mag = zeros(app.numSrc, app.numRef, fftLen/2+1);
%     app.refPath.phs = zeros(app.numSrc, app.numRef, fftLen/2+1);
% end
% if ~isempty(app.secPath)
%     app.secPath.mag = zeros(app.numSpk, app.numErr, fftLen/2+1);
%     app.secPath.phs = zeros(app.numSpk, app.numErr, fftLen/2+1);
% end

end


