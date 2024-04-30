function timeout =  lattice_off(timein)
global seqdata;

curtime = timein;
%% Ramp for HF imaging

if seqdata.flags.High_Field_Imaging
%    curtime = lattice_HF(curtime);
end

%% Lattice Band Map

% Turn off of lattices
 if (seqdata.flags.lattice_off_bandmap)
     curtime = calctime(curtime,15);
     
    % Scope Trigger for bandmap
    ScopeTriggerPulse(curtime,'lattice_off');     
     
    % Ramp off the XDTs before the lattices    
    dispLineStr('Ramping down XDTs',curtime);
    dip_rampstart = -15;
    dip_ramptime = 5;
    dip1_endpower = seqdata.params.ODT_zeros(1);
    dip2_endpower = seqdata.params.ODT_zeros(2);
    disp([' Ramp Start (ms) : ' num2str(dip_rampstart) ]);
    disp([' Ramp Time  (ms) : ' num2str(dip_ramptime) ]);
    disp([' End Power   (W) : ' num2str(dip_endpower)]);
   
    AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        dip_ramptime,dip_ramptime,dip1_endpower);
    AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        dip_ramptime,dip_ramptime,dip2_endpower);
    setDigitalChannel(calctime(curtime,dip_rampstart+dip_ramptime),...
        'XDT TTL',1);   
    
    % Band Map time (ms)
    bm_time_list = [3];
    bm_time = getScanParameter(bm_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'lattice_bm_time','ms'); %Whether to down a rampdown for bandmapping (1) or snap off (0) - number is also time for rampdown

    lat_rampdowntime =bm_time*1;        % how long to ramp (0: switch off)   %1ms
       
    xlat_endpower=seqdata.params.lattice_zero(1);
    ylat_endpower=seqdata.params.lattice_zero(2);
    zlat_endpower=seqdata.params.lattice_zero(3);

    if lat_rampdowntime > 0
        dispLineStr('Band mapping',curtime);
        
        disp([' Band Map Time (ms) : ' num2str(lat_rampdowntime)])
        disp([' xLattice End (Er)  : ' num2str(xlat_endpower)])
        disp([' yLattice End (Er)  : ' num2str(ylat_endpower)])
        disp([' zLattice End (Er)  : ' num2str(zlat_endpower)])

        AnalogFuncTo(calctime(curtime,0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
            lat_rampdowntime,lat_rampdowntime,xlat_endpower);
        AnalogFuncTo(calctime(curtime,0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),lat_rampdowntime,...
            lat_rampdowntime,ylat_endpower);
curtime =   AnalogFuncTo(calctime(curtime,0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),lat_rampdowntime,...
            lat_rampdowntime,zlat_endpower);
    end   
    
    setDigitalChannel(calctime(curtime + 0.5,0),'yLatticeOFF',1); 
    setDigitalChannel(calctime(curtime + 0.5,0),'Lattice Direct Control',1); 
end

%%
timeout = curtime;
end

