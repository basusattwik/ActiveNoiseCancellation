classdef sysLMS < matlab.System
    % SYSLMS System object implementation of adaptive LMS algorithm. 
    % This system object supports a MIMO setup.

    % Public, tunable properties
    properties

        % system setup
        numSpk = 1;
        numErr = 1;

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
        filterLen(1, 1){mustBePositive, mustBeInteger} = 256; % adaptive filter length
    end

    properties(DiscreteState)
        coeffs; % adaptive FIR filter coefficients
        states; % buffered reference signal
        error;  % error signal
        output; % output of each adaptive filter
        powrefhist; % smoothed power of reference signal
    end

    % Pre-computed constants
    properties(Access = private)
        % None
    end

    methods
        % Constructor
        function obj = sysLMS(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end
    end

    methods(Access = protected)
        %% Common functions

        function stepImpl(obj, ref, des)
            % Implement algorithm. Calculate y as a function of input u and
            % discrete states.

            % Update state vector
            obj.states = [ref; obj.states(1:end-1, :)];

            % Get output signals
            for mic = 1:obj.numErr
                for spk = 1:obj.numSpk
                    obj.output(mic, spk) = obj.states(:, spk).' * reshape(obj.coeffs(spk, mic, :), [obj.filterLen, 1]);                
                end
            end

            % Run LMS update
            for mic = 1:obj.numErr

                % Get error signal: desired - output % ToDo: Can move to outer loop
                obj.error(1, mic) = des(1, mic) - sum(obj.output(mic, :));

                for spk = 1:obj.numSpk

                % Get normalized stepsize
                obj.powrefhist(1, spk) = obj.smoothing * sum(obj.states(:, spk).^2) + (1 - obj.smoothing) * obj.powrefhist(1, spk);
                normstepsize = obj.stepsize / (1 + obj.normweight * obj.powrefhist(1, spk)); % This can be optimized to avoid divides
                      
                % Update filter coefficients using leaky LMS
                if ~obj.bfreezecoeffs
                    obj.coeffs(spk, mic, :) = reshape(obj.coeffs(spk, mic, :), [obj.filterLen, 1]) * (1 - normstepsize * obj.leakage) ...
                                                                                    + normstepsize * obj.error(1, mic) * obj.states(:, spk);
                end

                end % spk loop
            end % mic loop
        end 

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.states = zeros(obj.filterLen, obj.numSpk);
            obj.coeffs = zeros(obj.numSpk, obj.numErr, obj.filterLen);
            obj.error  = zeros(1, obj.numErr);
            obj.output = zeros(obj.numErr, obj.numSpk);
            obj.powrefhist = zeros(1, obj.numSpk);
        end
    end
end
