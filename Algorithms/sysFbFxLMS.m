classdef sysFbFxLMS < matlab.System
    % SYSFBFXLMS Add summary here
    
    % Public, tunable properties
    properties

        % system setup (NOTE: These are unused. They are there only for
        % compatibility with the constructors of MIMO algorithms)
        numRef = 1;
        numErr = 1;
        numSpk = 1;

        % adaptive filter tuning
        stepsize   = 0.01; % adaptive filter stepsize
        leakage    = 0.001; % adaptive filter leakage
        normweight = 1; % weight for stepsize normalization factor
        smoothing  = 0.999; % exponential smoothing constant
        
        % switches
        bfreezecoeffs(1, 1)logical = false; % bool to freeze coeffients

    end

    % Public, non-tunable properties
    properties(Nontunable)
        filterLen(1, 1){mustBePositive, mustBeInteger} = 512;        % adaptive filter length
        estSecPathFilterLen(1, 1){mustBePositive, mustBeInteger} = 512; % estimated secondary path filter length
    end

    % Public, non-tunable properties
    properties(Nontunable)
        estSecPathCoeff  = [];
        estSecPathCoeff2 = [];

        % Pure feedback architecture
        bFeedback = true;
    end

    properties(DiscreteState)
        filterCoeff; % adaptive FIR filter coefficients
        filterState; % buffered reference signal        
        estSecPathState;  % used for generating filtered reference
        estSecPathState2; % used for estimating the primary noise
        filtRefState;
        estPriNoise;
        powRefHist; % smoothed power of reference signal
    end

    % Pre-computed constants
    properties(Access = private)
        % None
    end

    methods
        % Constructor
        function obj = sysFbFxLMS(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end
    end

    methods(Access = protected)
        %% Common functions

        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
            obj.estSecPathCoeff2 = obj.estSecPathCoeff;
        end
        
        function output = stepImpl(obj, error, output) % inputs should be ref and err
            % Implement algorithm. Calculate y as a function of input u and
            % discrete states.

            % Get estimated primary noise
            obj.estSecPathState2 = [output; obj.estSecPathState2(1:end-1, 1)];
            obj.estPriNoise = error + squeeze(obj.estSecPathCoeff2).' * obj.estSecPathState2;
        
            % Update state vector of adaptive filter and filtered reference signal
            obj.estSecPathState = [obj.estPriNoise; obj.estSecPathState(1:end-1, 1)];
            obj.filterState     = [obj.estPriNoise; obj.filterState(1:end-1, 1)];

            % Get filtered reference signal
            tempFiltOutput   = squeeze(obj.estSecPathCoeff).' * obj.estSecPathState;
            obj.filtRefState = [tempFiltOutput; obj.filtRefState(1:end-1,1)];
        
            % Normalize stepsize
            obj.powRefHist = obj.smoothing * norm(obj.filtRefState) + (1 - obj.smoothing) * obj.powRefHist;
            normstepsize   = obj.stepsize / (1 + obj.normweight * obj.powRefHist);

            % Update filter coefficients using leaky LMS
            if ~obj.bfreezecoeffs
                obj.filterCoeff = obj.filterCoeff * (1 - normstepsize * obj.leakage) + ...
                                                         normstepsize * error * obj.filtRefState;
            end

            % Get output signal
            output = obj.filterCoeff.' * obj.filterState;
        end 

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.filterCoeff      = zeros(obj.filterLen, 1); % adaptive FIR filter coefficients
            obj.filterState      = zeros(obj.filterLen, 1); % buffered reference signal
            obj.filtRefState     = zeros(obj.estSecPathFilterLen, 1);
            obj.estSecPathState  = zeros(obj.estSecPathFilterLen, 1); 
            obj.estSecPathState2 = zeros(obj.estSecPathFilterLen, 1);
            obj.estPriNoise = 0;
            obj.powRefHist  = 0; % smoothed power of reference signal
        end
    end
end
