function app = fcnGenFftData(app)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

fftLen = str2double(app.FFTLenDropDown.Value);

% preallocate memory
if ~isempty(app.priPath)
    app.priPath.mag = zeros(app.numSrc, app.numErr, fftLen/2+1);
    app.priPath.phs = zeros(app.numSrc, app.numErr, fftLen/2+1);
    app.priPath.grd = zeros(app.numSrc, app.numErr, fftLen/2+1);
end
if ~isempty(app.refPath)
    app.refPath.mag = zeros(app.numSrc, app.numRef, fftLen/2+1);
    app.refPath.phs = zeros(app.numSrc, app.numRef, fftLen/2+1);
    app.refPath.grd = zeros(app.numSrc, app.numRef, fftLen/2+1);
end
if ~isempty(app.secPath)
    app.secPath.mag = zeros(app.numSpk, app.numErr, fftLen/2+1);
    app.secPath.phs = zeros(app.numSpk, app.numErr, fftLen/2+1);
    app.secPath.grd = zeros(app.numSpk, app.numErr, fftLen/2+1);
end

% Primary paths
if ~isempty(app.priPath)
    for src = 1:app.numSrc
        for err = 1:app.numErr
            h = app.priPath.filt{src, err}.Numerator;
            H = fft(h, fftLen) / numel(h);
            g = grpdelay(h, 1, fftLen);
            app.priPath.mag(src, err, :) = abs(H(1:fftLen/2+1));
            app.priPath.phs(src, err, :) = angle(H(1:fftLen/2+1));
            app.priPath.grd(src, err, :) = g(1:fftLen/2+1);
        end
    end
    app.priPath.mag(:, :, 2:end-1) = 2 * app.priPath.mag(:, :, 2:end-1); % Correct mag for one sided view
end

% Reference paths
if ~isempty(app.refPath)
    for src = 1:app.numSrc
        for ref = 1:app.numRef
            h = app.refPath.filt{src, ref}.Numerator;
            H = fft(h, fftLen) / numel(h);
            app.refPath.mag(src, ref, :) = abs(H(1:fftLen/2+1));
            app.refPath.phs(src, ref, :) = angle(H(1:fftLen/2+1));
            app.refPath.grd(src, ref, :) = grpdelay(h, 1, fftLen/2+1);
        end
    end
    app.refPath.mag(:, :, 2:end-1) = 2 * app.refPath.mag(:, :, 2:end-1); % Correct mag for one sided view
end

% Secondary paths
if ~isempty(app.secPath)
    for spk = 1:app.numSpk
        for err = 1:app.numErr
            h = app.secPath.filt{spk, err}.Numerator;
            H = fft(h, fftLen) / numel(h);
            app.secPath.mag(spk, err, :) = abs(H(1:fftLen/2+1));
            app.secPath.phs(spk, err, :) = angle(H(1:fftLen/2+1));
            app.secPath.grd(spk, err, :) = grpdelay(h, 1, fftLen/2+1);
        end
    end
    app.secPath.mag(:, :, 2:end-1) = 2 * app.secPath.mag(:, :, 2:end-1); % Correct mag for one sided view
end

end

