classdef sysRLS < matlab.System
    % SYSLMS System object implementation of adaptive RLS algorithm. 
    % This system object supports a MIMO setup.

    % Public, tunable properties
    properties

        % system setup
        numSpk = 1;
        numErr = 1;

        % constants
        stepsize = 1.0;
        lambda   = 0.99; % forgetting factor
        delta    = 0.01; % initialization for P matrix
        
        % switches
        bfreezecoeffs(1, 1)logical = false; % bool to freeze coeffients

    end

    % Public, non-tunable properties
    properties(Nontunable)
        filterLen(1, 1){mustBePositive, mustBeInteger} = 256; % adaptive filter length
    end

    properties(DiscreteState)
        coeffs; % adaptive FIR filter coefficients
        states; % buffered reference signal
        error;  % error signal
        output; % output of each adaptive filter
        gain;   % gain vector
        P;      % inverse correlation matrix
    end

    % Pre-computed constants
    properties(Access = private)
        lambdainv;
    end

    methods
        % Constructor
        function obj = sysRLS(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end
    end

    methods(Access = protected)
        %% Common functions

        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
            obj.lambdainv = 1 / obj.lambda;
        end

        function stepImpl(obj, ref, des)
            % Implement algorithm. Calculate y as a function of input u and
            % discrete states.

            % Update state vector
            obj.states = [ref; obj.states(1:end-1, :)];

            % Get output signals
            for mic = 1:obj.numErr
                for spk = 1:obj.numSpk 
                    obj.output(mic, spk) = obj.states(:, spk).' * reshape(obj.coeffs(spk, mic, :), [obj.filterLen, 1]); 
                end
            end

            % Run RLS update
            for mic = 1:obj.numErr

                % Get error signal: desired - output % ToDo: Can move to outer loop
                obj.error(1, mic) = des(1, mic) - sum(obj.output(mic, :));

                for spk = 1:obj.numSpk

                    % --- Cache some arrays for optimization ---
                    Pmat = reshape(obj.P(spk, mic, :, :), [obj.filterLen, obj.filterLen]);
                    x    = obj.states(:, spk);
                    xt   = x.';
                    Px   = Pmat * x; 
                    % ------------------------------------------
    
                    % Update the gain vector
                    obj.gain(spk, mic, :) = Px / (obj.lambda + xt * Px);
    
                    % Update the inverse correlation matrix
                    obj.P(spk, mic, :, :) = obj.lambdainv * (Pmat - reshape(obj.gain(spk, mic, :), [obj.filterLen, 1]) * xt * Pmat);
                          
                    % Update filter coefficients using RLS
                    if ~obj.bfreezecoeffs
                        obj.coeffs(spk, mic, :) = obj.coeffs(spk, mic, :) + obj.stepsize * obj.error(1, mic) * obj.gain(spk, mic, :);
                    end

                end % spk loop
            end % mic loop
        end 

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.states = zeros(obj.filterLen, obj.numSpk);
            obj.coeffs = zeros(obj.numSpk, obj.numErr, obj.filterLen);
            obj.error  = zeros(1, obj.numErr);
            obj.output = zeros(obj.numErr, obj.numSpk);
            obj.gain   = zeros(obj.numSpk, obj.numErr, obj.filterLen);

            obj.P = zeros(obj.numSpk, obj.numErr, obj.filterLen, obj.filterLen); 
            for spk = 1:obj.numSpk
                for mic = 1:obj.numErr
                    obj.P(spk, mic, :, :) = obj.delta * eye(obj.filterLen, obj.filterLen);
                end
            end

        end
    end
end
