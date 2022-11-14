function imp = genRirFilters(params)
%GENRIRFILTERS Summary of this function goes here
%   Detailed explanation goes here

numSrcs = size(params.srcPos, 1);
numMics = size(params.micPos, 1);
fs      = params.fs;
srcPos  = params.srcPos;              % Source position   [x y z] (m)
micPos  = params.micPos;              % Receiver position [x y z] (m)
speed   = params.c;                   % Sound velocity (m/s)
beta    = params.beta;                % Reverberation time (s)
n       = params.n;                   % Number of samples
L       = params.L;                   % Room dimensions [x y z] (m)

imp = cell(numSrcs, numMics);
for src = 1:numSrcs
    for mic = 1:numMics
        h = genRoomIr(speed, fs, micPos(mic, :), srcPos(src, :), L, beta, n);
        h = h ./ max(abs(h));
        imp{src, mic} = dsp.FIRFilter(h);
    end
end
end