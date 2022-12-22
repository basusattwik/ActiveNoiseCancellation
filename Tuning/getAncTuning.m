function [ancAlgoTune, msrIrTune] = getAncTuning()
%GETANCTUNING Set up tuning parameters for any feedforward and feedback
%ANC algorithms and secondary path IR measurement techniques. 

% For Feedforward FxLMS for ANC
ancAlgoTune.ffstep = 0.6;
ancAlgoTune.ffleak = 0.0001;
ancAlgoTune.ffnormweight = 0.01;
ancAlgoTune.ffsmoothing  = 0.997;
ancAlgoTune.fffilterLen  = 300;

% For Feedback FxLMS for ANC
ancAlgoTune.fbstep = 0.1;
ancAlgoTune.fbleak = 0.001;
ancAlgoTune.fbnormweight = 0.001;
ancAlgoTune.fbsmoothing  = 0.997;
ancAlgoTune.fbfilterLen  = 300;

% Setup for IR measurement
msrIrTune.lowFreq  = 20; % Hz
msrIrTune.swpTime  = 2;  % sec
msrIrTune.silnTime = 1;  % sec
msrIrTune.filtLen  = 300;

end