function x = getInvStft(xstft, winLen, winType, overlap, fftLen, padLen, bOnlyOla)
%GETINVSTFT Implementation of the Inverse Short-time Fourier Transform
%   This function takes a complex STFT matrix, along with other parameters
%   such as sample rate, window length, window type, overlap percentage and
%   FFT length and outputs a time domain signal using WOLA. 
%   Author: Sattwik Basu
%   Date: Oct 14 2022

if nargin < 7
    bOnlyOla = false;
end
if nargin < 6
    padLen = 0;
end

% Get the total number of frames & hop length
numFrm = size(xstft, 2);
numChn = size(xstft, 3);
hopLen = winLen - overlap;

% Select the appropriate window based on input
if strcmpi(winType, 'rect')
    win = str2func('ones');
    arg = 1;
else
    win = str2func(winType);
    arg = 'periodic';
end

% Compute IFFT on each frame of the STFT matrix
if bOnlyOla
    xifft = xstft; % sometimes we just want to do OLA
else
    xifft = real(ifft(xstft, fftLen));
end
ifftLen = min(winLen, size(xifft, 1));
xifft   = xifft(1:ifftLen , :, :);

% Apply window
window = win(ifftLen, arg);
xifft  = window .* xifft;

% Reconstruct by Weighted Overlap Add 
x = zeros((numFrm - 1) * hopLen + winLen, numChn);
normFactor = zeros((numFrm - 1) * hopLen + winLen, numChn);
for chn = 1:numChn
    for frm = 1:numFrm
        start = hopLen * (frm - 1) + 1;
        stop  = hopLen * (frm - 1) + winLen;
        x(start:stop, chn) = x(start:stop, chn) + xifft(:, frm, chn);
        normFactor(start:stop, chn) = normFactor(start:stop, chn) + window.^2;
    end
end

% Apply normalization
normFactor(normFactor < 10e-05) = 1;
x = x ./ normFactor;

% Truncate extra zeros from the end
x(end - padLen + 1:end, :) = [];

end