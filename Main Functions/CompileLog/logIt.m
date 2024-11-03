function logIt(input,logfile)

if nargin==0
    logfile='sequencer_log.html';
end

fileID = fopen(logfile,'w');
fprintf(fileID,'<!DOCTYPE html>\n');

end

