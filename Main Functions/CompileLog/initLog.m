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
fprintf(fileID,'<!DOCTYPE html>');
fprintf(fileID,'<html><body><p>')
fprintf(fileID,'</p></body></html>')



end

