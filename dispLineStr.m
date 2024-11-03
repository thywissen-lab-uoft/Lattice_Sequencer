function dispLineStr(str,curtime)
line_num=dbstack;

ind = min([2 length(line_num)]);
lNum=line_num(ind);

t=curtime2realtime(curtime);
file = lNum.file;
line = lNum.line; 
hotlinkcode = sprintf('<a href="matlab: matlab.desktop.editor.openAndGoToLine(which(''%s''), %d); ">%s (%d)</a>', ...
    file, line, file, line);
mystr = [' ' '(' num2str(t) ' ms) ' hotlinkcode];

disp(repmat('-',1,60));
disp(mystr);
disp([' ' str]);

end

