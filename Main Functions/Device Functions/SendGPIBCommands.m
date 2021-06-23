function out = SendGPIBCommands(cmds, talk)
%------
%Author: Stefan Trotzky
%Created: February 2014
%Summary: Sends GPIB commands to devices.
%-----

disp(repmat('-',1,60));
disp(['Sending GPIB commands (' num2str(length(cmds)) ')']);

brd = 0; % Board index (can use NI VISA to check -- should see GPIB$::INTFC for brd = $)


for j=1:length(cmds)
    % separate primary adress of device from command string
    pa = str2double(cmds{j}(1:(strfind(cmds{j},'#')-1)));
    cmd = cmds{j}((strfind(cmds{j},'#')+1):end);
    
    % seperate potential queries from commands
    if ~isempty(strfind(cmd,'?'));
        pos = strfind(cmd,';');
        if ~isempty(pos);
            qry = cmd((pos(end)+1):end);
            cmd = cmd(1:pos(end));
        else
            qry=cmd;
            cmd='';
        end
    else
        qry = '';
    end
    
    % create GPIB object
    obj = gpib('ni', brd, pa);
    
    % open device, send commands, send query (and display if requested)
    fopen(obj);
    fprintf(obj, cmd);
    if ~isempty(qry)
        qry = query(obj, qry);
        if (talk)            
            str=strrep(strrep(qry,newline,''),char(13),'');
            disp(sprintf(['GPIB device #%g: ' str],pa));
        end
    end
    fclose(obj);
    delete(obj);

end

end