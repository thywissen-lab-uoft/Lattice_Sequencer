function logHeader
global seqdata

logfile=seqdata.LogFile;

line_num=dbstack;
ind = min([2 length(line_num)]);
lNum=line_num(ind);

file = lNum.file;
line = lNum.line; 
% hotlinkcode = sprintf('<a href="matlab: matlab.desktop.editor.openAndGoToLine(which(''%s''), 1); ">%s </a>', ...
    % file, file);
hotlinkcode = sprintf('<a href="matlab: matlab.desktop.editor.openDocument(which(''%s'')); ">%s </a>', ...
    file, file);
fileID = fopen(logfile,'a+');

fprintf(fileID,'<p style="font-size: 16pt;">');
fprintf(fileID,hotlinkcode);
fprintf(fileID,'</p>');
fprintf(fileID,'\n');
fclose(fileID);

end

