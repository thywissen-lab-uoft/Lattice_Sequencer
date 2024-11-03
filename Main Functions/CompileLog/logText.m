function logAdd(log_lines)
global seqdata

logfile=seqdata.LogFile;

if ~isempty(log_lines)
    fileID = fopen(logfile,'a+');
    fprintf(fileID,'<p>\n');
    for kk=1:length(log_lines)
        fprintf(fileID,'<pre>');
        fprintf(fileID,'%s',log_lines{kk});
        fprintf(fileID,'</pre>');
        fprintf(fileID,'\n');
    end
    fprintf(fileID,'</p>');
    fclose(fileID);
end
end

