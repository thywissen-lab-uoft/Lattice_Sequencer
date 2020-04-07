%------
%Author: David McKay
%Created: July 2009
%Summary: Read in the output parameter files and convert into variables
%------

function [cycle params] = ReadInOutputParamFile(outfilename)

%cycle is the cycle specified in the param file
%params is a cell array with the name and value for each of the params in
%the file

%open the file
fid = fopen(outfilename,'rt');

if fid==-1
    error('Could not open the parameter file');
end

%read in the parameters

%do a custom input of the first six lines
for i = 1:4
    fgetl(fid);
end
cyclestr = fgetl(fid);
cycle = str2double(cyclestr(8:end));
fgetl(fid);

%now use textscan for the rest of the file
C = textscan(fid,'%[^:] %*s %s');

params = C;

%close the file
fclose(fid);

end