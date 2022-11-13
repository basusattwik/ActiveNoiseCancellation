classdef classAncSim
    %CLASSANCSIM Summary of this class goes here
    %   Detailed explanation goes here

    properties
        % System configuration
        config = struct('numSrc', 1, ...
                        'numRef', 1, ...
                        'numErr', 1, ...
                        'numSpk', 1, ...
                        'blockLen', 1, ... % ToDo: this is unused now.
                        'fs', 8000);  
        
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

        % Class plot data
        plt = classAncPlots;

    end

    properties
        % System Objects
        lms;
        fxlms; % how to setup?

        % Acoustic sim
        pPath;
        rPath;
        sPath; % How to setup??

        % Buffers
        primary;
        error;
        antinoise;
        reference;
        output;
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
            %SETUPSYSTEMObj

            % Setup FxLMS Algorithm
            obj.fxlms = sysMimoFxLMS('numRef',     obj.config.numRef, ...
                                     'numErr',     obj.config.numErr, ...
                                     'numSpk',     obj.config.numSpk, ...
                                     'stepsize',   fxlmsProp.step, ...
                                     'leakage',    fxlmsProp.leak, ...
                                     'normweight', fxlmsProp.normweight, ...
                                     'smoothing',  fxlmsProp.smoothing, ...
                                     'filterLen',  fxlmsProp.filterLen);

            % Setup LMS Algorithm
            obj.lms = sysLMS('numSpk',     obj.config.numSpk, ...
                             'numErr',     obj.config.numErr, ...
                             'stepsize',   lmsProp.step, ...
                             'leakage',    lmsProp.leak, ...
                             'normweight', lmsProp.normweight, ...
                             'smoothing',  lmsProp.smoothing, ...
                             'filterLen',  lmsProp.filterLen);

            % Setup Multi-channel convolvers
            obj.pPath = sysMimoConv('numInp',   obj.config.numErr, ...
                                    'numOut',   obj.config.numSrc, ...
                                    'blockLen', obj.config.blockLen, ...
                                    'filters',  obj.paths.priPathFilters);

            obj.sPath = sysMimoConv('numInp',   obj.config.numErr, ...
                                    'numOut',   obj.config.numSpk, ...
                                    'blockLen', obj.config.blockLen, ...
                                    'filters',  obj.paths.secPathFilters);

            obj.rPath = sysMimoConv('numInp',   obj.config.numRef, ...
                                    'numOut',   obj.config.numSrc, ...
                                    'blockLen', obj.config.blockLen, ...
                                    'filters',  obj.paths.refPathFilters);
        end

        function obj = resetBuffers(obj)
            %RESETBUFFERS

            % Initialize all buffers
            obj.primary   = zeros(obj.config.blockLen, obj.config.numErr);
            obj.error     = zeros(obj.config.blockLen, obj.config.numErr);
            obj.antinoise = zeros(obj.config.blockLen, obj.config.numErr);
            obj.reference = zeros(obj.config.blockLen, obj.config.numRef);
            obj.output    = zeros(obj.config.blockLen, obj.config.numSpk);
        end

        function obj = measureIr(obj)
            %MEASUREIR

            % Initialize excitation signal generator
            T   = 10; % 10 sec
            len = obj.config.fs * T;
            noise = dsp.ColoredNoise('white', 'SamplesPerFrame', obj.config.blockLen, 'NumChannels', obj.config.numSpk);
            
            % Adaptively estimate secondary paths
            for i = 1:len

                % Excitation signal
                x = noise();
            
                % Simulate secondary path
                obj.output = obj.sPath.step(x);
            
                % Call LMS algorithm 
                obj.lms.step(x, obj.output);
            end

            % Set estimated secondary path filters in FxLMS algorithm
            obj.fxlms.estSecPathCoeff = obj.lms.coeffs;
            obj.fxlms.estSecPathFilterLen = obj.lms.filterLen;

            % Reset all buffers
            obj = resetBuffers(obj);
        end

        function obj = ancSimCore(obj)
            %ANCSIMCORE

            noise = obj.signals.noise;

            for i = 1:obj.signals.simTime * obj.config.fs
        
                % Simulate primary noise
                obj.primary = obj.pPath.step(noise(i, :));
            
                % Calc error i.e. residual noise
                obj.error = obj.primary - obj.antinoise;
            
                % Simulate reference path acoustics
                obj.reference = obj.rPath.step(noise(i, :));
            
                % Call FxLMS algorithm
                obj.output = obj.fxlms(obj.reference, obj.error); 
            
                % Simulate secondary path acoustics
                obj.antinoise = obj.sPath.step(obj.output);
                    
            end
        end
    end
end