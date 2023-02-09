function [app] = uiDisplayConfig(app)
%UIDISPLAYCONFIG Summary of this function goes here
%   Detailed explanation goes here

app.ErrorEditField.Value = num2str(app.numErr);
app.RefEditField.Value   = num2str(app.numRef);
app.SrcEditField.Value   = num2str(app.numSrc);
app.SpkEditField.Value   = num2str(app.numSpk);
app.fsEditField.Value    = num2str(app.fs);

end

