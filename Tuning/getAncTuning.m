function [ancAlgoTune, msrIrTune] = getAncTuning()
%GETANCTUNING Set up tuning parameters for any feedforward and feedback
%ANC algorithms and secondary path IR measurement techniques. 

% For Feedforward FxLMS for ANC
ancAlgoTune.ffstep = 5;
ancAlgoTune.ffleak = 0.0;
ancAlgoTune.ffnormweight = 10;
ancAlgoTune.ffsmoothing  = 0.997;
ancAlgoTune.fffilterLen  = 1024;

% For Feedback FxLMS for ANC
ancAlgoTune.fbstep = 0.15;
ancAlgoTune.fbleak = 0.000001;
ancAlgoTune.fbnormweight = 0.001;
ancAlgoTune.fbsmoothing  = 0.997;
ancAlgoTune.fbfilterLen  = 1024;

% Setup for IR measurement
msrIrTune.lowFreq  = 20; % Hz
msrIrTune.swpTime  = 2;  % sec
msrIrTune.silnTime = 1;  % sec
msrIrTune.filtLen  = 1024;

end