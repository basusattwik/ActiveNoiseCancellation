function app = uiUpdateSpkSrcMicDropdowns(app)
%UIUPDATESPKSRCMICDROPDOWNS Summary of this function goes here
%   Detailed explanation goes here

% Update dropdown list for spk/sources
if strcmpi(app.PathDropDown.Value, 'Secondary')
    spkList = cell(app.numSpk, 1);
    for spk = 1:app.numSpk
        spkList{spk} = num2str(spk);
    end
    app.SpkSrcDropDown.Items = spkList;

elseif strcmpi(app.PathDropDown.Value, 'Primary') || strcmpi(app.PathDropDown.Value, 'Reference') 
    srcList = cell(app.numSrc, 1);
    for src = 1:app.numSrc
        srcList{src} = num2str(src);
    end
    app.SpkSrcDropDown.Items = srcList;
end

if strcmpi(app.PathDropDown.Value, 'Primary') || strcmpi(app.PathDropDown.Value, 'Secondary')
    micList = cell(app.numErr, 1);
    for mic = 1:app.numErr
        micList{mic} = num2str(mic);
    end
    app.MicDropDown.Items = micList;
elseif strcmpi(app.PathDropDown.Value, 'Reference')
    micList = cell(app.numRef, 1);
    for mic = 1:app.numRef
        micList{mic} = num2str(mic);
    end
    app.MicDropDown.Items = micList;
end
end
