classdef classAncSim
    %CLASSANCSIM Summary of this class goes here
    %   Detailed explanation goes here

    properties
        % System configuration
        config = struct('numSrc', 1, ...
                        'numRef', 1, ...
                        'numErr', 1, ...
                        'numSpk', 1, ...
                        'blockLen', 1, ...
                        'fs', 8000); % ToDo: this is unused now. 
        
        % Acoustic properties
        acoustics = struct('roomDim', [], ...
                           'sources', [], ...
                           'refMics', [], ...
                           'errMics', [], ...
                           'speakers', []);

        % System impulse responses for all acoustic paths
        paths = struct('priPathFilters', [], ...
                       'refPathFilters', [], ...
                       'secPathFilters', []);
  
        % Input signals (sources)
        signals = struct('noise', [], ...
                         'simtime', []);

%         plt = classVisualize;

    end

    properties

        % System Objects
        lms   = classLMSFilter;
        fxlms = classMimoFxLMSFilter; % how to setup?

        % Acoustic sim
        pPath = multiChannelConv;
        rPath = multiChannelConv;
        sPath = multiChannelConv; % How to setup??
    end

    methods
        function obj = classAncSim(filePath)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here

            load(filePath, 'ancSimInput');

            % System config
            obj.config.numSrc = ancSimInput.config.numSrc;
            obj.config.numRef = ancSimInput.config.numRef;
            obj.config.numErr = ancSimInput.config.numErr;
            obj.config.numSpk = ancSimInput.config.numSpk;
            obj.config.fs = ancSimInput.config.fs;
            
            % Acoustic config
            obj.acoustics.roomDim  = ancSimInput.acoustics.roomDim;
            obj.acoustics.sources  = ancSimInput.acoustics.sources;
            obj.acoustics.refMics  = ancSimInput.acoustics.refMics;
            obj.acoustics.errMics  = ancSimInput.acoustics.errMics;
            obj.acoustics.speakers = ancSimInput.acoustics.speakers;
            
            % All IRs
            obj.paths.priPathFilters = ancSimInput.priPathFilters;
            obj.paths.refPathFilters = ancSimInput.refPathFilters;
            obj.paths.secPathFilters = ancSimInput.secPathFilters;
            
            % Input signals (sources)
            obj.signals.noise = ancSimInput.noiseSource;
            obj.signals.simTime = ancSimInput.simTime;

        end

        function obj = setupSystemObj(obj, fxlmsProp, lmsProp)
            %SETUPSYSTEMOBJ

            % Setup FxLMS Algorithm
            obj.fxlms = classMimoFxLMSFilter('numRef',     obj.config.numRef, ...
                                             'numErr',     obj.config.numErr, ...
                                             'numSpk',     obj.config.numSpk, ...
                                             'stepsize',   fxlmsProp.step, ...
                                             'leakage',    fxlmsProp.leak, ...
                                             'normweight', fxlmsProp.normweight, ...
                                             'smoothing',  fxlmsProp.smoothing, ...
                                             'filterLen',  fxlmsProp.filterLen);

            % Setup LMS Algorithm
            obj.lms = classLMSFilter('numSpk',     obj.config.numSpk, ...
                                     'numErr',     obj.config.numErr, ...
                                     'stepsize',   lmsProp.step, ...
                                     'leakage',    lmsProp.leak, ...
                                     'normweight', lmsProp.normweight, ...
                                     'smoothing',  lmsProp.smoothing, ...
                                     'filterLen',  lmsProp.filterLen);

            % Setup Multi-channel convolvers
            obj.pPath = multiChannelConv('numInp',   obj.config.numErr, ...
                                         'numOut',   obj.config.numSrc, ...
                                         'blockLen', obj.config.blockLen, ...
                                         'filters',  obj.paths.priPathFilters);

            obj.sPath = multiChannelConv('numInp',   obj.config.numErr, ...
                                         'numOut',   obj.config.numSpk, ...
                                         'blockLen', obj.config.blockLen, ...
                                         'filters',  obj.paths.secPathFilters);

            obj.rPath = multiChannelConv('numInp',   obj.config.numRef, ...
                                         'numOut',   obj.config.numSrc, ...
                                         'blockLen', obj.config.blockLen, ...
                                         'filters',  obj.paths.refPathFilters);
        end

        function obj = measureIr(obj)

            % Initialize excitation signal
            extime = 10; % 10 sec
            len = obj.config.fs * extime;
            randNoise = randn(len, obj.config.numSpk);
            
            % Adaptively estimate secondary paths
            for i = 1:len
            
                % Simulate secondary path
                output = obj.sPath.step(randNoise(i, :));
            
                % Call LMS algorithm 
                obj.lms.step(randNoise(i,:), output);
            end

            % Set estimated secondary path filters in FxLMS algorithm
            obj.fxlms.estSecPathCoeff = obj.lms.coeffs;

            % Remember to set the sec path filters and filter lengths in MimoFxLMS
        end

        function obj = ancSimCore(obj)
            %ANCSIMCORE
        end
    end
end