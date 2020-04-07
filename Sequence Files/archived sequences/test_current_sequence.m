%------
%Author: David McKay
%Created: July 2009
%Summary: This runs current through one of the coils
%------
function timeout = test_current_sequence(timein,channel,duration,current)

curtime = timein;

for i = 1:length(channel)
    %turn on the coil
    switch channel(i)
        case 7 %push coil
            setAnalogChannel(curtime,7,current(i),2);
            %setAnalogChannel(curtime,16,-current(i)/2,2);
         case 8 %MOT
             setAnalogChannel(curtime,8,current(i),2);
             setDigitalChannel(curtime,12,1); %MOT TTL
        otherwise
            setAnalogChannel(curtime,channel(i),current(i),2);
    end
end

%turn off the coil
curtime = calctime(curtime,duration);
for i = 1:length(channel)
    curtime = setAnalogChannel(curtime,channel(i),0,1);
end

%setAnalogChannel(curtime,16,0,1);

setDigitalChannel(curtime,12,0);

AddOutputParam('test',1);
AddOutputParam('test2',100.20394);
timeout = curtime;

end