classdef classFxLMSFilter < matlab.System
    % CLASSFXLMSFILTER Add summary here
    
    % Public, tunable properties
    properties

        % system setup
        numRef = 1;
        numMic = 1;
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
        estSecPathCoeff = [];
    end

    properties(DiscreteState)
        filterCoeff; % adaptive FIR filter coefficients
        filterState; % buffered reference signal        
        estSecPathState;
        filtRefState;
        powRefHist; % smoothed power of reference signal
    end

    % Pre-computed constants
    properties(Access = private)
        % None
    end

    methods
        % Constructor
        function obj = classFxLMSFilter(varargin)
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

        function output = stepImpl(obj, ref, error) % inputs should be ref and err
            % Implement algorithm. Calculate y as a function of input u and
            % discrete states.

            % Update state vector of adaptive filter
            obj.filterState = [ref;  obj.filterState(1:end-1, 1)];
        
            % Get filtered reference signal
            obj.estSecPathState = [ref; obj.estSecPathState(1:end-1, 1)];
            tempFiltOutput      = obj.estSecPathCoeff.' * obj.estSecPathState;
            obj.filtRefState    = [tempFiltOutput; obj.filtRefState(1:end-1,1)];
        
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
            obj.filterCoeff     = zeros(obj.filterLen, 1); % zeros(obj.numRef, obj.numSpk, obj.filterLen);       % adaptive FIR filter coefficients
            obj.filterState     = zeros(obj.filterLen, 1); %zeros(obj.numRef, obj.numSpk, obj.filterLen); % buffered reference signal
            obj.filtRefState    = zeros(obj.estSecPathFilterLen, 1); % zeros(obj.numRef, obj.estSecPathFilterLen);
            obj.estSecPathState = zeros(obj.estSecPathFilterLen, 1); %zeros(obj.numSpk, obj.numMic, obj.estSecPathFilterLen);
            obj.powRefHist      = 0; % smoothed power of reference signal
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
