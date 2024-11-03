function initLog(logfile)
if nargin==0
    logfile='sequencer_log.html';
end
% 
% fopen('to_be_deleted.txt','w');
% <!DOCTYPE html> 
% <html><body><p>
% before the text you normally write to the log file and
%  </p></body></html>

fileID = fopen(logfile,'w');
fprintf(fileID,'<!DOCTYPE html>\n');
fprintf(fileID,'<html>\n');
fprintf(fileID,'<head>\n')
fprintf(fileID,'<link href="https://fonts.cdnfonts.com/css/anonymous-pro" rel="stylesheet">');
fprintf(fileID,'<style>\n');
fprintf(fileID,'* { font-family: "Anonymous Pro", sans-serif}');
fprintf(fileID,'</style>\n');
fprintf(fileID,'</head>\n')
fprintf(fileID,'<body><p style="font-size: 24pt;">');
fprintf(fileID,'Lattice Sequencer Compiler');
fprintf(fileID,'</p>');

fprintf(fileID,'<p>Cora Fujiwara</p>');
fprintf(fileID,'<p>I know very little HTML. I hope this log file is helpful.</p>');


fprintf(fileID,'\n</body></html>');



end

