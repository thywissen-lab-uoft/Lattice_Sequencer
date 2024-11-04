function logText(log_lines)
global log_file

if ~isempty(log_lines)
    fileID = fopen(log_file,'a+');
    % fprintf(fileID,'<p>\n');
    fprintf(fileID,'\n');

    if ~iscell(log_lines)
        log_lines={log_lines};
    end
    for kk=1:length(log_lines)
        fprintf(fileID,'<pre>');
        fprintf(fileID,'%s',log_lines{kk});
        fprintf(fileID,'</pre>');
    end
    
    % fprintf(fileID,'</p>');

    fclose(fileID);
end
end

