function timeout =  lattice_off(timein)
global seqdata;

curtime = timein;
%% Magnetic Field ramps for HF imaging

%% Magnetic Field Ramps for LF imaging

%% Band Mapping

% Turn off of lattices
 if (seqdata.flags.lattice_off_bandmap)               
    % Ramp off the XDTs before the lattices    
    dispLineStr('Band mapping',curtime);
    
    % Scope Trigger for bandmap
    ScopeTriggerPulse(curtime,'lattice_off');     


    % XDT Ramp off settings
    xdt_ramptime=getVar('lattice_bm_xdt_ramptime');  
    dip1_endpower = seqdata.params.ODT_zeros(1);
    dip2_endpower = seqdata.params.ODT_zeros(2);    
    
    % Display
    disp([' Ramping off XDTs']);
    disp([' Ramp Time  (ms) : ' num2str(xdt_ramptime) ]);   
    
    % Ramp them
    if xdt_ramptime>0
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            xdt_ramptime,xdt_ramptime,dip1_endpower);
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            xdt_ramptime,xdt_ramptime,dip2_endpower);
    end
    setDigitalChannel(calctime(curtime,xdt_ramptime),...
        'XDT TTL',1);   
    
    % Advance curtime is non-simultaenous ramp off
    if ~seqdata.flags.lattice_off_bandmap_xdt_off_simultaneous       
        dip_waittime = getVar('lattice_bm_xdt_waittime');
        curtime = calctime(curtime,xdt_ramptime+dip_waittime);
        disp([' Wait Time  (ms) : ' num2str(dip_waittime) ]);   
    end
       
    
    % Band Map time (ms)
    bm_time=getVar('lattice_bm_time');       
    Ux_off=seqdata.params.lattice_zero(1);
    Uy_off=seqdata.params.lattice_zero(2);
    Uz_off=seqdata.params.lattice_zero(3);
    if bm_time > 0
        disp([' Band Map Time (ms) : ' num2str(bm_time)])
        disp([' xLattice End (Er)  : ' num2str(Ux_off)])
        disp([' yLattice End (Er)  : ' num2str(Uy_off)])
        disp([' zLattice End (Er)  : ' num2str(Uz_off)])

        AnalogFuncTo(calctime(curtime,0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
            bm_time,bm_time,Ux_off);
        AnalogFuncTo(calctime(curtime,0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),bm_time,...
            bm_time,Uy_off);
        AnalogFuncTo(calctime(curtime,0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),bm_time,...
            bm_time,Uz_off);
        curtime = calctime(curtime,bm_time);
    else
        disp('Snapping off lattice');
    end       
    setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1); 
end

%%
timeout = curtime;
end

