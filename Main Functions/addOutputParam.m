%------
%Function call: addOutputParam(paramname,paramval)
%Author: David McKay
%Created: July 2009
%Summary: Add an output parameter to be written to the communication file.
%   It will appear as a field with name paramname and a value paramval and
%   can be accessed in the imaging processing scripts via ProcessCmds.paramname
%------

function addOutputParam(paramname,paramval)

global seqdata;

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

end