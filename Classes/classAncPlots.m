classdef classAncPlots < handle
    %CLASSANCPLOTS Summary of this class goes here
    %   Detailed explanation goes here

    properties

        % Setup
        fs;
        simLen;
        numErr;
        numRef;
        numSrc;
        numSpk;

        % Signals
        primary;
        reference;
        error;
        output;
        antinoise;

        % Frequency Domain Data
        psdPrimary;
        psdError;

        % Transfer Functions
        priPathIr;
        priPathFftMag;
        priPathFftPhs;

        secPathIr;
        secPathFftMag;
        secPathFftPhs;

        refPathIr;
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
            for err = 1:obj.numErr
                nexttile
                    plot(tx, obj.primary(:, err));
                    hold on;
                    plot(tx, -obj.antinoise(:, err));
                    plot(tx, obj.error(:, err));
                    grid on; grid minor;
                    xlabel('time [s]'); ylabel('Amplitude');
                    legend('Primary Noise', 'Antinoise', 'Error');
                    title(['Mic: ', num2str(err)]);
            end
            title(tl, 'Noise Cancellation');
        end
    end
end