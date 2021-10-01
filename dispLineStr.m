function dispLineStr(str,curtime)
line_num=dbstack;
lNum=line_num(2);

t=curtime2realtime(curtime);

disp(repmat('-',1,60));
mystr=[' ' '(' num2str(t) ' ms) ' lNum.file ' (' num2str(lNum.line) ') ' newline ' ' str ];
disp(mystr);


end

