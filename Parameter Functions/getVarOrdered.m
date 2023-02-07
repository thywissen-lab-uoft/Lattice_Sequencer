function [val,ind] = getVarOrdered(name)
    global seqdata
    val = seqdata.variables.(name);
    unit = seqdata.variables_units.(name);
    
    switch length(val)
        case 0
            error('empty variable');
        case 1
            val = val;
            ind = 1;
        otherwise
            value_list = val;                           % The variable list
            L = length(value_list);                     % variable list length            
            ordered_list = 1:L;        
            cycle_number = seqdata.scancycle;           % Cycle Number   
            ind = ordered_list(1+mod(cycle_number-1,L));
            val = value_list(ind);               
    end
    
    % Write to output parameters
    addOutputParam(name,val,unit);
end

