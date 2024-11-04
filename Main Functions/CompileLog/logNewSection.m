function logNewSection(str,curtime)

global log_file

if nargin ==1
    curtime = nan;
end

line_num=dbstack;
ind = min([2 length(line_num)]);
lNum=line_num(ind);

t=curtime2realtime(curtime);
file = lNum.file;
line = lNum.line; 
hotlinkcode = sprintf('<a href="matlab: matlab.desktop.editor.openAndGoToLine(which(''%s''), %d); ">%s (%d)</a>', ...
    file, line, file, line);
mystr = [' ' '(' num2str(t) ' ms) ' hotlinkcode ' ' str];


fileID = fopen(log_file,'a+');
fprintf(fileID,'\n');
fprintf(fileID,'<p>');
fprintf(fileID,'%s',mystr);
fprintf(fileID,'</p>');
fclose(fileID);

end

