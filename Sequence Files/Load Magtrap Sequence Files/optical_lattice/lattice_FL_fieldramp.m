function curtime = lattice_FL_fieldramp(curtime)
global seqdata

% Mangetic Field
    doInitialFieldRamp    = 1;        % Auto specify ramps       
    doInitialFieldRamp2   = 0;        % Manually specify ramps 

    %% Magnetic Field Settings
% This sets the quantizing field along the fpump axis. It is assumed that
% you are imaging along the FPUMP axis
    
    B0 = 4;         % Quantization Field
    B0_shift_list = [0.22];0.23;[0.24];.21;
    
    % Quantization Field 
    B0_shift = getScanParameter(...
        B0_shift_list,seqdata.scancycle,seqdata.randcyclelist,...
        'qgm_field_shift','G');  
    
    CenterField = B0 + B0_shift;
    
    addOutputParam('qgm_field',CenterField,'G');   
    
%% INITIAL MAGNETIC FIELD RAMP
% Should probably move to a different subfunction

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% Magnetic Field Settings %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Additional Magnetic field offset
X_Shim_Offset = 0;
Y_Shim_Offset = 0;
Z_Shim_Offset = 0.055;

% Selection angle between X and Y shims
theta_list = [62];
theta = getScanParameter(theta_list,...
    seqdata.scancycle,seqdata.randcyclelist,'qgm_Bfield_angle','deg');

% Convert the quantization magnetic field to frequency (|9,-9>->|7,-7>)
df = CenterField*2.4889; % MHz

% Coefficients that convert from XY shim current (A) to frequency (MHz) 
shim_calib = [2.4889*2, 0.983*2.4889*2]; % MHz/A

% Field strength and angle into current
X_Shim_Value = df*cosd(theta)/shim_calib(1);
Y_Shim_Value = df*sind(theta)/shim_calib(2);
%%
% Ramp up gradient and Feshbach field  
if doInitialFieldRamp

    % What the code should do :
    % Turn off Feshbachbach Field (close switch as well)
    % Turn off QP Field (should probably set FF to zero)
    % Ramp the shims to the correct value

    newramp = struct('ShimValues',seqdata.params.shim_zero + ...
        [X_Shim_Value+X_Shim_Offset, ...
        Y_Shim_Value+Y_Shim_Offset, ...
        Z_Shim_Offset],...
        'FeshValue',0.01,...
        'QPValue',0,...
        'SettlingTime',100);
    
%     setDigitalChannel(calctime(curtime,-200),'Z shim bipolar relay',1);
    
curtime = rampMagneticFields(calctime(curtime,0), newramp);
end      

%% Magnetic Field Ramp 2

if doInitialFieldRamp2
    tShimRamp = 100;
    tShimSettle = 10;
    tFBRamp = 100;
    tFBSettle = 50;
    
    Ix = X_Shim_Value + X_Shim_Offset + seqdata.params.shim_zero(1);
    Iy = Y_Shim_Value + Y_Shim_Offset + seqdata.params.shim_zero(2);
    Iz = Z_Shim_Offset + seqdata.params.shim_zero(3);    
    
    %Ramp shim fields
    AnalogFuncTo(calctime(curtime,0),'X Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        tShimRamp,tShimRamp,Ix,3);
    AnalogFuncTo(calctime(curtime,0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        tShimRamp,tShimRamp,Iy,4);
    AnalogFuncTo(calctime(curtime,0),'Z Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        tShimRamp,tShimRamp,Iz,3);
    curtime = calctime(curtime,tShimRamp);
    
    curtime = calctime(curtime,tShimSettle);
    
    % Turn off FB and any QP Field
    
    % Turn off FB Current
    AnalogFuncTo(calctime(curtime,0),'FB current',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        tFBRamp,tFBRamp,0);
    
    % Turn off transport supply
    AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        tFBRamp,tFBRamp,0);
    
    curtime = calctime(curtime,tFBRamp);    
    curtime = calctime(curtime,tFBSettle); 
end
    
%% Extra Settling Time

curtime = calctime(curtime,100);

end

