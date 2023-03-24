function [xstft, t, f, padLen, xframe] = getStft(x, fs, winLen, winType, overlap, fftLen)
%GETSTFT Implementation of the Short-time Fourier Transform
%   This function takes a time domain signal x, along with other parameters
%   such as sample rate, window length, window type, overlap percentage and
%   FFT length and outputs a complex STFT matrix. 
%   Author: Sattwik Basu
%   Date: Oct 14 2022

% Set default values
if nargin < 6
    fftLen = winLen;
end
if nargin < 5
    overlap = floor(0.75 * winLen); % 75% of the window len
end
if nargin < 4
    winType = 'hann';
end

% NOTE: Input signal must have different channels in columns

numChn = size(x, 2);
sigLen = size(x, 1);
hopLen = winLen - overlap;
numFrm = ((sigLen - overlap) / hopLen);

% Pad signal with zeros for proper reconstruction
if floor(numFrm) ~= numFrm
    i = 0;
    while floor(numFrm) ~= numFrm
        padLen   = i;
        xzeropad = [x ; zeros(padLen, numChn)];
        numFrm   = (length(xzeropad) - overlap) / hopLen;
        i = i+1;
    end
else
    padLen   = 0;
    xzeropad = x;
end

% Select the appropriate window based on input
if strcmpi(winType, 'rect')
    win = str2func('ones');
    arg = 1;
else
    win = str2func(winType);
    arg = 'periodic';
end

% Split signal into frames
xframe = zeros(winLen, numFrm, numChn);
for chn = 1:numChn
    for frm = 1:numFrm
        start = hopLen * (frm - 1) + 1;
        stop  = hopLen * (frm - 1) + winLen;
        xframe(:, frm, chn) = xzeropad(start:stop, chn);
    end
end

% Apply window to each frame
xframewin = win(winLen, arg) .* xframe;

% Compute FFT on each frame
xstft = fft(xframewin, fftLen);

% Compute time and frequency axes
t  = ((0:(numFrm - 1)) * hopLen + winLen/2) / fs;
df = fs / fftLen;
f  = 0:df:fs-df;

% if no output is requested, display one-sided spectrogram
if nargout < 1

    f_plot = f(1:fftLen/2+1);
    xstft_plot = xstft(1:fftLen/2+1, :, :);
    % One subplot per channel
    tl = tiledlayout('flow');%numChn,1);
    for chn = 1:numChn
        nexttile;
        img  = mag2db(abs(xstft_plot(:, :, chn) + eps));

        % Apply thresholding to spectrograms
        pmax = max(img(:));
        pth  = pmax-80; % remove values 65 dB below peak

        % Display
        imagesc(t, f_plot, img);
        colorbar;
        set(gca,'YDir','normal');
        set(gca,'CLim',[pth pmax]);
        xlabel('Time (s)'); ylabel('Frequency (Hz)');

        if numChn > 1
            title(['Channel: ', num2str(chn)]);
        end
    end
    title(tl, 'Spectrograms');
end