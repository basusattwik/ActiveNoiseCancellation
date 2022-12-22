function [coeffs] = genBandPassTransferFunction(N, flow, fhigh, delay, Ast, ford, fs)
%GENBANDPASSTRANSFERFUNCTION Generate a simple impulse response using
%bandpass filtered random noise.

% Design bandpass filter to generate bandlimited impulse response
specs  = fdesign.bandpass('N,Fst1,Fst2,Ast', ford, flow, fhigh, Ast, fs);
bpfilt = design(specs,'cheby2','FilterStructure','df2tsos', ...
                       'SystemObject',true);

% Filter noise to generate impulse response
coeffs = bpfilt([zeros(delay,1); ...
                              log(0.99 * rand(N-delay, 1) + 0.01) .* ...
                              sign(randn(N - delay, 1)) .* exp(-0.01 * (1:N-delay)')]);

coeffs = coeffs / norm(coeffs);

end