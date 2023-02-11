function imp = genRirFilters(params, bNorm, bUnity)
%GENRIRFILTERS Function to setup system objects to simulate the primary,
%reference and secondary path acoustics

if nargin < 2
    bNorm = false;
end
if nargin < 3
    bUnity = false;
end

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

if ~bUnity
    for src = 1:numSrcs
        for mic = 1:numMics
            h = genRoomIr(speed, fs, micPos(mic, :), srcPos(src, :), L, beta, n);
            if bNorm
                h = h ./ max(abs(h));
            end
            imp{src, mic} = dsp.FIRFilter(h);
        end
    end
else
    for src = 1:numSrcs
        for mic = 1:numMics
            h = zeros(1,n);
            h(1) = 1;
            if bNorm
                h = h ./ max(abs(h));
            end
            imp{src, mic} = dsp.FIRFilter(h);
        end
    end
end