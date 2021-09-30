function out = paramGet(name)

global seqdata;
global scan_params;
global scan_inds;

[params,punits] = paramDef;

%% Find parameters that are being scanned

pnames = fieldnames(params);

params_scan = struct;
for nn = 1:length(pnames)
    pname = pnames{nn};
    if size(params.(pname),2)>1
        params_scan.(pname) = params.(pname);
    end    
end
pnames_scan = fieldnames(params_scan);

%% Convert into list of indices

V = {};
V2 = {};


for nn = 1:length(pnames_scan)
    pname = pnames_scan{nn};
    V{nn} = 1:size(params_scan.(pname),2);    
    V2{nn} = params_scan.(pname);    
end

scan_inds = cell(1,numel(V));
[scan_inds{:}] = ndgrid(V{:});
scan_inds = cellfun(@(X) reshape(X,[],1),scan_inds,'UniformOutput',false);
scan_inds = horzcat(scan_inds{:});

scan_params = cell(1,numel(V2));
[scan_params{:}] = ndgrid(V2{:});
scan_params = cellfun(@(X) reshape(X,[],1),scan_params,'UniformOutput',false);
scan_params = horzcat(scan_params{:});

N = size(scan_params,1);
cyclelist = seqdata.randcyclelist;
cyclelist = cyclelist(cyclelist<=N);
inds_order = cyclelist(1+mod(0:(N-1),N));

scan_inds = scan_inds(inds_order,:);
scan_params = scan_params(inds_order,:);

%%

if nargin == 1
    if ismember(name,pnames_scan)
        for kk = 1:length(pnames_scan)
           if isequal(pnames_scan{kk},name)
              ind = kk;
           end
        end
        scancycle=seqdata.scancycle;
        val = scan_params(1+mod(scancycle-1,N),ind);
        unit = punits.(name);
        addOutputParam(name,val,unit)
        out = val;  
    else
        if ismember(name,pnames)
            val = params.(name);
            unit = punits.(name);
            addOutputParam(name,val,unit)
            out = val;     
        else
            error('This parameter is not stored');
        end   
        
    end
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

