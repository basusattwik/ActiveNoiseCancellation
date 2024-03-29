classdef classAncSim
    %CLASSANCSIM Class to manage all the components of running a simulation
    %   This class handles setup of all algorithm system objects, measuring
    %   secondary path and simulating active noise cancellation. 
    %   The required inputs are a simulation input .mat file and algorithm
    %   tuning.

    properties
        % System configuration
        config = struct('numSrc', 1, ...
                        'numRef', 1, ...
                        'numErr', 1, ...
                        'numSpk', 1, ...
                        'blockLen', 1, ... % ToDo: this is unused at the moment.
                        'fs', 3000);  
        
        % Acoustic properties
        acoustics = struct('roomDim', [], ...
                           'sources', [], ...
                           'refMics', [], ...
                           'errMics', [], ...
                           'speakers', [], ...
                           'bSimheadphones', [], ...
                           'lpfCutoff', [], ...
                           'lpfOrder',  []);

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
        ancAlgo;

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
            %CLASSANCSIM Constructor to initialize all simulation
            %componentss
            %   Loads the input .mat file and assigns appropriate values to
            %   class properties. 

            load(filePath, 'ancSimInput'); % TODO: Add checks to make sure file exists. 

            disp('Starting simulation ...');
            disp(['Speakers: ',   num2str(ancSimInput.config.numSpk), ', ', ...
                  'Error Mics: ', num2str(ancSimInput.config.numErr), ', ', ...
                  'Ref Mics: ',   num2str(ancSimInput.config.numRef), ', ', ...
                  'Sources: ',    num2str(ancSimInput.config.numSrc)]);

            % System config
            obj.config.numSrc = ancSimInput.config.numSrc;
            obj.config.numRef = ancSimInput.config.numRef;
            obj.config.numErr = ancSimInput.config.numErr;
            obj.config.numSpk = ancSimInput.config.numSpk;
            obj.config.fs     = ancSimInput.config.fs;
            
            % Acoustic config
            obj.acoustics.roomDim   = ancSimInput.acoustics.roomDim;
            obj.acoustics.sources   = ancSimInput.acoustics.sources;
            obj.acoustics.refMics   = ancSimInput.acoustics.refMics;
            obj.acoustics.errMics   = ancSimInput.acoustics.errMics;
            obj.acoustics.speakers  = ancSimInput.acoustics.speakers;
            obj.acoustics.lpfCutoff = ancSimInput.acoustics.lpfCutoff;
            obj.acoustics.lpfOrder  = ancSimInput.acoustics.lpfOrder;
            obj.acoustics.bSimheadphones = ancSimInput.acoustics.bSimheadphones;
            
            % All IRs
            obj.paths.priPathFilters = ancSimInput.priPathFilters;
            obj.paths.refPathFilters = ancSimInput.refPathFilters;
            obj.paths.secPathFilters = ancSimInput.secPathFilters;
            
            % Input signals (sources)
            obj.signals.noise   = ancSimInput.noiseSource;
            obj.signals.simTime = ancSimInput.simTime;
        end

        function obj = setupSystemObj(obj, ancAlgo, ancAlgoTune)
            %SETUPSYSTEMObj

            % Setup ANC Algorithm
            if strcmpi(func2str(ancAlgo), 'sysFxLMS') || strcmpi(func2str(ancAlgo), 'sysMimoFxLMS')

                obj.ancAlgo = ancAlgo('numRef',     obj.config.numRef, ...
                                      'numErr',     obj.config.numErr, ...
                                      'numSpk',     obj.config.numSpk, ...
                                      'stepsize',   ancAlgoTune.ffstep,  ...
                                      'leakage',    ancAlgoTune.ffleak,  ...
                                      'normweight', ancAlgoTune.ffnormweight, ...
                                      'smoothing',  ancAlgoTune.ffsmoothing, ...
                                      'filterLen',  ancAlgoTune.fffilterLen);

            elseif strcmpi(func2str(ancAlgo), 'sysFbFxLMS') || strcmpi(func2str(ancAlgo), 'sysMimoFbFxLMS')

                obj.ancAlgo = ancAlgo('numRef',     obj.config.numRef, ...
                                      'numErr',     obj.config.numErr, ...
                                      'numSpk',     obj.config.numSpk, ...
                                      'stepsize',   ancAlgoTune.fbstep,  ...
                                      'leakage',    ancAlgoTune.fbleak,  ...
                                      'normweight', ancAlgoTune.fbnormweight, ...
                                      'smoothing',  ancAlgoTune.fbsmoothing, ...
                                      'filterLen',  ancAlgoTune.fbfilterLen);

            elseif strcmpi(func2str(ancAlgo), 'sysHybridFxLMS')  || strcmpi(func2str(ancAlgo), 'sysMimoHybridFxLMS')
                
                obj.ancAlgo = ancAlgo('numRef',       obj.config.numRef, ...
                                      'numErr',       obj.config.numErr, ...
                                      'numSpk',       obj.config.numSpk, ...
                                      'ffstepsize',   ancAlgoTune.ffstep,  ...
                                      'ffleakage',    ancAlgoTune.ffleak,  ...
                                      'ffnormweight', ancAlgoTune.ffnormweight, ...
                                      'ffsmoothing',  ancAlgoTune.ffsmoothing, ...
                                      'fffilterLen',  ancAlgoTune.fffilterLen, ...
                                      'fbstepsize',   ancAlgoTune.fbstep,  ...
                                      'fbleakage',    ancAlgoTune.fbleak,  ...
                                      'fbnormweight', ancAlgoTune.fbnormweight, ...
                                      'fbsmoothing',  ancAlgoTune.fbsmoothing, ...
                                      'fbfilterLen',  ancAlgoTune.fbfilterLen);
            end

            % Setup Multi-channel convolvers to simulate various acoustic paths
            obj.priPath = sysMimoConv('numMic',   obj.config.numErr, ...
                                      'numSrc',   obj.config.numSrc, ...
                                      'blockLen', obj.config.blockLen, ...
                                      'filters',  obj.paths.priPathFilters);

            obj.secPath = sysMimoConv('numMic',   obj.config.numErr, ...
                                      'numSrc',   obj.config.numSpk, ...
                                      'blockLen', obj.config.blockLen, ...
                                      'filters',  obj.paths.secPathFilters);

            obj.refPath = sysMimoConv('numMic',   obj.config.numRef, ...
                                      'numSrc',   obj.config.numSrc, ...
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

            function obj = measureIr(obj, msrIrTune, bCopy)
            %MEASUREIR Estimate secondary path IRs using Farina's method 

            switch bCopy

                case true % Copy coefficients from secondary path IR 

                    for spk = 1:obj.config.numSpk
                        for err = 1:obj.config.numErr
                            obj.ancAlgo.estSecPathCoeff(spk, err, :) = obj.paths.secPathFilters{spk, err}.Numerator(1:msrIrTune.filtLen);
                        end
                    end
                    obj.ancAlgo.estSecPathFilterLen = msrIrTune.filtLen;

                case false % Measure IR

                    % Generate sine sweep
                    swp = sweeptone(msrIrTune.swpTime, msrIrTune.silnTime, obj.config.fs, 'SweepFrequencyRange', ...
                                    [msrIrTune.lowFreq, obj.config.fs/2]);

                    for spk = 1:obj.config.numSpk
                        for err = 1:obj.config.numErr

                            % Filter sweep through secondary path
                            rec = obj.paths.secPathFilters{spk, err}(swp);

                            % Estimate Impulse Response (Use Farina's method)
                            tmp = impzest(swp, rec);
                            obj.ancAlgo.estSecPathCoeff(spk, err, :) = tmp(1:msrIrTune.filtLen, 1); 
                        end
                    end
                    obj.ancAlgo.estSecPathFilterLen = msrIrTune.filtLen;

                    % Reset secondary path filters
                    for spk = 1:obj.config.numSpk
                        for err = 1:obj.config.numErr
                            reset(obj.paths.secPathFilters{spk, err});
                        end
                    end
            end
        end

        function [obj, simData] = ancSimCore(obj)
            %ANCSIMCORE Main processing of the ANC simulation

            % Preallocate arrays
            totalSamples = obj.signals.simTime * obj.config.fs;
            simData.totalSamples  = totalSamples;
            simData.savePrimary   = zeros(totalSamples, obj.config.numErr);
            simData.saveReference = zeros(totalSamples, obj.config.numRef);
            simData.saveError     = zeros(totalSamples, obj.config.numErr);
            simData.saveAntinoise = zeros(totalSamples, obj.config.numErr);
            simData.saveOutput    = zeros(totalSamples, obj.config.numSpk);

            % Wait bar
            wbar = waitbar(0, 'Please wait', 'Name','Running Simulation...',...
                           'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');

            % Setup filter to simulate headphones
            if obj.acoustics.bSimheadphones
                [b, a]   = butter(obj.acoustics.lpfOrder, obj.acoustics.lpfCutoff / (0.5 * obj.config.fs), 'low');
                lpfState = [];
            end

            blockInd = 1:obj.config.blockLen;
            noise = obj.signals.noise;
            for i = 1:obj.signals.simTime * obj.config.fs
        
                % Simulate primary noise
                obj.primary = obj.priPath.step(noise(blockInd, :));

                % Add a LPF to primary noise simulate headphones
                if obj.acoustics.bSimheadphones
                    [obj.primary, lpfState] = filter(b, a, obj.primary, lpfState, 1);
                end
            
                % Calc error i.e. residual noise
                obj.error = obj.primary - obj.antinoise;
            
                if ~obj.ancAlgo.bFeedback
                    % Simulate reference path acoustics
                    obj.reference = obj.refPath.step(noise(blockInd, :)); 

                    % Call FF or Hybrid ANC algorithm step function
                    obj.output = obj.ancAlgo.step(obj.error, obj.reference);
                else
                    % Call FB ANC algorithm step function
                    obj.output = obj.ancAlgo.step(obj.error, obj.output); 
                end
            
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
                if mod(i, 0.5 * obj.config.fs) == 0 % Update waitbar every 0.5 sec worth of data
                    waitbar(i/totalSamples)
                end
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
            simData.fxlms = obj.ancAlgo;
        end

        function [obj, simData] = runAncSim(obj, ancAlgo, ancAlgoTune, msrIrTune, bCopy)
            %RUNANCSIM Helper function to organize the sequence of events
            %leading up to a full simulation run.

            if nargin < 5
                bCopy = false;
            end

            disp(['ANC Algorithm: ', func2str(ancAlgo)]);
            
            disp('--- Setting up the algorithms');
            obj = obj.setupSystemObj(ancAlgo, ancAlgoTune);
            obj = obj.resetBuffers();
            
            disp('--- Measuring Impulse Response');
            obj = obj.measureIr(msrIrTune, bCopy);
            obj = resetBuffers(obj);
            obj.secPath.reset();
            
            disp('--- Running Simulation');
            tic;
            [obj, simData] = obj.ancSimCore();
            toc;
        end
    end
end