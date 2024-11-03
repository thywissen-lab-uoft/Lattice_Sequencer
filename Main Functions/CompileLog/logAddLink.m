function logAddLink(str,curtime)

global seqdata
logfile=seqdata.LogFile;

line_num=dbstack;
ind = min([2 length(line_num)]);
lNum=line_num(ind);

t=curtime2realtime(curtime);
file = lNum.file;
line = lNum.line; 
hotlinkcode = sprintf('<a href="matlab: matlab.desktop.editor.openAndGoToLine(which(''%s''), %d); ">%s (%d)</a>', ...
    file, line, file, line);
mystr = [' ' '(' num2str(t) ' ms) ' hotlinkcode ' ' str];


fileID = fopen(logfile,'a+');

fprintf(fileID,'<p>');
fprintf(fileID,'%s',mystr);
fprintf(fileID,'</p>');
fprintf(fileID,'\n');
fclose(fileID);

end

