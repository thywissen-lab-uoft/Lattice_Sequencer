function defVar(name,val,unit)
    global seqdata
    if nargin == 2
        unit = '?';
    end   
    
    seqdata.variables.(name) = val;
    seqdata.variables_units.(name) = unit;
end

