function app = fcnInitProperties(app, simInput)
%FCNINITPROPERTIES Summary of this function goes here
%   Detailed explanation goes here

% Assign data to class properties
app.priPath.filt = simInput.priPathFilters;
app.secPath.filt = simInput.secPathFilters;
app.refPath.filt = simInput.refPathFilters;

app.numErr  = simInput.config.numErr;
app.numRef  = simInput.config.numRef;
app.numSrc  = simInput.config.numSrc;
app.numSpk  = simInput.config.numSpk;
app.fs      = simInput.config.fs;
app.numTaps = simInput.acoustics.numTaps;

fftLen = str2double(app.FFTLenDropDown.Value);

end


