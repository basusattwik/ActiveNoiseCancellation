function uiDisplayFigures(app)
%UIDISPLAYFIGURES Summary of this function goes here
%   Detailed explanation goes here

fftLen = str2double(app.FFTLenDropDown.Value);
df = app.fs / fftLen;  % frequency spacing
fx = 0:df:app.fs/2;    % frequency axis

if strcmpi(app.PathDropDown.Value, 'Primary')

    mic = str2double(app.MicDropDown.Value);
    src = str2double(app.SpkSrcDropDown.Value);

    plot(app.UIAxes1, app.priPath.filt{src, mic}.Numerator, 'LineWidth', 1.1);
    plot(app.UIAxes2, fx, mag2db(squeeze(app.priPath.mag(src, mic, :))), 'LineWidth', 1.1);
    plot(app.UIAxes3, fx, squeeze(app.priPath.phs(src, mic, :)), 'LineWidth', 1.1);

elseif strcmpi(app.PathDropDown.Value, 'Reference')

    mic = str2double(app.MicDropDown.Value);
    src = str2double(app.SpkSrcDropDown.Value);

    plot(app.UIAxes1, app.refPath.filt{src, mic}.Numerator, 'LineWidth', 1.1);
    plot(app.UIAxes2, fx, mag2db(squeeze(app.refPath.mag(src, mic, :))), 'LineWidth', 1.1);
    plot(app.UIAxes3, fx, squeeze(app.refPath.phs(src, mic, :)), 'LineWidth', 1.1);

elseif strcmpi(app.PathDropDown.Value, 'Secondary')
    
    mic = str2double(app.MicDropDown.Value);
    spk = str2double(app.SpkSrcDropDown.Value);

    plot(app.UIAxes1, app.secPath.filt{spk, mic}.Numerator, 'LineWidth', 1.1);
    plot(app.UIAxes2, fx, mag2db(squeeze(app.secPath.mag(spk, mic, :))), 'LineWidth', 1.1);
    plot(app.UIAxes3, fx, squeeze(app.secPath.phs(spk, mic, :)), 'LineWidth', 1.1);
end   

end

