function dispLineStr(str,curtime)
line_num=dbstack;
lNum=line_num(2);

t=curtime2realtime(curtime);

disp(repmat('-',1,60));
mystr=[' ' lNum.file ' (' num2str(lNum.line) ') ' str ' (' num2str(t) ' ms)'];
disp(mystr);


end

