function curtime = lattice_FL_wrapper(curtime)

if nargin==0
   curtime = 0; 
end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% Enable and Disable Beams %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fluor = struct;
    fluor.EnableUWave           = 0;
    fluor.EnableFpump           = 0;
    fluor.EnableEITProbe        = 0;
    fluor.EnableRaman           = 0;
    
    fluor.PulseTime             = 10; % in ms

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% Camera Settings %%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fluor.TriggerIxon          = 1;
    fluor.NumberOfImages       = 1;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% Magnetic Field Settings %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This sets the quantizing field along the fpump axis.
    fluor.doInitialFieldRamp    = 1;    
    
    B0 = 4; % Quantization Field
    B0_shift_list = [0.095];
    
    % Quantization Field 
    B0_shift = getScanParameter(...
        B0_shift_list,seqdata.scancycle,seqdata.randcyclelist,...
        'qgm_field_shift','G');  
    
    fluor.CenterField = B0 + B0_shift;
    
    addOutputParam('qgm_field',fluor.CenterField,'G');    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% uWave Settings %%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    uWave_Freq_Shift_List = [-200:50:200];
    
    uwave_freq_shift = getScanParameter(...
        uWave_Freq_Shift_List,seqdata.scancycle,seqdata.randcyclelist,...
        'qgm_uwave_freq_shift','kHz');     
    
    
    fluor.uWave_Frequency = 1296.824 + uwave_freq_shift/1000;
    fluor.uWave_Power = 15;
    
    addOutputParam('qgm_uWave_Frequency',fluor.uWave_Frequency,'MHz');    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% EIT Settings %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    F_Pump_List = [2];
    fluor.F_Pump_Power = getScanParameter(F_Pump_List,...
        seqdata.scancycle,seqdata.randcyclelist,'F_Pump_Power','V');
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% Raman Settings %%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
      
    %%% Raman 1 %%%
    V10 = 1.3;
    Raman1_Power_List = V10*[1];
    Raman1_ShiftFreq_List = [-175];       
    
    Raman1_Freq_Shift = getScanParameter(Raman1_ShiftFreq_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman1_Freq_Shift','kHz');       
    Raman1_Power = getScanParameter(Raman1_Power_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman1_Power','V'); 
    
    fluor.Raman1_EnableSweep = 0;
    fluor.Raman1_Power = Raman1_Power;
    fluor.Raman1_Frequency = 110 + Raman1_Freq_Shift/1000;
        
    %%% Raman 2 %%%
    V20 = 1.36;   
    Raman2_Power_List = V20*[1];
    Raman2_ShiftFreq_List = [0];       
    
    Raman2_Freq_Shift = getScanParameter(Raman2_ShiftFreq_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman2_Freq_Shift','kHz');       
    Raman2_Power = getScanParameter(Raman2_Power_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman2_Power','V'); 
    
    fluor.Raman2_EnableSweep = 0;
    fluor.Raman2_Power = Raman2_Power;
    fluor.Raman2_Frequency = 80 + Raman2_Freq_Shift/1000;        
    
    % Calculate frequencies (the Rigol and EOM could be programmed every
    % run, but for now they are manuually specified).
    raman_eom_freq = 1266.924;
    
    raman_2photon_freq = (raman_eom_freq + fluor.Raman2_Frequency) - ...
        fluor.Raman1_Frequency;
    raman_2photon_detuning = (raman_2photon_freq - seqdata.constants.hyperfine_ground)*1e3;

    addOutputParam('qgm_raman_eom_freq',raman_eom_freq,'MHz');    
    addOutputParam('qgm_raman1_freq',fluor.Raman1_Frequency,'MHz');
    addOutputParam('qgm_raman2_freq',fluor.Raman2_Frequency,'MHz');
    addOutputParam('qgm_raman_2photon_freq',raman_2photon_freq,'MHz');
    addOutputParam('qgm_raman_2photon_detuning',raman_2photon_detuning,'kHz');
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% Run Sub Function %%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
    curtime = lattice_FL(curtime,fluor);  
end

