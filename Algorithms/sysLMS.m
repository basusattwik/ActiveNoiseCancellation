classdef sysLMS < matlab.System
    % SYSLMS System object implementation of adaptive LMS algorithm. 

    % Public, tunable properties
    properties

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

        % adaptive filter length
        filterLen(1, 1){mustBePositive, mustBeInteger} = 256; 

        % system setup
        numSpk = 1;
        numErr = 1;
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
            obj.states = [ref; obj.states(1:end-1, 1)];

            % Get output signals
            obj.output = obj.states.' * obj.coeffs;                

            % Run LMS update

            % Get error signal: desired - output
            obj.error = des - obj.output;

            % Get normalized stepsize
            obj.powrefhist = obj.smoothing * sum(obj.states.^2) + (1 - obj.smoothing) * obj.powrefhist;
            normstepsize = obj.stepsize / (1 + obj.normweight * obj.powrefhist); % This can be optimized to avoid divides
                  
            % Update filter coefficients using leaky LMS
            if ~obj.bfreezecoeffs
                obj.coeffs = obj.coeffs * (1 - normstepsize * obj.leakage) + normstepsize * obj.error * obj.states;
            end

        end 

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.states = zeros(obj.filterLen, obj.numSpk);
            obj.coeffs = zeros(obj.filterLen, 1);
            obj.error  = zeros(1, obj.numErr);
            obj.output = zeros(1, obj.numSpk);
            obj.powrefhist = zeros(1, obj.numSpk);
        end
    end
end
