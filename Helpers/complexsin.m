function y = complexsin(fs, f, amp, phs, L)
%COMPLEXSIN Generates a composite complex sinusoid.
%   Components of the signal are specified using the elements of arrays f, amp and
%   phs. These three arrays must have the same number of elements. Note
%   that phs is specified in degrees. L is the total duration of the
%   signal in seconds.

% Defaults
if nargin < 5
    L = 1; 
end
if nargin < 4
    phs = zeros(1, numel(f));
end
if nargin < 3
    amp = ones(1, numel(f));
end
if nargin < 2
    error('Complexsin needs atleast fs and frequencies');
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
T = 1/fs;
t = (0:T:L-T).';
y = exp(1j * (2*pi*t*f + deg2rad(phs))) * amp.';

% Plot signal if no output is requested
if nargout == 0
    plot(t, real(y), t, imag(y));
    xlabel('time (s)'); 
    ylabel('amplitude');
    grid on; grid minor;
    legend('Real part', 'Imaginary part');
end

end
