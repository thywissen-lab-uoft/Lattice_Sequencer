function [output] = getParam(type,name)

global seqdata

% Initialize structure and objects
params = struct;
punits  = struct;

%% Define Parameters

params.Bfield = [203 204 205 206 207 208 209 210];
punits.Bfield = 'seconds';

params.Freq = [-30:5:100];
punits.Freq = 'kHz';

params.obj_piezo_V = [5];
punits.obj_piezo_V = 'V';

%% Find parameters that are being scanned

pnames = fieldnames(params);
scan_params = struct;
for nn = 1:length(pnames)
    pname = pnames{nn};
    if size(params.(pname),2)>1
        scan_params.(pname) = params.(pname);
    end    
end

%% Convert into list of indices

V = {};

pnames = fieldnames(scan_params);
for nn = 1:length(pnames)
    pname = pnames{nn};
    V{nn} = 1:size(scan_params.(pname),2);    
end

C = cell(1,numel(V));
[C{:}] = ndgrid(V{:});
C = cellfun(@(X) reshape(X,[],1),C,'UniformOutput',false);
C = horzcat(C{:});



%%
% Design goals
%
% - Minimize the number of user functions
% - Final user interface is very simple, but customizable
% - Keep track of all runs

% 1) Find all params whose size(p,1)>1
% 2) Convert size(p,1) into list of indices
% 3) Convert into perumuations
% 4) Select an index




end

