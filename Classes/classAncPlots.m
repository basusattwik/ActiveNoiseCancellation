classdef classAncPlots < handle
    %CLASSANCPLOTS Summary of this class goes here
    %   Detailed explanation goes here

    properties

        % Setup 
        fs;     % Sampling rate
        simLen; % Total noise length in samples
        numErr; % Number of error mics
        numRef; % Number of reference mics
        numSrc; % Number of noise sources
        numSpk; % Number of speakers

        % Time domain signals
        primary;   % Primary noise
        reference; % Reference mic signals
        error;     % Errror mic signals
        output;    % Speaker output signals
        antinoise; % Speaker outputs filtered through sec. path

        % Frequency Domain Data (PSD)
        psdPrimary;   % PSD of primary noise
        psdAntinoise; % PSD of antinoise
        psdError;     % PSD of error signals

        % Transfer Functions
        priPathIr;     % Primary path: Noises source to error mics
        priPathFftMag; 
        priPathFftPhs;

        secPathIr;     % Secondary path: Speakers to error mics
        secPathFftMag;
        secPathFftPhs;

        refPathIr;     % Reference path: Noise sources to reference mics
        refPathFftMag;
        refPathFftPhs;
    end

    methods
        % Class Constructor
        function obj = classAncPlots(simData)
            %CLASSANCPLOTS Construct an instance of this class
            %   Detailed explanation goes here

            obj.numErr = simData.numErr;
            obj.numRef = simData.numRef;
            obj.numSrc = simData.numSrc;
            obj.numSpk = simData.numSpk;

            obj.fs        = simData.fs;
            obj.simLen    = simData.totalSamples;
            obj.primary   = simData.savePrimary;
            obj.reference = simData.saveReference;
            obj.error     = simData.saveError;
            obj.output    = simData.saveOutput;
            obj.antinoise = simData.saveAntinoise;
    
            obj.priPathIr = simData.priPath;
            obj.secPathIr = simData.secPath;
            obj.refPathIr = simData.refPath;
        end

        function genTimeDomainPlots(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            tx = (1:obj.simLen)/obj.fs;

            figure
            tl = tiledlayout('flow');
            ax = zeros(1, obj.numErr);
            for err = 1:obj.numErr
                ax(err) = nexttile;
                    plot(tx, obj.primary(:, err), 'LineWidth', 1.2);
                    hold on;
                    plot(tx, -obj.antinoise(:, err), 'LineWidth', 1.2);
                    plot(tx, obj.error(:, err), 'LineWidth', 1.2);
                    grid on; grid minor;
                    xlabel('time [s]'); ylabel('Amplitude');
                    legend('Primary Noise', 'Antinoise', 'Error');
                    title(['Mic: ', num2str(err)]);
            end
            title(tl, 'Noise Cancellation');
            linkaxes(ax, 'xy')
        end

        function genFreqDomainPlots(obj)
            %GENFREQDOMAINPLOTS

            % Calculate frequency domain data
            winLen  = 1024;
            overlap = 512;
            fftLen  = 2048;
            
            % for residual noise, wait for a few seconds and then compute PSD to ensure
            % convergence
            waitTime = 5; % sec
            
            [obj.psdPrimary,  fx] = pwelch(obj.primary, winLen, overlap, fftLen, obj.fs);
            [obj.psdAntinoise, ~] = pwelch(obj.antinoise, winLen, overlap, fftLen, obj.fs);
            [obj.psdError, ~]     = pwelch(obj.error(waitTime * obj.fs:end, :), winLen, overlap, fftLen, obj.fs);

            figure
            tl = tiledlayout('flow');
            ax = zeros(1, obj.numErr);

            for err = 1:obj.numErr
                ax(err) = nexttile;
                    plot(fx, 10*log10(obj.psdPrimary(:, err)), 'LineWidth', 1.1);
                    hold on;
                    plot(fx, 10*log10(obj.psdAntinoise(:, err)), 'LineWidth', 1.1);
                    plot(fx, 10*log10(obj.psdError(:, err)), 'LineWidth', 1.1);
                    grid on; grid minor;
                    xlabel('Frequency [Hz]'); ylabel('Power [dB]');
                    legend('Primary Noise', 'Antinoise', 'Error');
                    title(['Mic: ', num2str(err)]);
            end
            title(tl, 'Noise Cancellation PSD');
            linkaxes(ax, 'xy')
        end
    end
end