function logInitialize
global log_file

% 
% fopen('to_be_deleted.txt','w');
% <!DOCTYPE html> 
% <html><body><p>
% before the text you normally write to the log file and
%  </p></body></html>

fileID = fopen(log_file,'w');
fprintf(fileID,'<!DOCTYPE html>\n');
fprintf(fileID,'<html>\n');
fprintf(fileID,'<head>\n');
fprintf(fileID,'<link href="https://fonts.cdnfonts.com/css/anonymous-pro" rel="stylesheet">');
fprintf(fileID,'<style>\n');
fprintf(fileID,'* { font-family: "Anonymous Pro", sans-serif; font-size: 8pt}');
fprintf(fileID,'pre { font-family: "Anonymous Pro", sans-serif; font-size: 8pt;   margin: 0;  padding: 0}');

fprintf(fileID,'</style>\n');

fprintf(fileID,'</head></body>\n');

% fprintf(fileID,'<p style="font-size: 24pt;">');
% fprintf(fileID,'Lattice Sequencer Compiler');
% fprintf(fileID,'</p>');
% % fprintf(fileID,'\n</body></html>');
% fprintf(fileID,'\n');
% fprintf(fileID,'\n');

fclose(fileID);
end

