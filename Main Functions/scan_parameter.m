%------
%Author: Stefan Trotzky
%Created: June 2013
%Summary: Picks a parameter from a list for scanning
%------

function out = scan_parameter(scan_list, name, mode)
%
% out = scan_parameter(scan_list, name, list_mode)
%
% Hands back a value taken from a scan list and adds the value to the
% output parameters. Can be called multiple times during one build of the
% same sequence and always takes the same index from the list.


global seqdata;
        
if nargin < 2
    name = 'scan value';
end

if nargin < 3
    mode = 'random';
end

if seqdata.scanindex == -1
    switch lower(mode)
        case 'linear'
            index = seqdata.cycle;
        case 'random'
            index = seqdata.randcyclelist(seqdata.cycle);
        otherwise
            error('unknown scan list mode.')
    end
else
    index = seqdata.index;
end
    

out = scan_list(index);
addOutputParam(name,out);
seqdata.index = index;

end