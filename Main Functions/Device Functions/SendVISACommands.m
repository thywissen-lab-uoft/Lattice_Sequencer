function out = SendVISACommands(cmds, talk)
%------
%Author: Stefan Trotzky
%Created: January 2015
%Summary: Sends commands to VISA devices.
%-----

disp(repmat('-',1,60));
disp(['Sending VISA commands (' num2str(length(cmds)) ')']);

if ischar(cmds) % convert a single string to a cell array
    cmds = {cmds};
end

for j=1:length(cmds)
    % separate device name of device from command string
    addr = cmds{j}(1:(strfind(cmds{j},'#')-1));
    cmd = cmds{j}((strfind(cmds{j},'#')+1):end);
    
    % seperate potential queries from commands
    if ~isempty(strfind(cmd,'?'));
        pos = strfind(cmd,';');
        if ~isempty(pos);
            qry = cmd((pos(end)+1):end);
            cmd = cmd(1:pos(end));
            if cmd(end)~=';'; cmd=[cmd ';']; end
        else
            qry=cmd;
            cmd='';
        end
    else
        qry = '';
    end
    
    % create GPIB object
    obj = visa('ni', addr);
    
    % open device, send commands, send query (and display if requested)
    try
        fopen(obj);
        success = 1;
    catch ERR
        disp(['visa::error could not connect to device ' addr '! Moving on.'])
        success = 0;
    end
    
    if (success)
        try
            if ~isempty(cmd);
                pos = [0 strfind(cmd,';')];
                for k = 2:length(pos)
                    thiscmd = cmd((pos(k-1)+1):(pos(k)-1));
                    fprintf(obj, thiscmd);
                end
            end
            
            if ~isempty(qry)
                qry = query(obj, qry);
                if (talk); disp(['VISA device ' addr ': ' qry]); end
            end
            fclose(obj);
        catch ERR
            fclose(obj);
            delete(obj);
            error(ERR);
        end
    end
    
    delete(obj);

end

end