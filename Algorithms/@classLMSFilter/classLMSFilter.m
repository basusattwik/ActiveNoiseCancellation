classdef classLMSFilter < matlab.System
    % CLASSLMSFILTER Add summary here
    
    %
    % This template includes most, but not all, possible properties,
    % attributes, and methods that you can implement for a System object.

    % Public, tunable properties
    properties

        % adaptive filter tuning
        stepsize   = 0.1;
        leakage    = 0.001;
        smoothing  = 0.999; 
        normweight = 1;

    end

    % Public, non-tunable properties
    properties(Nontunable)
        filterlen (1, 1) {mustBePositive, mustBeInteger} = 32; % default value
    end

    properties(DiscreteState)
        coeffs; 
        states;  
        powrefhist;
    end

    % Pre-computed constants
    properties(Access = private)

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
            obj.states = zeros(obj.filterlen, 1);
            obj.coeffs = zeros(obj.filterlen, 1);
            obj.powrefhist = zero(1, 1);
        end

        function [output, error] = stepImpl(obj, ref, des)
            % Implement algorithm. Calculate y as a function of input u and
            % discrete states.

            % Update state vector
            obj.state = [ref; obj.state(1:end-1, 1)];
        
            % Get normalized stepsize
            obj.powrefhist = obj.smoothing * norm(state) + (1 - obj.smoothing) * obj.powrefhist;
            normstepsize   = obj.stepsize / (1 + obj.normweight * obj.powrefhist);
        
            % Get error signal: desired - output
            output = obj.coeffs.' * obj.state;
            error  = des - obj.coeffs.' * output;
        
            % Update filter coefficients
            obj.coeffs = obj.coeffs * (1 - normstepsize * obj.leakage) + normstepsize * error * obj.state;
        end

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.states = zeros(obj.filterlen, 1);
            obj.coeffs = zeros(obj.filterlen, 1);
            obj.powrefhist = zero(1, 1);
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
