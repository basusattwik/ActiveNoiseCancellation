function app = uiUpdatePathDropdowns(app)
%UIUPDATEPATHDROPDOWNS Summary of this function goes here
%   Detailed explanation goes here

% Update dropdown list for paths
pathNames = {};
if ~isempty(app.priPath)
     pathNames{end+1} = 'Primary';
end
if ~isempty(app.secPath)
     pathNames{end+1} = 'Secondary';
end
if ~isempty(app.refPath)
     pathNames{end+1} = 'Reference';
end
app.PathDropDown.Items = pathNames;

end

