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

    end

    properties
        % Adaptive Filter System Objects
        lms;
        fxlms;

        % Acoustic Sim System Objects
        priPath;
        refPath;
        secPath;

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
            obj.priPath = sysMimoConv('numInp',   obj.config.numErr, ...
                                      'numOut',   obj.config.numSrc, ...
                                      'blockLen', obj.config.blockLen, ...
                                      'filters',  obj.paths.priPathFilters);

            obj.secPath = sysMimoConv('numInp',   obj.config.numErr, ...
                                      'numOut',   obj.config.numSpk, ...
                                      'blockLen', obj.config.blockLen, ...
                                      'filters',  obj.paths.secPathFilters);

            obj.refPath = sysMimoConv('numInp',   obj.config.numRef, ...
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

        function obj = measureIr(obj, bCopy)
            %MEASUREIR

            switch bCopy

                case true % Copy coefficients from secondary path IR model

                    for spk = obj.config.numSpk
                        for err = obj.config.numErr
                            obj.fxlms.estSecPathCoeff(spk, err, :) = obj.paths.secPathFilters{spk, err}.Numerator(1:obj.lms.filterLen);
                        end
                    end
                    obj.fxlms.estSecPathFilterLen = numel(obj.paths.secPathFilters{1, 1}.Numerator(1:obj.lms.filterLen));

                case false % Measure IR using LMS 

                % Initialize excitation signal generator
                T   = 10; % 10 sec
                len = obj.config.fs * T;
                noise = dsp.ColoredNoise('white', 'SamplesPerFrame', obj.config.blockLen, 'NumChannels', obj.config.numSpk);
                
                % Adaptively estimate secondary paths
                for i = 1:len
    
                    % Excitation signal
                    x = noise();
                
                    % Simulate secondary path
                    obj.output = obj.secPath.step(x);
                
                    % Call LMS algorithm 
                    obj.lms.step(x, obj.output);
                end
    
                % Set estimated secondary path filters in FxLMS algorithm
                obj.fxlms.estSecPathCoeff     = obj.lms.coeffs;
                obj.fxlms.estSecPathFilterLen = obj.lms.filterLen;
    
                % Reset all buffers
                obj = resetBuffers(obj);
            end
        end

        function [obj, simData] = ancSimCore(obj)
            %ANCSIMCORE

            % Preallocate arrays
            totalSamples  = obj.signals.simTime * obj.config.fs;
            simData.totalSamples  = totalSamples;
            simData.savePrimary   = zeros(totalSamples, obj.config.numErr);
            simData.saveReference = zeros(totalSamples, obj.config.numRef);
            simData.saveError     = zeros(totalSamples, obj.config.numErr);
            simData.saveAntinoise = zeros(totalSamples, obj.config.numErr);
            simData.saveOutput    = zeros(totalSamples, obj.config.numSpk);

            % Wait bar
            wbar = waitbar(0, 'Please wait', 'Name','ANC Simulation...',...
                           'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');

            blockInd = 1:obj.config.blockLen;
            noise = obj.signals.noise;
            for i = 1:obj.signals.simTime * obj.config.fs
        
                % Simulate primary noise
                obj.primary = obj.priPath.step(noise(blockInd, :));
            
                % Calc error i.e. residual noise
                obj.error = obj.primary - obj.antinoise;
            
                % Simulate reference path acoustics
                obj.reference = obj.refPath.step(noise(blockInd, :));
            
                % Call FxLMS algorithm
                obj.output = obj.fxlms.step(obj.reference, obj.error); 
            
                % Simulate secondary path acoustics
                obj.antinoise = obj.secPath.step(obj.output);
                    
                % Save data for analysis
                simData.savePrimary(blockInd, :)   = obj.primary;
                simData.saveReference(blockInd, :) = obj.reference;
                simData.saveError(blockInd, :)     = obj.error;
                simData.saveAntinoise(blockInd, :) = obj.antinoise;
                simData.saveOutput(blockInd, :)    = obj.output;

                % Increment block indices
                blockInd = blockInd + obj.config.blockLen;

                % Update waitbar and message
                if getappdata(wbar, 'canceling')
                    break
                end                
                waitbar(i/totalSamples)
            end

            delete(wbar);
        
            % Save data to struct
            simData.numErr = obj.config.numErr;
            simData.numRef = obj.config.numRef;
            simData.numSrc = obj.config.numSrc;
            simData.numSpk = obj.config.numSpk;

            simData.priPath = obj.paths.priPathFilters;
            simData.refPath = obj.paths.refPathFilters;
            simData.secPath = obj.paths.secPathFilters;

            simData.fs = obj.config.fs;
        end
    end
end