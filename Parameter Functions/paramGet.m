function [out,varargout] = paramGet(name)

global seqdata;
global scan_params;
global scan_inds;
global scan_names;

% Define the parameters
[params,punits,ptypes] = paramDef;

% All parameters names
pnames = fieldnames(params);

%% Convert dependent parameters
% Some parameters are specified as funcitons of other ones. Convert them
% into lists if they are given as fucntion handles.

for nn = 1:length(pnames)
    foo = params.(pnames{nn});
   if isa(foo,'function_handle')
        var = ptypes.(pnames{nn});       
        params.(pnames{nn}) =  foo(params.(var));
   end
end

%% Find parameters that are being scanned

params_scan = struct;
for nn = 1:length(pnames)
    pname = pnames{nn};
    if size(params.(pname),2)>1
        params_scan.(pname) = params.(pname);
    end    
end

% The parameter names that are being scanned
pnames_scan = fieldnames(params_scan);

%% Simple output edge cases
% The output is simple if there are no scanned parameters or is this
% variable is not a scanned variable.

if isempty(pnames_scan) || ~ismember(name,pnames_scan)
    if isfield(params,name)
        val = params.(name);
        unit = punits.(name);
        addOutputParam(name,val,unit);
        out = val;  
        varargout{1} = unit;
    else
        error(['Parameter ''' name ''' is not recognized.']);
    end
    return
end

%% Create list of parameters which are tensor scanned
% If a parameter is scanned, it could be because it is scanned
% independently of all other parameters (ie. a tensor product), or it could
% be beacuse it depends on another variable (ie. like a dot product).
%
% For creating an nD scans purposes we only care about the parameters which
% are scanned in a tensor product like way.

pnames_grid = {};
pnames_follow = {};
for nn = 1:length(pnames_scan)
    scan_mode = ptypes.(pnames_scan{nn});
    if isequal(scan_mode,'random') || isequal(scan_mode,'ordered')
        pnames_grid{end+1} = pnames_scan{nn}; 
    else
        pnames_follow{end+1} = pnames_scan{nn}; 
        
        L_follow = length(params.(pnames_follow{end}));
        L_source = length(params.(scan_mode));
        
        if ~isequal(L_follow,L_source)
            error(['followed list ' pnames_follow{end} '(' num2str(L_follow) ') ' ...
                'is not same length as the source list ' ...
                scan_mode '(' num2str(L_source) ')!']);
        end
    end
end

%% Create Lists of Lists
% Provided a set of n parameters to run in the n-dimensional grid, creates
% a list of lists of parameters and indicies.  Then order these lists with
% the random ones first and then the ordered ones.

% List of indices of each scannable parameter
V = {};

% List of values of each scannable paramter
V2 = {};

% Get lists of all indices and values of scannable parameters
for nn = 1:length(pnames_grid)
    pname = pnames_grid{nn};
    V{nn} = 1:size(params_scan.(pname),2);    
    V2{nn} = params_scan.(pname);    
end

% Reorder lists of lists with ordered ones first
isRand = zeros(length(pnames_grid),1);
for jj=1:length(pnames_grid)
    isRand(jj) = isequal(ptypes.(pnames_grid{jj}),'random');
end
[isR,indR]=sort(isRand,'descend');

% List of lists of indices, values, and corresponding names
V=V(indR);
V2=V2(indR);
pnames_grid = pnames_grid(indR);

%% Create the nD grid
% Create the n-dimensional grid of parameters and format them into a list

scan_inds = cell(1,numel(V));
[scan_inds{:}] = ndgrid(V{:});
scan_inds = cellfun(@(X) reshape(X,[],1),scan_inds,'UniformOutput',false);
scan_inds = horzcat(scan_inds{:});

scan_params = cell(1,numel(V2));
[scan_params{:}] = ndgrid(V2{:});
scan_params = cellfun(@(X) reshape(X,[],1),scan_params,'UniformOutput',false);
scan_params = horzcat(scan_params{:});

%% Randomize the random ones
% Determine randomness subsector size
N_rand = 1;
for jj = 1:length(pnames_grid)
    if isequal(ptypes.(pnames_grid{jj}),'random')
        N_rand = N_rand*length(params_scan.(pnames_grid{jj}));
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

%% Append dot product to end

for nn = 1:length(pnames_follow)
    source_name = ptypes.(pnames_follow{nn});
    source_index = find(strcmp(pnames_grid,source_name)==1,1);    
    follow_values = params_scan.(pnames_follow{nn});
    
    scan_inds(:,end+1) = scan_inds(:,source_index);
    scan_params(:,end+1) = follow_values(scan_inds(:,source_index));    
end

% Total parameter name list
pnames_scan = [pnames_grid pnames_follow];

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

scan_names = pnames_scan;
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

