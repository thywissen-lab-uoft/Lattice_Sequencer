function curtime = transport_round_trip(timein)
global seqdata
curtime = timein;

doRoundTripBasic = 0;
doMatchNew = 1;
doRampNew = 1;
doHandOff = 1;
doRamp2 = 1;
     
     if doRoundTripBasic
        logNewSection('round trip transport',curtime);
        defVar('transport_round_trip_point',[150:2:172],'mm');
        defVar('transport_round_trip_number',1,'trips');
        t = 500;
        pos = [174 getVar('transport_round_trip_point')];
        horiz_length = 365;
        pos = pos + horiz_length;
        times = [0 t];        
        for nn=1:getVar('transport_round_trip_number')     
            for kk=1:(length(pos)-1)
                curtime = AnalogFunc(calctime(curtime,0),0,...
                    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
                    times(kk+1)-times(kk), times(kk+1)-times(kk), pos(kk),pos(kk+1));
            end
            for kk=(length(pos)-1):-1:1
                curtime = AnalogFunc(calctime(curtime,0),0,...
                    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
                    times(kk+1)-times(kk), times(kk+1)-times(kk), pos(kk+1),pos(kk));
            end 
        end
     end    
     
%      Load New Current Splines
    data=load('transport_calcs_60G.mat');
    zMatch = 0.1763;     % Position chosen to match end of normal transport
    i14_Match = [0 interp1(data.zz,data.i4,zMatch)];
    i15_Match = [-10.21 interp1(data.zz,data.i5,zMatch)];
    i16_Match = [18.35 interp1(data.zz,data.i6,zMatch)];  
    tmatch = 500;
    
    zCross = 0.153;
    
    z2i12a = @(z) interp1(data.zz,-data.i1,z);
    z2i12b = @(z) interp1(data.zz,-data.i2,z);
    z2i13 = @(z) interp1(data.zz,data.i3,z);
    z2i14 = @(z) interp1(data.zz,data.i4,z);
    z2i15 = @(z) interp1(data.zz,data.i5,z);
    z2i16 = @(z) interp1(data.zz,data.i6,z);
    z2ik = @(z) interp1(data.zz,data.i6+data.i5,z);
        
   
     if doMatchNew
        AnalogFunc(calctime(curtime,0),'Coil 14',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tmatch, tmatch, i14_Match(1),i14_Match(2),3);
        AnalogFunc(calctime(curtime,0),'kitten',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tmatch, tmatch, i16_Match(1)+i15_Match(1),i16_Match(2)+i15_Match(2),4);
        AnalogFunc(calctime(curtime,0),'Coil 16',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tmatch, tmatch, i16_Match(1),i16_Match(2),5);
        
        AnalogFunc(calctime(curtime,0),'Coil 15',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tmatch, tmatch, -7.342,-.4,5);
        
        curtime = calctime(curtime,tmatch);
     end
     
     V0 = 5.5;
     VL = 2.1;
     I0 = -2;
%      defVar('transport_gs_I0',[-2:.l:
     defVar('transport_gs_tau',[1]);
     tau = getVar('transport_gs_tau');
     curr15_2_gs = @(curr) (V0-VL)*(exp(curr/tau)-1)./(exp(I0/tau)-1).*...
         (curr>=I0).*(curr<=0) + ...
         (curr<I0)*(V0-VL)+VL;
%      
%      Ilist = [-5 -4 0];
%      Vlist = [5.5 5.5 2.1];
%          
     tramp = 500;
     if doRampNew
         ff_start = 12.25;
        defVar('transport_round_trip_ff',[12.25],'V');12.25;      
        defVar('transport_round_trip_point',[155],'mm');
        zEnd = getVar('transport_round_trip_point')*1e-3;        
        AnalogFunc(calctime(curtime,0),'Coil 14',...
            @(t,tt,y1,y2) z2i14(ramp_minjerk(t,tt,y1,y2)), ...
            tramp, tramp, zMatch,zEnd,3);
        AnalogFunc(calctime(curtime,0),'kitten',...
            @(t,tt,y1,y2) z2ik(ramp_minjerk(t,tt,y1,y2)), ...
            tramp, tramp, zMatch,zEnd,4);
        AnalogFunc(calctime(curtime,0),'Coil 16',...
            @(t,tt,y1,y2) z2i16(ramp_minjerk(t,tt,y1,y2)), ...
            tramp, tramp, zMatch,zEnd,5);            
        AnalogFunc(calctime(curtime,0),'Transport FF',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, ff_start,getVar('transport_round_trip_ff'),2);
        curtime = calctime(curtime,tramp);
     end
     
     if doHandOff
        tramp2 = 100;
        tramp3 = 200;
        ik = z2ik(zEnd);
        i16 = z2i16(zEnd);
        i14 = z2i14(zEnd);        
        i16_153 = z2i16(153e-3);
        i14_153 = z2i14(153e-3);
        VM = 2.7;
        VL = 2.1;        
       curtime =  AnalogFunc(calctime(curtime,0),'15/16 GS',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp2, tramp2, 5.5,VM,1);          
        AnalogFunc(calctime(curtime,0),'15/16 GS',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp3, tramp3, VM,VL,1);   
        AnalogFunc(calctime(curtime,0),'kitten',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp3, tramp3, ik,i16_153+1,4);  
        AnalogFunc(calctime(curtime,0),'Coil 16',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp3, tramp3, i16,i16_153,5);  
        AnalogFunc(calctime(curtime,0),'Coil 14',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp3, tramp3, i14,i14_153,3);  
        curtime = calctime(curtime,tramp3);        
     end
     
     if doRamp2
        defVar('transport_round_trip_point2',[0],'mm');
        zStart2 = 153*1e-3;   
        zEnd2 = getVar('transport_round_trip_point2')*1e-3;            
        tramp4 = 5;
        tramp5 = 3000;
        
        
        curtime =  AnalogFunc(calctime(curtime,0),'15/16 GS',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp4, tramp4, VL,0,1);         
        curtime = AnalogFunc(calctime(curtime,0),'Coil 15',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            50, 50, -0.4,0,5);
                
        AnalogFunc(calctime(curtime,0),'Coil 12a',...
            @(t,tt,y1,y2) z2i12a(ramp_minjerk(t,tt,y1,y2)), ...
            tramp5, tramp5, zStart2,zEnd2,3);  
        AnalogFunc(calctime(curtime,0),'Coil 12b',...
            @(t,tt,y1,y2) z2i12b(ramp_minjerk(t,tt,y1,y2)), ...
            tramp5, tramp5, zStart2,zEnd2,3);        
        AnalogFunc(calctime(curtime,0),'Coil 13',...
            @(t,tt,y1,y2) z2i13(ramp_minjerk(t,tt,y1,y2)), ...
            tramp5, tramp5, zStart2,zEnd2,3);       
        AnalogFunc(calctime(curtime,0),'Coil 14',...
            @(t,tt,y1,y2) z2i14(ramp_minjerk(t,tt,y1,y2)), ...
            tramp5, tramp5, zStart2,zEnd2,3);
        AnalogFunc(calctime(curtime,0),'Coil 15',...
            @(t,tt,y1,y2) z2i15(ramp_minjerk(t,tt,y1,y2)), ...
            tramp5, tramp5, zStart2,zEnd2,5);
        AnalogFunc(calctime(curtime,0),'kitten',...
            @(t,tt,y1,y2) z2ik(ramp_minjerk(t,tt,y1,y2))+2, ...
            tramp5, tramp5, zStart2,zEnd2,4);
        AnalogFunc(calctime(curtime,0),'Coil 16',...
            @(t,tt,y1,y2) z2i16(ramp_minjerk(t,tt,y1,y2)), ...
            tramp5, tramp5, zStart2,zEnd2,5); 
        curtime = calctime(curtime,tramp5);
     end
     
     if doRamp2
                         
        AnalogFunc(calctime(curtime,0),'Coil 12a',...
            @(t,tt,y1,y2) z2i12a(ramp_minjerk(t,tt,y1,y2)), ...
            tramp5, tramp5, zEnd2,zStart2,3);  
        AnalogFunc(calctime(curtime,0),'Coil 12b',...
            @(t,tt,y1,y2) z2i12b(ramp_minjerk(t,tt,y1,y2)), ...
            tramp5, tramp5, zEnd2,zStart2,3);        
        AnalogFunc(calctime(curtime,0),'Coil 13',...
            @(t,tt,y1,y2) z2i13(ramp_minjerk(t,tt,y1,y2)), ...
            tramp5, tramp5, zEnd2,zStart2,3);       
        AnalogFunc(calctime(curtime,0),'Coil 14',...
            @(t,tt,y1,y2) z2i14(ramp_minjerk(t,tt,y1,y2)), ...
            tramp5, tramp5, zEnd2,zStart2,3);
        AnalogFunc(calctime(curtime,0),'Coil 15',...
            @(t,tt,y1,y2) z2i15(ramp_minjerk(t,tt,y1,y2)), ...
            tramp5, tramp5, zEnd2,zStart2,5);
        AnalogFunc(calctime(curtime,0),'kitten',...
            @(t,tt,y1,y2) z2ik(ramp_minjerk(t,tt,y1,y2))+2, ...
            tramp5, tramp5, zEnd2,zStart2,4);
        AnalogFunc(calctime(curtime,0),'Coil 16',...
            @(t,tt,y1,y2) z2i16(ramp_minjerk(t,tt,y1,y2)), ...
            tramp5, tramp5, zEnd2,zStart2,5); 
         curtime = calctime(curtime,tramp5);

         curtime = AnalogFunc(calctime(curtime,0),'Coil 15',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            50, 50, 0,-0.4,5);
         curtime =  AnalogFunc(calctime(curtime,0),'15/16 GS',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp4, tramp4, 0,VL,1);       
     end
     
     if doHandOff
        AnalogFunc(calctime(curtime,0),'15/16 GS',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp3, tramp3, VL,VM,1);   
        AnalogFunc(calctime(curtime,0),'kitten',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp3, tramp3, i16_153+1,ik,4);         
        AnalogFunc(calctime(curtime,0),'Coil 16',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp3, tramp3, i16_153,i16,5);  
        AnalogFunc(calctime(curtime,0),'Coil 14',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp3, tramp3, i14_153,i14,3); 
        curtime = calctime(curtime,tramp3);
       curtime =  AnalogFunc(calctime(curtime,0),'15/16 GS',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp2, tramp2, VM,5.5,1); 
     end
     
      if doRampNew 
        AnalogFunc(calctime(curtime,0),'Coil 14',...
            @(t,tt,y1,y2) z2i14(ramp_minjerk(t,tt,y1,y2)), ...
            tramp, tramp, zEnd,zMatch,3);
        AnalogFunc(calctime(curtime,0),'kitten',...
            @(t,tt,y1,y2) z2ik(ramp_minjerk(t,tt,y1,y2)), ...
            tramp, tramp, zEnd,zMatch,4);
        AnalogFunc(calctime(curtime,0),'Coil 16',...
            @(t,tt,y1,y2) z2i16(ramp_minjerk(t,tt,y1,y2)), ...
            tramp, tramp, zEnd,zMatch,5);       
        AnalogFunc(calctime(curtime,0),'Transport FF',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, getVar('transport_round_trip_ff'),ff_start,2);    
        curtime = calctime(curtime,tramp);
     end
     
      if doMatchNew
        AnalogFunc(calctime(curtime,0),'Coil 14',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tmatch, tmatch, i14_Match(2),i14_Match(1),3);
        AnalogFunc(calctime(curtime,0),'kitten',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tmatch, tmatch, i16_Match(2)+i15_Match(2),i16_Match(1)+i15_Match(1),4);
        AnalogFunc(calctime(curtime,0),'Coil 16',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tmatch, tmatch, i16_Match(2),i16_Match(1),5);
        AnalogFunc(calctime(curtime,0),'Coil 15',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tmatch, tmatch,-.4,-7.3425,5);        
        curtime = calctime(curtime,tmatch);
     end
% 
end

