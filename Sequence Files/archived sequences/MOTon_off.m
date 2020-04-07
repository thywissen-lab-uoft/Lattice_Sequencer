%------
%Author: David McKay
%Created: July 2009
%Summary: This oscillates the MOT on and off
%------ 

function timeout = MOTon_off(timein)


curtime = timein;

mot_ttl = 1;
mag_off = 1;

curtime = calctime(curtime,2);

if mag_off
    DigitalPulse(curtime,16,0.5,mot_ttl);
else
    
    DigitalPulse(curtime,16,0.5,mot_ttl);
    
    %analog
    setAnalogChannel(curtime,3,0.0);
    %TTL
    setDigitalChannel(curtime,6,1); 
    %trap shutter
    setDigitalChannel(curtime,2,0);
    
    %repump shutter
    setDigitalChannel(curtime,5,0);
    
end

curtime = Load_MOT(calctime(curtime,2),38);
% 
% 
% curtime = calctime(curtime,5000);
% %setDigitalChannel(curtime,12,0);
% 
% for i = 1:3
%         
%     curtime = DigitalPulse(calctime(curtime,10000),16,0.5,mot_ttl); %MOT TTL
%     
%     %curtime = setAnalogChannel(calctime(curtime,200),5,16+16*mot_ttl);
%     
%     %mot_ttl = ~mot_ttl;
%     
% end