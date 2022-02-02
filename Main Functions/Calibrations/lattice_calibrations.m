function [xLattice,yLattice,zLattice] = lattice_calibrations

global seqdata

%% Zero optical power calibration
% These voltages are the "zero" lattice levels.  Use these values when
% ramping up the lattice from totally zero power to smooth out ramps.
xLattice0_list = [-0.85];[-1.64];
xLattice0 = getScanParameter(xLattice0_list,...
    seqdata.scancycle,seqdata.randcyclelist,'xLatt0');

yLattice0_list =  -0.58;%-0.955;-1.05;[-1.15];
yLattice0 = getScanParameter(yLattice0_list,...
    seqdata.scancycle,seqdata.randcyclelist,'yLatt0');

zLattice0_list = 0.38;0.35;0.26;0.46;[0.40];0.44;
zLattice0 = getScanParameter(zLattice0_list,...
    seqdata.scancycle,seqdata.randcyclelist,'zLatt0');  
% These parameters could be super sensitive to cause spikes and kill atoms

seqdata.params.lattice_zero = [xLattice0 yLattice0 zLattice0];

%% Low lattice depth calibration
% This is the low lattice depth calibration function.  This will be most
% useful for science lattices and lattice turn on.

% X Lattice
xLatticeL = @(U_Er) (U_Er)/134.58-2.6*1E-3;      % 2021/08/03
% Y Lattice
yLatticeL = @(U_Er) (U_Er)/151.32+15.5*1E-3;     % 2021/08/03
% Z Lattice
zLatticeL = @(U_Er) (U_Er)/95.66+2.6E-3;         % 2021/08/03 

%% High lattice depth calibration
% This is the high lattice depth calibration function.  This will be most
% useful for fluorescence imaging

% X Lattice
xLatticeH = @(U_Er)(U_Er+8.28)/117.3;            % 2021/05/04
% Y Lattice
yLatticeH = @(U_Er)(U_Er+8.6812)/141.2965;       % 2021/04/23
% Z Lattice
zLatticeH = @(U_Er)((U_Er+8.5772)/89.2457);      % 2021/04/23 

%% Combine the calibrations

% Threshold lattice depth to connect different calibrations
U0 = [150 150 150]; % Merge location in Er
dU = [20 20 20];    % Merging radius

xLattice = @(U) ...
    xLatticeL(U).*0.5.*(erfc((U-U0(1))/dU(1)))+ ...    
    xLatticeH(U).*0.5.*(erf((U-U0(1))/dU(1))+1); 

yLattice = @(U) ...
    yLatticeL(U).*0.5.*(erfc((U-U0(2))/dU(2)))+ ...    
    yLatticeH(U).*0.5.*(erf((U-U0(2))/dU(2))+1);

zLattice = @(U) ...
    zLatticeL(U).*0.5.*(erfc((U-U0(3))/dU(3)))+ ...    
    zLatticeH(U).*0.5.*(erf((U-U0(3))/dU(3))+1);

doDebug=0;
if doDebug
    hF=figure;
    hF.Position=[100 100 1200 300];
    hF.Color='w';
    
    % Sample points
    Uvec=linspace(-100,1300,1E4);
    
    subplot(131)
    plot(Uvec,xLatticeL(Uvec),'linewidth',3);
    hold on
    plot(Uvec,xLatticeH(Uvec),'linewidth',3);
    plot(Uvec,xLattice(Uvec),'k-','linewidth',1);
    legend({'low','high','merge'},'location','southeast');
    xlim([0 800]);
    xlabel('x lattice (E_R)');
    ylabel('voltage output (V)');
    set(gca,'xgrid','on','ygrid','on','box','on','linewidth',1);
    
    subplot(132)
    plot(Uvec,yLatticeL(Uvec),'linewidth',3);
    hold on
    plot(Uvec,yLatticeH(Uvec),'linewidth',3);
    plot(Uvec,yLattice(Uvec),'k-','linewidth',1);
    legend({'low','high','merge'},'location','southeast');
    xlim([0 800]);
    xlabel('y lattice (E_R)');
    ylabel('voltage output (V)');
    set(gca,'xgrid','on','ygrid','on','box','on','linewidth',1);

    subplot(133)
    plot(Uvec,zLatticeL(Uvec),'linewidth',3);
    hold on
    plot(Uvec,zLatticeH(Uvec),'linewidth',3);
    plot(Uvec,zLattice(Uvec),'k-','linewidth',1);
    legend({'low','high','merge'},'location','southeast');
    xlim([0 800]);
    xlabel('z lattice (E_R)');
    ylabel('voltage output (V)');
    set(gca,'xgrid','on','ygrid','on','box','on','linewidth',1);
end

%% X Lattice new
x_power2voltage = @(P) (P*48.2126 - 9.6744).*(P < 0.24467) + ...
    (P*4.0806 + 1.1235).*(P >= 0.24467);
x_ErPerW = 346;

% x_lattice2voltage = @(U) x_power2voltage(U/x_ErPerW); 
xLattice = @(U) x_power2voltage(U/x_ErPerW);

%% Y Lattice new
y_power2voltage = @(P) (P*54.731069 - 9.655506).*(P < 0.213147) + ...
    (P*4.166124 + 1.122266).*(P >= 0.213147);
% y_power2voltage = @(P) (P*54.73 - 9.66).*(P < 0.21) + ...
%     (P*4.17 + 1.12).*(P >= 0.21);
y_ErPerW = 346;346;

% x_lattice2voltage = @(U) x_power2voltage(U/x_ErPerW); 
yLattice = @(U) y_power2voltage(U/y_ErPerW);
end

