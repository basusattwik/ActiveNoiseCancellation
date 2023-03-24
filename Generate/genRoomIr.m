function h = genRoomIr(c, fs, rx, sr, L, beta, n, mictype, order, dim, micorient, hpf)
%GENROOMIR Generates a realistic room impulse response using the Image-Source
%method by J.B. Allen and D.A. Berkley
%   This function uses a mex file created from the room impulse response
%   generator written by Dr. Emanuel Habets from Audio Labs Erlangen. 
%   https://www.audiolabs-erlangen.de/fau/professor/habets/software/rir-generator
%
%   Input arguments:
%   c           Sound velocity (m/s)
%   fs          Sample frequency (samples/s)
%   r           Receiver position [x y z] (m)
%   s           Source position   [x y z] (m)
%   L           Room dimensions   [x y z] (m)
%   n           Number of samples
%   beta        Reverberation time (s)
%   mictype     Type of microphone
%   order       -1 equals maximum reflection order!
%   dim         Room dimension
%   micorient   Microphone orientation (rad)
%   hpf         Disable high-pass filter
%   
%   Outputs:
%   h           Generated room impulse response

if nargin > 12
    error('Too many input arguments');
end
if nargin < 12
    hpf = true;
end
if nargin < 11
    micorient = [];
end
if nargin < 10
    dim = [];
end
if nargin < 9
    order = [];
end
if nargin < 8
    mictype = [];
end
if nargin < 7
    beta = [];
end
if nargin < 6
    error('A minimum of 6 arguments is required');
end
% ToDo: Can I use varagin?

h = rir_generator(c, fs, rx, sr, L, beta, n, mictype, order, dim, micorient, hpf);

end