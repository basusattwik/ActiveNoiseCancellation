classdef sysMimoConv < matlab.System
    % SYSMIMOCONV Add summary here
    %
    % NOTE: When renaming the class name untitled5, the file name
    % and constructor name must be updated to use the class name.
    %
    % This template includes most, but not all, possible properties,
    % attributes, and methods that you can implement for a System object.

    % Public, tunable properties
    properties

    end

    % Public, non-tunable properties
    properties(Nontunable)
        numInp;
        numOut;
        blockLen;
        filters;
    end

    properties(DiscreteState)
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
        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
        end

        function xout = stepImpl(obj, xin)
            % Implement algorithm. Calculate y as a function of input u and
            % discrete states. 
            obj.output(:) = 0;
            for inp = 1:obj.numInp
                for out = 1:obj.numOut
                    obj.output(:, inp) = obj.output(1, inp) + obj.filters{out, inp}(xin(:, out));
                end
            end

            xout = obj.output;
        end

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.output = zeros(obj.blockLen, obj.numInp);
        end
    end
end