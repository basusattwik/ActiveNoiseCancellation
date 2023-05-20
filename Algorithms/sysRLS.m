classdef sysRLS < matlab.System
    % SYSLMS System object implementation of adaptive RLS algorithm. 

    % Public, tunable properties
    properties

        % constants
        stepsize = 1.0;
        lambda   = 0.99; % forgetting factor
        delta    = 0.01; % initialization for P matrix
        
        % switches
        bfreezecoeffs(1, 1)logical = false; % bool to freeze coeffients

    end

    % Public, non-tunable properties
    properties(Nontunable)

        % adaptive filter length
        filterLen(1, 1){mustBePositive, mustBeInteger} = 256; 
        
        % system setup
        numSpk = 1;
        numErr = 1;
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
        function obj = sysRLS(varargin)
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
            lamb    = obj.lambda;
            lambInv = obj.lambdaInv;
            step    = obj.stepsize;
            w       = obj.coeffs;
            P       = obj.invcov;
            % ------------------------------------

            % Update state vector
            x = [ref; obj.states(1:end-1, 1)];
            xt  = x.';

            % Get output signals
            y = xt * w; 

            % Get error signal: desired - output % ToDo: Can move to outer loop
            e = des - y;

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
            obj.invcov = P;
            obj.gain   = g;
            obj.coeffs = w; 
            obj.states = x;
            obj.error  = e;
            obj.output = y;

        end 

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.states = zeros(obj.filterLen, obj.numSpk);
            obj.coeffs = zeros(obj.filterLen, 1);
            obj.error  = zeros(1, obj.numErr);
            obj.output = zeros(1, obj.numSpk);
            obj.gain   = zeros(obj.filterLen, 1);
            obj.invcov = obj.delta * eye(obj.filterLen, obj.filterLen);

        end
    end
end
