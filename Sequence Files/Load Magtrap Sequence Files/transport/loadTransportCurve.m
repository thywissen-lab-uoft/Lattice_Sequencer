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
        curr(pos==44)=[];pos(pos==44)=[];
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');   
        pos2curr = @(xq) interp1(pos,curr,xq,'spline').*[xq<=45].*[xq>=0];           
    case 'MOT Coil'
        y = dlmread(fullfile(mydir,filenames.MOTCoil),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');          
    case 'Coil 3'
        y = dlmread(fullfile(mydir,filenames.Coil3),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;        
        curr(103)=[];
        pos(103)=[];               
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');          
        pos2curr = @(xq) interp1(pos,curr,xq,'linear').*[xq>=100]+...
            interp1(pos,curr,xq,'spline').*[xq<100];        
    case 'Coil 4'
        y = dlmread(fullfile(mydir,filenames.Coil4),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;                
        curr(133)=[];
        pos(133)=[];               
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');          
        pos2curr = @(xq) interp1(pos,curr,xq,'linear').*[xq>=130]+...
            interp1(pos,curr,xq,'spline').*[xq<130].*[xq>=44];         
    case 'Coil 5'
        y = dlmread(fullfile(mydir,filenames.Coil5),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end   
        curr(1:1:366) = y; 
        curr(pos==68)=[];pos(pos==68)=[];
        curr(pos==165)=[];pos(pos==165)=[];
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');        
        pos2curr = @(xq) interp1(pos,curr,xq,'spline').*[xq<=166].*[xq>=67];   
    case 'Coil 6'
        y = dlmread(fullfile(mydir,filenames.Coil6),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;        
        curr(pos==194)=[];pos(pos==194)=[];
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');  
        pos2curr = @(xq) interp1(pos,curr,xq,'spline').*[xq<=195].*[xq>=102];   
    case 'Coil 7'
        y = dlmread(fullfile(mydir,filenames.Coil7),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;        
        curr(pos==131)=[];pos(pos==131)=[];
        curr(pos==227)=[];pos(pos==227)=[];
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');  
        pos2curr = @(xq) interp1(pos,curr,xq,'spline').*[xq<=228].*[xq>=130];   
    case 'Coil 8'
        y = dlmread(fullfile(mydir,filenames.Coil8),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y; 
        curr(pos==166)=[];pos(pos==166)=[];
        curr(pos==257)=[];pos(pos==257)=[];
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');    
        pos2curr = @(xq) interp1(pos,curr,xq,'spline').*[xq<=258].*[xq>=165]; 
    case 'Coil 9'
        y = dlmread(fullfile(mydir,filenames.Coil9),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;  
        curr(pos==195)=[];pos(pos==195)=[];
        curr(pos==290)=[];pos(pos==290)=[];
        pos2curr = @(xq) interp1(pos,curr,xq,'linear'); 
        pos2curr = @(xq) interp1(pos,curr,xq,'spline').*[xq<=291].*[xq>=194]; 
    case 'Coil 10'
        y = dlmread(fullfile(mydir,filenames.Coil10),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y; 
        curr(pos==228)=[];pos(pos==228)=[];
        curr(pos==309)=[];pos(pos==309)=[];
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
        pos2curr = @(xq) interp1(pos,curr,xq,'spline').*[xq<=310].*[xq>=227]; 
    case 'Coil 11'
        y = dlmread(fullfile(mydir,filenames.Coil11),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;  
        curr(pos==258)=[];pos(pos==258)=[];
        curr(pos==330)=[];pos(pos==330)=[];
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
        pos2curr = @(xq) interp1(pos,curr,xq,'spline').*[xq<=331].*[xq>=257]; 
    case 'Coil Extra'
        y = dlmread(fullfile(mydir,filenames.CoilExtra),',',0,1);
        if length(y)~=366;error('on no, unexpected length');end
        curr(1:1:366) = y;    
        curr(pos==365)=[];pos(pos==365)=[];
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
        pos2curr = @(xq) interp1(pos,curr,xq,'spline').*[xq<=366].*[xq>=297]; 
    case 'Coil 12a'
        yH = dlmread(fullfile(mydir,filenames.Coil12),',',0,1);
        yV = dlmread(fullfile(mydir,filenames.Coil12a),',',0,1);
        if length(yH)~=366;error('on no, unexpected length');end
        if length(yV)~=174;error('on no, unexpected length');end    
        curr(1:1:366) = -yH;
        curr(367:end) = yV;
        curr(pos==366)=[];pos(pos==366)=[];
        curr(pos==367)=[];pos(pos==367)=[];
        curr(pos==368)=[];pos(pos==368)=[];
        curr(pos==432)=[];pos(pos==432)=[];
        pos_h=pos(pos<=365);
        curr_h = curr(pos<=365);        
        pos_v = pos(pos>=365);
        curr_v = curr(pos>=365);
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
        pos2curr = @(xq) interp1(pos_h,curr_h,xq,'spline').*[xq>=309].*[xq<=365] + ...
            interp1(pos_v,curr_v,xq,'spline').*[xq>365].*[xq<=433];        
    case 'Coil 12b'
        yH = dlmread(fullfile(mydir,filenames.Coil12),',',0,1);
        yV = dlmread(fullfile(mydir,filenames.Coil12b),',',0,1);
        if length(yH)~=366;error('on no, unexpected length');end
        if length(yV)~=174;error('on no, unexpected length');end        
        curr(1:1:366) = yH;
        curr(367:end) = yV;        
        curr(pos==466)=[];pos(pos==466)=[];

        pos_h=pos(pos<=365);
        curr_h = curr(pos<=365);        
        pos_v = pos(pos>=365);
        curr_v = curr(pos>=365);       
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
        pos2curr = @(xq) interp1(pos_h,curr_h,xq,'spline',0).*[xq>=309].*[xq<=365] + ...
        interp1(pos_v,curr_v,xq,'linear',0).*[xq>365].*[xq<=366] + ...
        interp1(pos_v,curr_v,xq,'spline',0).*[xq>366].*[xq<=467]; 
    case 'Coil 13'
        y = dlmread(fullfile(mydir,filenames.Coil13),',',0,1);
        if length(y)~=174;error('on no, unexpected length');end
        curr(367:1:end) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
        pos1 = pos(pos<=366);
        curr1 = curr(pos<=366);        
        pos2 = pos(pos>=366);
        curr2 = curr(pos>=366);        
        pos2curr = @(xq) interp1(pos1,curr1,xq,'linear',0).*[xq>=365].*[xq<=366] + ...
            interp1(pos2,curr2,xq,'spline',0).*[xq>366].*[xq<=518]; 
    case 'Coil 14'
        y = dlmread(fullfile(mydir,filenames.Coil14),',',0,1);
        if length(y)~=174;error('on no, unexpected length');end
        curr(367:1:end) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
        pos2curr = @(xq) interp1(pos,curr,xq,'spline').*[xq<=539].*[xq>=387]; 
    case 'Coil 15'
        y = dlmread(fullfile(mydir,filenames.Coil15),',',0,1);
        if length(y)~=174;error('on no, unexpected length');end
        curr(367:1:end) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
        pos2curr = @(xq) interp1(pos,curr,xq,'spline').*[xq<=539].*[xq>=432]; 
    case 'Coil 16'
        y = dlmread(fullfile(mydir,filenames.Coil16),',',0,1);
        if length(y)~=174;error('on no, unexpected length');end
        curr(367:1:end) = y;        
        pos2curr = @(xq) interp1(pos,curr,xq,'linear');
        pos2curr = @(xq) interp1(pos,curr,xq,'spline').*[xq<=539].*[xq>=466]; 
end


end