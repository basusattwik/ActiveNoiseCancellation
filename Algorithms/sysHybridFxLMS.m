classdef sysHybridFxLMS < matlab.System
    % SYSHYBRIDFXLMS Add summary here
    %
    % NOTE: When renaming the class name untitled2, the file name
    % and constructor name must be updated to use the class name.
    %
    % This template includes most, but not all, possible properties,
    % attributes, and methods that you can implement for a System object.

    % Public, tunable properties
    properties
        % system setup (NOTE: These are unused. They are there only for
        % compatibility with the constructors of MIMO algorithms)
        numRef = 1;
        numErr = 1;
        numSpk = 1;
        
        % adaptive filter tuning
        ffstepsize   = 0.01; % adaptive filter stepsize
        ffleakage    = 0.001; % adaptive filter leakage
        ffnormweight = 1; % weight for stepsize normalization factor
        ffsmoothing  = 0.999; % exponential smoothing constant

        % adaptive filter tuning
        fbstepsize   = 0.01; % adaptive filter stepsize
        fbleakage    = 0.001; % adaptive filter leakage
        fbnormweight = 1; % weight for stepsize normalization factor
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
    % Pre-computed constants
    properties(Access = private)
        ffanc;
        fbanc;
    end

    methods
        % Constructor
        function obj = sysHybridFxLMS(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end
    end

    methods(Access = protected)
        %% Common functions
        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
                obj.ffanc = sysFxLMS('numRef',     obj.numRef, ...
                                     'numErr',     obj.numErr, ...
                                     'numSpk',     obj.numSpk, ...
                                     'stepsize',   obj.ffstepsize,  ...
                                     'leakage',    obj.ffleakage,  ...
                                     'normweight', obj.ffnormweight, ...
                                     'smoothing',  obj.ffsmoothing, ...
                                     'filterLen',  obj.fffilterLen, ...
                                     'estSecPathCoeff', obj.estSecPathCoeff, ...
                                     'estSecPathFilterLen', obj.estSecPathFilterLen);

                obj.fbanc = sysFbFxLMS('numRef',     obj.numRef, ...
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
            % Implement algorithm. Calculate y as a function of input u and
            % discrete states.

            % Call FF and FB ANC algorithm step function
            output = obj.ffanc.step(error, ref) + obj.fbanc.step(error, obj.saveoutput);
            obj.saveoutput = output;
        end

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.ffanc.reset();
            obj.fbanc.reset();
            obj.saveoutput = 0;
        end

    end
end
