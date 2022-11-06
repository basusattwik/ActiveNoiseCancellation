classdef classLMSFilter < matlab.System
    % CLASSLMSFILTER Add summary here

    % Public, tunable properties
    properties

        % system setup
        numRef = 1;
        numErr = 1;

        % adaptive filter tuning
        stepsize   = []; % adaptive filter stepsize
        leakage    = []; % adaptive filter leakage
        normweight = []; % weight for stepsize normalization factor
        smoothing  = 0.999; % exponential smoothing constant
        
        % switches
        bfreezecoeffs(1, 1)logical = false; % bool to freeze coeffients

    end

    % Public, non-tunable properties
    properties(Nontunable)
        filterlen(1, 1){mustBePositive, mustBeInteger} = 256; % adaptive filter length
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
        function obj = classLMSFilter(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end
    end

    methods(Access = protected)
        %% Common functions
        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
            % None
        end

        function stepImpl(obj, ref, des)
            % Implement algorithm. Calculate y as a function of input u and
            % discrete states.

            % Update state vector
            obj.states = [ref; obj.states(1:end-1, :)];

            % Get output signals
            for mic = 1:obj.numErr
                for ref = 1:obj.numRef
                    obj.output(mic, ref) = squeeze(obj.coeffs(ref, mic, :)).' * obj.states(:, ref);                
                end
            end

            % Run LMS update
            for mic = 1:obj.numErr
                for ref = 1:obj.numRef
                
                % Get error signal: desired - output
                obj.error(1, mic) = des(1, mic) - sum(obj.output(mic, :));

                % Get normalized stepsize
                obj.powrefhist(1, ref) = obj.smoothing * norm(obj.states(:, ref)) + (1 - obj.smoothing) * obj.powrefhist(1, ref);
                normstepsize = obj.stepsize(1, mic) / (1 + obj.normweight(1, mic) * obj.powrefhist(1, ref)); % This can be optimized to avoid divides
                      
                % Update filter coefficients using leaky LMS
                if ~obj.bfreezecoeffs
                    obj.coeffs(ref, mic, :) = squeeze(obj.coeffs(ref, mic, :)) * (1 - normstepsize * obj.leakage) ...
                                                                                    + normstepsize * obj.error(1, mic) * obj.states(:, ref);
                end

                end % chn loop
            end % mic loop
        end 

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.states = zeros(obj.filterlen, obj.numRef);
            obj.coeffs = zeros(obj.numRef, obj.numErr, obj.filterlen);
            obj.error  = zeros(1, obj.numErr);
            obj.output = zeros(obj.numErr, obj.numRef);
            obj.powrefhist = zeros(1, obj.numRef);
        end

        %% Backup/restore functions
        function s = saveObjectImpl(obj)
            % Set properties in structure s to values in object obj

            % Set public properties and states
            s = saveObjectImpl@matlab.System(obj);

            % Set private and protected properties
            %s.myproperty = obj.myproperty;
        end

        function loadObjectImpl(obj,s,wasLocked)
            % Set properties in object obj to values in structure s

            % Set private and protected properties
            % obj.myproperty = s.myproperty; 

            % Set public properties and states
            loadObjectImpl@matlab.System(obj,s,wasLocked);
        end

        %% Advanced functions
        function validateInputsImpl(obj,u)
            % Validate inputs to the step method at initialization
        end

        function validatePropertiesImpl(obj)
            % Validate related or interdependent property values
        end

        function ds = getDiscreteStateImpl(obj)
            % Return structure of properties with DiscreteState attribute
            ds = struct([]);
        end

        function processTunedPropertiesImpl(obj)
            % Perform actions when tunable properties change
            % between calls to the System object
        end

        function flag = isInputSizeMutableImpl(obj,index)
            % Return false if input size cannot change
            % between calls to the System object
            flag = false;
        end

        function flag = isInactivePropertyImpl(obj,prop)
            % Return false if property is visible based on object 
            % configuration, for the command line and System block dialog
            flag = false;
        end
    end
end
