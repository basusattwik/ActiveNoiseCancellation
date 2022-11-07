classdef classMimoFxLMSFilter < matlab.System
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
        function obj = classMimoFxLMSFilter(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end
    end

    methods(Access = protected)
        %% Common functions

        function output = stepImpl(obj, input, error) % inputs should be ref and err
            % Implement algorithm. Calculate y as a function of input u and
            % discrete states.

            output = 0;
        
            for ref = 1:obj.numRef             
                for spk = 1:obj.numSpk           
                    for mic = 1:obj.numMic

                        % Get filtered reference signal
                        obj.estSecPathState(ref, spk, mic, :) = [input(1, ref); squeeze(obj.estSecPathState(ref, spk, mic, 1:end-1))];
                        tempFiltOutput = squeeze(obj.estSecPathCoeff(spk, mic, :)).' * squeeze(obj.estSecPathState(ref, spk, mic, :));
                        obj.filtRefState(ref, spk, mic, :) = [tempFiltOutput; squeeze(obj.filtRefState(ref, spk, mic, 1:end-1))];

                        % Normalize stepsize
                        obj.powRefHist(1, ref) = obj.smoothing * norm(squeeze(obj.filtRefState(ref, spk, mic, :))) + (1 - obj.smoothing) * obj.powRefHist(1, ref);
                        normstepsize = obj.stepsize / (1 + obj.normweight * obj.powRefHist(1, ref));

                        % Update filter coefficients using leaky LMS
                        if ~obj.bfreezecoeffs
                            obj.filterCoeff(spk, mic, :) = squeeze(obj.filterCoeff(spk, mic, :)) * (1 - normstepsize * obj.leakage) + ...
                                                                    normstepsize * error(1, mic) * squeeze(obj.filtRefState(ref, spk, mic, :));
                        end

                        % Update state vector of adaptive filter
                        obj.filterState(:, ref)  = [input(1, ref); obj.filterState(1:end-1, ref)];
            
                        % Get output signal
                        output = output + squeeze(obj.filterCoeff(ref, spk, :)).' * obj.filterState(:, ref);

                    end % mic loop
                end % spk loop
            end % ref loop
        end 

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.filterCoeff     = zeros(obj.numRef, obj.numSpk, obj.filterLen);       % adaptive FIR filter coefficients
            obj.filterState     = zeros(obj.filterLen, obj.numRef);                   % buffered reference signal
            obj.filtRefState    = zeros(obj.numRef, obj.numSpk, obj.numMic, obj.estSecPathFilterLen); % buffered sec path filtered reference signal
            obj.estSecPathState = zeros(obj.numRef, obj.numSpk, obj.numMic, obj.estSecPathFilterLen); % buffered reference signal for sec path filter
            obj.powRefHist      = zeros(1, obj.numRef); % smoothed power of reference signal
        end

    end
end
