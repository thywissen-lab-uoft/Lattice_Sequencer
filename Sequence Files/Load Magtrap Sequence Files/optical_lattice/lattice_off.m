function timeout =  lattice_off(timein)
global seqdata;

curtime = timein;
%% Magnetic Field ramps for HF imaging

%% Magnetic Field Ramps for LF imaging

%% Turn off feshbach field

if seqdata.flags.lattice_off_feshbach_off   
    tr = getVar('xdtB_feshbach_off_ramptime');
    fesh = getVar('xdtB_feshbach_off_field');        

    % Define the ramp structure
    ramp=struct;
    ramp.shim_ramptime      = tr;
    ramp.shim_ramp_delay    = 0;
    ramp.xshim_final        = seqdata.params.shim_zero(1); 
    ramp.yshim_final        = seqdata.params.shim_zero(2);
    ramp.zshim_final        = seqdata.params.shim_zero(3);
    ramp.fesh_ramptime      = tr;
    ramp.fesh_ramp_delay    = 0;
    ramp.fesh_final         = fesh;
    ramp.settling_time      = 0; 
    curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain 
end

%%
if seqdata.flags.lattice_off_levitate_off  
    tr = getVar('xdtB_levitate_off_ramptime');
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,0,1);               

curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
             @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
                 5,5,0); 
        % Go back to "normal" configuration
        curtime = calctime(curtime,10);
        % Turn off reverse QP switch
        setDigitalChannel(curtime,'Reverse QP Switch',0);
        curtime = calctime(curtime,10);
        % Turn on 15/16 switch
        curtime = AnalogFuncTo(calctime(curtime,0),'15/16 GS',...
             @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
                 10,10,9,1);              
        curtime = calctime(curtime,50);
        
%         curtime = calctime(curtime,1000);
end


%% Band Mapping

% Turn off of lattices
 if (seqdata.flags.lattice_off_bandmap)               
    % Ramp off the XDTs before the lattices    
    logNewSection('Band mapping',curtime);
    
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
 else
    %Snap off lattice
    setAnalogChannel(calctime(curtime,0),'xLattice',seqdata.params.lattice_zero(1));
    setAnalogChannel(calctime(curtime,0),'yLattice',seqdata.params.lattice_zero(2));
    setAnalogChannel(calctime(curtime,0),'zLattice',seqdata.params.lattice_zero(3));
    setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1); 
end

%%
timeout = curtime;
end

