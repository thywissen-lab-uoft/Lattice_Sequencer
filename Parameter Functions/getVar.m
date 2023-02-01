function val = getVar(name)
    global seqdata
    val = seqdata.variables.(name);
    unit = seqdata.variables_units.(name);
    
    switch length(val)
        case 0
            error('empty variable');
        case 1
            val = val;
        otherwise
            value_list = val;                           % The variable list
            L = length(value_list);                     % variable list length
            random_list = seqdata.randcyclelist;        % Full random list
            random_list = random_list(random_list<=L);  % Partial random list          
            cycle_number = seqdata.scancycle;           % Cycle Number        
            val = value_list(...                        % Get the value
                random_list(1+mod(cycle_number-1,L)));   
    end
    
    % Write to output parameters
    addOutputParam(name,val,unit);
end

