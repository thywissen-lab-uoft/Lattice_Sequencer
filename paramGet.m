function [out,varargout] = paramGet(name)

global seqdata;
global scan_params;
global scan_inds;

[params,punits,prands] = paramDef;

%% Find parameters that are being scanned

pnames = fieldnames(params);

params_scan = struct;
for nn = 1:length(pnames)
    pname = pnames{nn};
    if size(params.(pname),2)>1
        params_scan.(pname) = params.(pname);
    end    
end

% The parameter names that are being scanned
pnames_scan = fieldnames(params_scan);

%% Convert into list of indices

% List of indices of each scannable parameter
V = {};

% List of values of each scannable paramter
V2 = {};

% Get lists of all indices and values of scannable parameters
for nn = 1:length(pnames_scan)
    pname = pnames_scan{nn};
    V{nn} = 1:size(params_scan.(pname),2);    
    V2{nn} = params_scan.(pname);    
end

% Reorder lists by whether they should be random
isRand = zeros(length(pnames_scan),1);
for jj=1:length(pnames_scan)
    isRand(jj) = prands.(pnames_scan{jj});
end
[isR,indR]=sort(isRand,'descend');

V=V(indR);
V2=V2(indR);
pnames_scan = pnames_scan(indR);

scan_inds = cell(1,numel(V));
[scan_inds{:}] = ndgrid(V{:});
scan_inds = cellfun(@(X) reshape(X,[],1),scan_inds,'UniformOutput',false);
scan_inds = horzcat(scan_inds{:});

scan_params = cell(1,numel(V2));
[scan_params{:}] = ndgrid(V2{:});
scan_params = cellfun(@(X) reshape(X,[],1),scan_params,'UniformOutput',false);
scan_params = horzcat(scan_params{:});

% Determine randomness subsector size
N_rand = 1;
for jj = 1:length(pnames_scan)
    if prands.(pnames_scan{jj})
        N_rand = N_rand*length(params_scan.(pnames_scan{jj}));
    end
end

for jj = 1:size(scan_params,1)/N_rand    
    N = N_rand;         % Size of random subsector    
    n1 = 1 + (jj-1)*N;  % Start index of subsector
    n2 = jj*N;          % End index of subsector    
    ii = n1:n2;         % Indeces of subsector
    
    % Get random seed
    randSeedList = seqdata.randcyclelist;
    
    % Find seed of these indeces
    inds_rand = randSeedList(randSeedList<=n2 & randSeedList>=n1 );
    
    % Reorder this subsector
    scan_inds(ii,:)     = scan_inds(inds_rand,:);
    scan_params(ii,:)   = scan_params(inds_rand,:);
end


% N = size(scan_params,1);
% cyclelist = seqdata.randcyclelist;
% cyclelist = cyclelist(cyclelist<=N);
% inds_order = cyclelist(1+mod(0:(N-1),N));
% 
% scan_inds = scan_inds(inds_order,:);
% scan_params = scan_params(inds_order,:);



%% Grab this Cycle's Value

scancycle = seqdata.scancycle;
ind       = 1 + mod(scancycle-1,size(scan_inds,1));

pinds = scan_inds(ind,:);

params_scan_out     = struct;
params_out          = params;
for kk=1:length(pnames_scan)    
    valList = params_scan.(pnames_scan{kk});
    params_scan_out.(pnames_scan{kk}) = valList(pinds(kk));    
    params_out.(pnames_scan{kk}) = valList(pinds(kk));
end

if nargin == 1
    if isfield(params_out,name)
        val = params_out.(name);
        unit = punits.(name);
        addOutputParam(name,val,unit);
        out = val;  
        varargout{1} = unit;

    else
        error(['Parameter ''' name ''' is not recognized.']);
    end
end

if nargin == 0
    out = params_scan_out;
    varargout{1} = params_out;
    varargout{2} = punits;
end

seqdata.ScanVar = struct;
for kk=1:length(pnames_scan)
    seqdata.ScanVar.(pnames_scan{kk}) = params_scan_out.(pnames_scan{kk});
end

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

