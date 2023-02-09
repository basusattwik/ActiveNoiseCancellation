function app = uiDisplayStatus(app, message, color)
%UIDISPLAYSTATUS Summary of this function goes here
%   Detailed explanation goes here

if nargin < 3
    color = [0 0 0]; % default font color is black
end
app.StatusTextArea.Value = {message};
app.StatusTextArea.FontColor = color;

end