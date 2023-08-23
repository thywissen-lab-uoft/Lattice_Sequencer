function  timeout = doVerticalTransport_1(timein,T,D)
global seqdata
curtime = timein;
%%
% 12a, 12b, 13, 14, 15, 16, kitten
transport_functions = [3 3 3 2 5 5 3];     
transport_names = {'Coil 12a','Coil 12b','Coil 13','Coil 14','Coil 15','Coil 16','kitten'};


% 12a, 12b, 13, 14, 15, 16, kitten
transport_functions = [3 3 3 2 5 5 2];     
transport_names = {'Coil 12a','Coil 12b','Coil 13','Coil 14','Coil 15','Coil 16','Transport FF'};

data = load('transport_calcs.mat');
currentarray = zeros(length(T)*length(transport_names),3);
N = length(T);
for kk=1:length(transport_names)
    x = data.zz*1e3;
    chnum = name_lookup(transport_names{kk},1);
    func_index = transport_functions(kk);
    switch transport_names{kk}                
        case 'Coil 12a'
            y = -data.i1;                       
        case 'Coil 12b'
            y = -data.i2;    
        case 'Coil 13'
            y = data.i3;                    
        case 'Coil 14'
            y = data.i4;    
        case 'Coil 15'
            y = data.i5;    
        case 'Coil 16'
            y = data.i6;    
        case 'Transport FF'
             ff_endpoints =[ ...
                 0 10;      % Start at horizontal
                 24 11.25;  % 12a 13 center
                 48 11.25;  % low current in between zone
                 68 11.25;  % 12b 14 center
                 89 11.5;   % low current in between zone
                 104 20   % 13 15 center
                 120 20;  % low in between
                 150 20  % 14 16 cetner
                 174 20];  % Ending (all on)];  
             x = ff_endpoints(:,1);
             y = ff_endpoints(:,2);
    end
    
    ySample = interp1(x,y,D,'linear');     
    
    if isequal(transport_names{kk},'Transport FF')
        ySample = interp1(x,y,D,'pchip'); 
    end
    
    currentarray((1:N)+(kk-1)*N,1) = timein + T*seqdata.timeunit/seqdata.deltat;
    currentarray((1:N)+(kk-1)*N,2) = ones(N,1)*chnum;
    currentarray((1:N)+(kk-1)*N,3) = ySample;
    
    current2voltage = seqdata.analogchannels(chnum).voltagefunc{func_index};            
    voltages = current2voltage(ySample);
    
    currentarray((1:N)+(kk-1)*N,3) = voltages;   
    
%     if isequal(transport_names{kk},'Coil 16')
%         keyboard
%     end
end

    seqdata.analogadwinlist = [seqdata.analogadwinlist; currentarray];

%%
timeout = calctime(curtime,T(end));
end

