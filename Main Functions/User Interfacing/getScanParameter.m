function out = getScanParameter(scanlist,cycle,randlist,name)
%
%   out = getScanParameter(scanlist,cycle,randlist)
%
%   typical usage:
%   par_list = [1:10];
%   par = getScanParameter(par_list, seqdata.scancycle, seqdata.randcyclelist, 'par')
%
%   Picks a parameter from a #scanlist for a given #cycle in a scan. A
%   #randlist may be specified that contains a randomized order of scanlist
%   indices. Will restart iteration when #cycle > length(#scanlist). Set
%   randlist to 0 for non-randomized scans.
%   -- S. Trotzky, March 2014
%
    
    if ~exist('randlist','var'); randlist = 0; end
    if ~exist('name','var'); name = 'scanparameter'; end
    if ischar(randlist); name=randlist; ranslist = 0; end
    
    if (randlist(1)~=0); % draw parameter with random order using randlist
        randlist = randlist(randlist<=length(scanlist));
        out = scanlist(randlist(1+mod(cycle-1,length(randlist))));
    else % draw parameter with linear order
        out = scanlist(1+mod(cycle-1,length(scanlist)));
    end
    
    addOutputParam(name,out); % write automatically to output parameters

end