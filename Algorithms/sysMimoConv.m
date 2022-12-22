classdef sysMimoConv < matlab.System
    % SYSMIMOCONV Multichannnel convolver to simulate the acoustics of a 
    % MIMO speaker/source and microphone arrangement. The output from each
    % speaker/souce is convolved with an impulse response and summed at
    % each microphone. 

    % Public, non-tunable properties
    properties(Nontunable)
        numMic;
        numSrc;
        blockLen;
        filters; % pre-measured impulse responses
    end

    properties(DiscreteState)
        % Total output for all microphones
        output; 
    end

    % Pre-computed constants
    properties(Access = private)
        
    end

    methods
        % Constructor
        function obj = sysMimoConv(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end
    end

    methods(Access = protected)
        %% Common functions
        function xout = stepImpl(obj, xin)
            % Implement multichannel convolutionn algorithm. 
            obj.output(:) = 0;
            for mic = 1:obj.numMic
                for src = 1:obj.numSrc
                    obj.output(:, mic) = obj.output(:, mic) + obj.filters{src, mic}(xin(:, src));
                end
            end

            % Combined output from all speakers at each microphone
            xout = obj.output;
        end

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.output = zeros(obj.blockLen, obj.numMic);
            for inp = 1:obj.numMic
                for out = 1:obj.numSrc
                    reset(obj.filters{out, inp});
                end
            end
        end
    end
end
