function [yn] = wienerFilter(xn, vn, fs, winDur, alpha)
%WIENERFILTER Frequency domain implementation of the optimal Wiener
%filter

sigLen  = length(xn);
winLen  = fix(winDur * fs); % 20 ms
fftLen  = winLen; %2^nextpow2(winLen);
overlap = winLen / 2;

window = hann(winLen, 'periodic');

% Moving indices
hopLen = winLen - overlap;
numWin = fix((sigLen - overlap) / hopLen);

% preallocate memory
yn = zeros((numWin - 1) * hopLen + winLen, 1); % reconstructed filtered signal
nf = zeros((numWin - 1) * hopLen + winLen, 1); % normalization factor
Sxv = zeros(fftLen, 1);
Sxx = zeros(fftLen, 1);

ind = 1:winLen;
for n = 1:numWin
    
    % Break signal into frames and apply window
    xwin  = window .* xn(ind);
    vwin  = window .* vn(ind);

    % Compute PSD and CPSD
    Xw = fft(xwin, fftLen);
    Vw = fft(vwin, fftLen) ;

    Sxx = alpha * Sxx + (1-alpha) * (Xw .* conj(Xw));
    Sxv = alpha * Sxv + (1-alpha) * (Xw .* conj(Vw));

    % Get the Wiener filter
    Hopt = Sxv ./ Sxx;

    % Filter signal
    ytmp = real(ifft(Hopt .* Xw, fftLen));
    ytmp = ytmp(1:winLen);

    % Overlap add
    yn(ind) = yn(ind) + window .* ytmp;
    nf(ind) = nf(ind) + window.^2;

    % Update indices
    ind = ind + hopLen;
end

% Apply normalization
nf(nf < 10e-05) = 1;
yn = yn ./ nf;

end