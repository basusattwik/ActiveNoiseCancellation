function y = sinewave(fs, f, amp, phs, T)
%SINEWAVE Generates a composite sinusoidal signal

if nargin < 5
    T = 1;
end
if nargin < 4
    phs = zeros(1, numel(f));
end
if nargin < 3
    amp = zeros(1, numel(f));
end
if nargin < 2
    error('Sinewave needs fs and frequencies');
end
if iscolumn(f)
    f = f.';
end
if iscolumn(amp)
    amp = amp.';
end
if iscolumn(phs)
    phs = phs.';
end

% Generate sinewave
t = (0:1/fs:T-1/fs).';
y = sin(2*pi*f.*t + phs) * amp.';

% Plot signal if no output is requested
if nargout == 0
    plot(t, y);
    xlabel('time (s)'); 
    ylabel('amplitude');
    grid on; grid minor;
    title('Sinewave');
end
end
