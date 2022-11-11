classdef classMimoFxLMSFilter < matlab.System
    % CLASSMIMOFXLMSFILTER Add summary here
    
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
        estSecPathCoeff = [];
    end

    properties(DiscreteState)
        filterCoeff;     % adaptive FIR filter coefficients
        filterState;     % buffered reference signal        
        gradient;        % gradient vector per ref x spk
        estSecPathState; % buffered reference signal for sec path filter
        filtRefState;    % buffered sec path filtered reference signal
        powRefHist;      % smoothed power of reference signal
    end

    % Pre-computed constants
    properties(Access = private)
        % None
    end

    methods
        % Constructor
        function obj = classMimoFxLMSFilter(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end
    end

    methods(Access = protected)
        %% Common functions

        function output = stepImpl(obj, input, error) % inputs should be ref and err
            % Implement MIMO FxLMS algorithm. 
       
            % Update state vector of adaptive filter and estimated sec path filter
            obj.estSecPathState = [input ; obj.estSecPathState(1:end-1, :)]; 
            obj.filterState     = [input ; obj.filterState(1:end-1, :)];
            
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
                end % spk loop
            end % ref loop

            % Leaky LMS
            if ~obj.bfreezecoeffs
                % Get normalized stepsize
                normstepsize = obj.stepsize; % ToDo: Figure out normalization 1 / (1 + obj.normweight * obj.powRefHist(ref, spk, mic));

                % Update filter coefficients
                obj.filterCoeff = obj.filterCoeff * (1 - normstepsize * obj.leakage) + normstepsize * obj.gradient;
            end

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
            obj.filterCoeff     = zeros(obj.filterLen, obj.numRef, obj.numSpk);       % adaptive FIR filter coefficients ref x spk
            obj.filterState     = zeros(obj.filterLen, obj.numRef);                   % buffered reference signal
            obj.gradient        = zeros(obj.filterLen, obj.numRef, obj.numSpk);       % gradient vector ref x spk
            obj.filtRefState    = zeros(obj.filterLen, obj.numRef, obj.numSpk, obj.numErr); % buffered sec path filtered reference signal
            obj.estSecPathState = zeros(obj.estSecPathFilterLen, obj.numRef);         % buffered reference signal for sec path filter
            obj.powRefHist      = zeros(obj.numRef, obj.numSpk, obj.numErr);          % smoothed power of reference signal
        end

    end
end
