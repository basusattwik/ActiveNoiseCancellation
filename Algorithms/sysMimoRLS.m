classdef sysMimoRLS < matlab.System
    % SYSLMS System object implementation of a multichannel adaptive RLS algorithm. 
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
        invcov; % inverse covariance matrix
    end

    % Pre-computed constants
    properties(Access = private)
        lambdaInv;
    end

    methods
        % Constructor
        function obj = sysMimoRLS(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end
    end

    methods(Access = protected)
        %% Common functions

        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
            obj.lambdaInv = 1 / obj.lambda;
        end

        function stepImpl(obj, ref, des)
            % Implement algorithm. Calculate y as a function of input u and
            % discrete states.

            % --- Cache some values and arrays ---
            filtLen = obj.filterLen;
            lamb    = obj.lambda;
            lambInv = obj.lambdaInv;
            step    = obj.stepsize;
            coeff   = obj.coeffs;
            Pmat    = obj.invcov;
            % ------------------------------------

            % Update state vector
            obj.states = [ref; obj.states(1:end-1, :)];

            % Get output signals
            for mic = 1:obj.numErr
                for spk = 1:obj.numSpk 
                    obj.output(mic, spk) = obj.states(:, spk).' * reshape(coeff(spk, mic, :), [filtLen, 1]); 
                end
            end

            % Run RLS update
            for mic = 1:obj.numErr

                % Get error signal: desired - output % ToDo: Can move to outer loop
                e = des(1, mic) - sum(obj.output(mic, :));
                obj.error(1, mic) = e;

                for spk = 1:obj.numSpk

                    % --- Cache some arrays for optimization ---
                    w   = reshape(coeff(spk, mic, :), [filtLen, 1]);
                    P   = reshape(Pmat(spk, mic, :, :), [filtLen, filtLen]);
                    x   = obj.states(:, spk);
                    xt  = x.';
                    % ------------------------------------------
    
                    % Update the gain vector and inverse correlation matrix
                    Px  = P * x; 
                    den = 1 / (lamb + xt * Px);
                    g   = Px * den;       
                    P   = lambInv * (P - g * xt * P);                    
                          
                    % Update filter coefficients
                    if ~obj.bfreezecoeffs
                        w = w + step * e * g;
                    end

                    % Save new values to class properties
                    obj.invcov(spk, mic, :, :) = P;
                    obj.gain(spk, mic, :)      = g;
                    obj.coeffs(spk, mic, :)    = w; 

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

            obj.invcov = zeros(obj.numSpk, obj.numErr, obj.filterLen, obj.filterLen); 
            for spk = 1:obj.numSpk
                for mic = 1:obj.numErr
                    obj.invcov(spk, mic, :, :) = obj.delta * eye(obj.filterLen, obj.filterLen);
                end
            end
        end
    end
end
