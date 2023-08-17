function [pos2curr,pos,curr] = loadTransportCurve(coil_identifier)
% CF : Loading the splines. This function should also convert the calculate
% curves into generalized function. An important task will be to properly
% handle splining due to the non zero slope intercepts
pos = 0:1:539;
curr = zeros(1,length(pos));

%% Set Location of Transport Curves

curpath = fileparts(mfilename('fullpath'));
mydir = 'transport_splines';
if ~exist(fullfile(curpath,mydir),'dir')
   error('the transport folder is specified incorrectly!');
end
mydir=fullfile(curpath,mydir);

%% Define the Files to load

filenames = struct;
filenames.PushCoil  = 'Hextra1coilPush.txt';
filenames.MOTCoil   = 'Hextra1coilMOT.txt';
filenames.Coil3     = 'Hextra1coil3.txt';
filenames.Coil4     = 'Hextra1coil4.txt';
filenames.Coil5     = 'Hextra1coil5.txt';
filenames.Coil6     = 'Hextra1coil6.txt';
filenames.Coil7     = 'Hextra1coil7.txt';
filenames.Coil8     = 'Hextra1coil8.txt';
filenames.Coil9     = 'Hextra1coil9.txt';
filenames.Coil10    = 'Hextra1coil10.txt';
filenames.Coil11    = 'Hextra1coil11.txt';
filenames.CoilExtra = 'Hextra1coilextra.txt';
filenames.Coil12    = 'Hextra1coil12.txt';
filenames.Coil12a   = 'rev45coil1.txt';
filenames.Coil12b   = 'rev45coil2.txt';
filenames.Coil13    = 'rev45coil3.txt';
filenames.Coil14    = 'rev45coil4.txt';
filenames.Coil15    = 'rev45coil5.txt';
filenames.Coil16    = 'rev45coil6.txt';

%% Load the Curves
switch coil_identifier
    case 'Push Coil'
        y = dlmread(fullfile(mydir,filenames.PushCoil),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');   
    case 'MOT Coil'
        y = dlmread(fullfile(mydir,filenames.MOTCoil),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');          
    case 'Coil 3'
        y = dlmread(fullfile(mydir,filenames.Coil3),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear'); 
    case 'Coil 4'
        y = dlmread(fullfile(mydir,filenames.Coil4),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear'); 
    case 'Coil 5'
        y = dlmread(fullfile(mydir,filenames.Coil5),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');   
    case 'Coil 6'
        y = dlmread(fullfile(mydir,filenames.Coil6),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');  
    case 'Coil 7'
        y = dlmread(fullfile(mydir,filenames.Coil7),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');  
    case 'Coil 8'
        y = dlmread(fullfile(mydir,filenames.Coil8),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');         
    case 'Coil 9'
        y = dlmread(fullfile(mydir,filenames.Coil9),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear'); 
    case 'Coil 10'
        y = dlmread(fullfile(mydir,filenames.Coil10),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
    case 'Coil 11'
        y = dlmread(fullfile(mydir,filenames.Coil11),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
    case 'Coil Extra'
        y = dlmread(fullfile(mydir,filenames.Coil1Extra),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
    case 'Coil 12a'
        yH = dlmread(fullfile(mydir,filenames.Coil12),',',0,1);
        yV = dlmread(fullfile(mydir,filenames.Coil12a),',',0,1);
        if length(yH)~=366;error('on no, unexpected length');end
        if length(yV)~=174;error('on no, unexpected length');end        
        curr(1:1:366) = -yH;
        curr(367:end) = yV;
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
    case 'Coil 12b'
        yH = dlmread(fullfile(mydir,filenames.Coil12),',',0,1);
        yV = dlmread(fullfile(mydir,filenames.Coil12b),',',0,1);
        if length(yH)~=366;error('on no, unexpected length');end
        if length(yV)~=174;error('on no, unexpected length');end        
        curr(1:1:366) = yH;
        curr(367:end) = yV;
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
    case 'Coil 13'
        y = dlmread(fullfile(mydir,filenames.Coil13),',',0,1);
        if length(y)~=174;error('on no, unexpected length');end
        curr(367:1:end) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
    case 'Coil 14'
        y = dlmread(fullfile(mydir,filenames.Coil14),',',0,1);
        if length(y)~=174;error('on no, unexpected length');end
        curr(367:1:end) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
    case 'Coil 15'
        y = dlmread(fullfile(mydir,filenames.Coil15),',',0,1);
        if length(y)~=174;error('on no, unexpected length');end
        curr(367:1:end) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
    case 'Coil 16'
        y = dlmread(fullfile(mydir,filenames.Coil16),',',0,1);
        if length(y)~=174;error('on no, unexpected length');end
        curr(367:1:end) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
end


end