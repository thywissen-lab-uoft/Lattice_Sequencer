function logAdd(log_lines,timein,timeout)
global seqdata

line_num=dbstack;
ind = min([2 length(line_num)]);
lNum=line_num(ind);

t1 = curtime2realtime(timein);
t2 = curtime2realtime(timeout);

file = lNum.file;
line = lNum.line; 
hotlinkcode = sprintf('<a href="matlab: matlab.desktop.editor.openAndGoToLine(which(''%s''), %d); ">%s (%d)</a>', ...
    file, line, file, line);

logfile=seqdata.LogFile;

fileID = fopen(logfile,'a+');
fprintf(fileID,['<details>\n<summary>' hotlinkcode '</summary>\n']);
for kk=1:length(log_lines)
    fprintf(fileID,log_lines{kk});
    fprintf(fileID,'\n');
end
fprintf(fileID,'\n</details>\n');
fclose(fileID);

% fprintf(fileID,'<!DOCTYPE html>\n');

end

