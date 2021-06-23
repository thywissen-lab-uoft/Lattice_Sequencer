function out = getScanParameter(scanlist,cycle,randlist,name,unit)
% Picks a parameter from a #scanlist for a given #cycle in a scan. A
% #randlist may be specified that contains a randomized order of scanlist
% indices. Will restart iteration when #cycle > length(#scanlist). Set
% randlist to 0 for non-randomized scans.
% 
%   Author      : Trotzky, March 2014
%   Last Edited : 2020/09/29 comments (CF), 2014/03 (ST)
%
%   randlist - a list of indices, which indicates the order in which to run
%   the scan list
%   scanlist - the list of parameter values to choose
%   name - the name of the variable changing
%   cycle - the current cycle iteration number
%
%   out = getScanParameter(scanlist,cycle,randlist,name)
%   Example:
%   par_list = [1:10];
%   par = getScanParameter(par_list, seqdata.scancycle, seqdata.randcyclelist, 'par')
    
% If a random list is not provided set it to be zero
    if ~exist('randlist','var'); randlist = 0; end
    
% If a scan parameter name is not provided give a dummy name
    if ~exist('name','var'); name = 'scanparameter'; end

% I think this if statement is meant to handle if the number of input
    % arugments is incorrect. Ie. getScanParameter(scanlist,cycle,name)
    if ischar(randlist); name=randlist; randlist = 0; end
    
    if ~exist('unit','var'); unit='??'; end
    
    
    if (randlist(1)~=0) 
        % draw parameter with random order using randlist
        randlist = randlist(randlist<=length(scanlist));
        out = scanlist(randlist(1+mod(cycle-1,length(randlist))));
    else % draw parameter with linear order
        out = scanlist(1+mod(cycle-1,length(scanlist)));
    end
    
    % Write to output parameters
    addOutputParam(name,out,unit);

end