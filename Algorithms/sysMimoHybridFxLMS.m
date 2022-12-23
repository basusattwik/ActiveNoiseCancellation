classdef sysMimoHybridFxLMS < matlab.System
    % SYSMIMOHYBRIDFXLMS Composite system object for Hybrid ANC that combines feedforward
    % and feedback FxLMS algorithms. This system object supports a MIMO
    % setup.
        % This system object uses 1. sysMimoFxLMS and 2. sysMimoFbFxLMS system
        % objects. 

    % Public, tunable properties
    properties

        % system setup
        numRef = 2;
        numErr = 2;
        numSpk = 2;
        
        % adaptive filter tuning
        ffstepsize   = 0.01;  % adaptive filter stepsize
        ffleakage    = 0.001; % adaptive filter leakage
        ffnormweight = 1;     % weight for stepsize normalization factor
        ffsmoothing  = 0.999; % exponential smoothing constant

        % adaptive filter tuning
        fbstepsize   = 0.01;  % adaptive filter stepsize
        fbleakage    = 0.001; % adaptive filter leakage
        fbnormweight = 1;     % weight for stepsize normalization factor
        fbsmoothing  = 0.999; % exponential smoothing constant
    end

    % Public, non-tunable properties
    properties(Nontunable)
        fffilterLen(1, 1){mustBePositive, mustBeInteger} = 512;           % Feedforward adaptive filter length
        fbfilterLen(1, 1){mustBePositive, mustBeInteger} = 512;           % Feedback adaptive filter length
        estSecPathFilterLen(1, 1){mustBePositive, mustBeInteger} = 512;   % estimated secondary path filter length
    end

    % Public, non-tunable properties
    properties(Nontunable)
        estSecPathCoeff  = [];

        % Pure feedback architecture
        bFeedback = false;
    end

    properties(DiscreteState)
        saveoutput;
    end

    % System objects for FF and FB ANC
    properties(Access = private)
        ffanc;
        fbanc;
    end

    methods
        % Constructor
        function obj = sysMimoHybridFxLMS(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end
    end

    methods(Access = protected)
        %% Common functions
        function setupImpl(obj)
            % Perform one-time setup for FF and FB ANC algorithms
            obj.ffanc = sysMimoFxLMS('numRef',     obj.numRef, ...
                                     'numErr',     obj.numErr, ...
                                     'numSpk',     obj.numSpk, ...
                                     'stepsize',   obj.ffstepsize,  ...
                                     'leakage',    obj.ffleakage,   ...
                                     'normweight', obj.ffnormweight, ...
                                     'smoothing',  obj.ffsmoothing, ...
                                     'filterLen',  obj.fffilterLen, ...
                                     'estSecPathCoeff', obj.estSecPathCoeff, ...
                                     'estSecPathFilterLen', obj.estSecPathFilterLen);

            obj.fbanc = sysMimoFbFxLMS('numRef',     obj.numRef, ...
                                       'numErr',     obj.numErr, ...
                                       'numSpk',     obj.numSpk, ...
                                       'stepsize',   obj.fbstepsize, ...
                                       'leakage',    obj.fbleakage,  ...
                                       'normweight', obj.fbnormweight, ...
                                       'smoothing',  obj.fbsmoothing, ...
                                       'filterLen',  obj.fbfilterLen, ...
                                       'estSecPathCoeff', obj.estSecPathCoeff, ...
                                       'estSecPathFilterLen', obj.estSecPathFilterLen);
        end

        function output = stepImpl(obj, error, ref)
            % Implement MIMO Hybrid FxLMS algorithm

            % Run FF and FB ANC algorithms and produce combined output
            output = obj.ffanc.step(error, ref) + obj.fbanc.step(error, obj.saveoutput);
            obj.saveoutput = output;
        end

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.ffanc.reset();
            obj.fbanc.reset();
            obj.saveoutput = zeros(1, obj.numSpk);
        end

    end
end
