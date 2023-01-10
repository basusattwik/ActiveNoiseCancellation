classdef sysMimoFbFxLMS < matlab.System
    % SYSMIMOFBFXLMS System object implementation of adaptive feedback FxLMS
    % algorithm. This system object supports a MIMO setup.
    
    % Public, tunable properties
    properties

        % system setup
        numRef = 2;
        numErr = 2;
        numSpk = 2;

        % adaptive filter tuning
        stepsize   = 0.01;  % adaptive filter stepsize
        leakage    = 0.001; % adaptive filter leakage
        normweight = 1;     % weight for stepsize normalization factor
        smoothing  = 0.999; % exponential smoothing constant
        
        % switches
        bfreezecoeffs(1, 1)logical = false; % bool to freeze coeffients

    end

    % Public, non-tunable properties
    properties(Nontunable)
        filterLen(1, 1){mustBePositive, mustBeInteger} = 512;           % adaptive filter length
        estSecPathFilterLen(1, 1){mustBePositive, mustBeInteger} = 512; % estimated secondary path filter length
    end

    % Public, non-tunable properties
    properties(Nontunable)
        estSecPathCoeff  = [];
        estSecPathCoeff2 = [];
        
        % Feedback architecture
        bFeedback = true;
    end

    properties(DiscreteState)
        filterCoeff;      % adaptive FIR filter coefficients
        filterState;      % buffered reference signal        
        gradient;         % gradient vector per ref x spk
        estSecPathState;  % buffered reference signal for sec path filter
        estSecPathState2; % used for estimating the primary noise
        filtRefState;     % buffered sec path filtered reference signal
        estPriNoise;      % estimated primary noise, used to generated reference
        estAntinoise;     % estimated antinoise at the error microphones
        powRefHist;       % smoothed power of reference signal
    end

    % Pre-computed constants
    properties(Access = private)
        % None
    end

    methods
        % Constructor
        function obj = sysMimoFbFxLMS(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end
    end

    methods(Access = protected)
        %% Common functions

        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
            obj.estSecPathCoeff2 = obj.estSecPathCoeff;

            % Note that references are synthesized, so they are equal to
            % numErr
            obj.numRef = obj.numErr;
        end

        function output = stepImpl(obj, error, output) 
            % Implement MIMO Feedback FxLMS algorithm. 
       
            % Get estimated antinoise at the error microphones
            obj.estSecPathState2 = [output; obj.estSecPathState2(1:end-1, :)];
            obj.estAntinoise(:)  = 0; % clear out previous values
            for mic = 1:obj.numErr
                for spk = 1:obj.numSpk
                    obj.estAntinoise(1, mic) = obj.estAntinoise(1, mic) + squeeze(obj.estSecPathCoeff2(spk, mic, :)).' * obj.estSecPathState2(:, spk);
                end
            end

            % Get estimated primary noise
            obj.estPriNoise = error + obj.estAntinoise;

            % Update state vector of adaptive filter and estimated sec path filter
            obj.estSecPathState = [obj.estPriNoise ; obj.estSecPathState(1:end-1, :)]; 
            obj.filterState     = [obj.estPriNoise ; obj.filterState(1:end-1, :)];
            
            for ref = 1:obj.numRef             
                for spk = 1:obj.numSpk           
                    for mic = 1:obj.numErr

                        % Get filtered reference signal
                        estSecPathFiltOutput = squeeze(obj.estSecPathCoeff(spk, mic, :)).' * obj.estSecPathState(:, ref);

                        % Update state vector for filtered reference
                        obj.filtRefState(:, ref, spk, mic) = [estSecPathFiltOutput ; squeeze(obj.filtRefState(1:end-1, ref, spk, mic))];

                        % Get power of filtered reference 
                        obj.powRefHist(ref, spk, mic) = obj.smoothing * sum(squeeze(obj.filtRefState(:, ref, spk, mic)).^2) ...
                                                                      + (1 - obj.smoothing) * obj.powRefHist(ref, spk, mic);  

                        % Get total gradient
                        obj.gradient(:, ref, spk) = obj.gradient(:, ref, spk) + error(1, mic) * squeeze(obj.filtRefState(:, ref, spk, mic));

                    end % mic loop

                    % Leaky LMS
                    if ~obj.bfreezecoeffs
                        % Get normalized stepsize
                        normstepsize = obj.stepsize / (1 + obj.normweight * mean(obj.powRefHist(ref, spk, :), 3));
        
                        % Update filter coefficients
                        obj.filterCoeff(:, ref, spk) = obj.filterCoeff(:, ref, spk) * (1 - normstepsize * obj.leakage) ...
                                                                                         + normstepsize * obj.gradient(:, ref, spk);
                    end
                end % spk loop
            end % ref loop

            % Get total output for all speakers
            output = zeros(1, obj.numSpk);
            for spk = 1:obj.numSpk
                for ref = 1:obj.numRef
                    output(1, spk) = output(1, spk) + squeeze(obj.filterCoeff(:, ref, spk)).' * obj.filterState(:, ref);
                end
            end

            % Clear gradients
            obj.gradient(:) = 0;
        end 

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.filterCoeff      = zeros(obj.filterLen, obj.numRef, obj.numSpk);       % adaptive FIR filter coefficients ref x spk
            obj.filterState      = zeros(obj.filterLen, obj.numRef);                   % buffered reference signal
            obj.gradient         = zeros(obj.filterLen, obj.numRef, obj.numSpk);       % gradient vector ref x spk
            obj.filtRefState     = zeros(obj.filterLen, obj.numRef, obj.numSpk, obj.numErr); % buffered sec path filtered reference signal
            obj.estSecPathState  = zeros(obj.estSecPathFilterLen, obj.numRef);         % buffered reference signal for sec path filter
            obj.estSecPathState2 = zeros(obj.estSecPathFilterLen, obj.numSpk);         % buffered output signal for sec path filter
            obj.estPriNoise      = zeros(1, obj.numErr);                               % estimated primary noise at the error mics
            obj.estAntinoise     = zeros(1, obj.numErr);                               % estimated antinoise at the error mics
            obj.powRefHist       = zeros(obj.numRef, obj.numSpk, obj.numErr);          % smoothed power of reference signal
        end

    end
end
