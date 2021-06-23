%------
%Function call: addOutputParam(paramname,paramval)
%Author: David McKay
%Created: July 2009
%Summary: Add an output parameter to be written to the communication file.
%   It will appear as a field with name paramname and a value paramval and
%   can be accessed in the imaging processing scripts via ProcessCmds.paramname
%------

function addOutputParam(paramname,paramval,paramunit)

global seqdata;

if ~exist('paramunit','var'); paramunit='??'; end

found = 0;
if length(seqdata.outputparams)>0
    for j=1:length(seqdata.outputparams)
            if strcmp(paramname,seqdata.outputparams{j}{1})
            seqdata.outputparams{j} = {paramname,paramval};
            found=1;
        end
    end
end

if (~found)
    seqdata.outputparams{end+1} = {paramname,paramval};
end

% 2021/06/23
% CF: Adding additional outputparams2 as a structure (for easier processing
% and also for units)

% Make the structure if it doesn't exist
if ~isfield(seqdata,'outputparams2')
    seqdata.outputparams2=struct;
end

% Add the parameter value as the first array list and the the paramter unit
% as the second array list

seqdata.outputparams2(1).(paramname)=paramval;
seqdata.outputparams2(2).(paramname)=paramunit;    

end