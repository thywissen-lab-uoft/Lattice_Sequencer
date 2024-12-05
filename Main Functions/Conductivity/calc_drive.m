function [x0, y0, aL, aH] = calc_drive(Tpred,Gpred,amp_desired)
    %% Constants
    h = 6.626e-34;
    hbar = h/(2*pi);
    kb = 1.380649e-23;
    aL = 527e-9;
    amu = 1.660538921e-27;
    m = 39.964008*amu;
    %Feb 2024, scaled by 3.55 um/V
    %Oct 2024, scaled by 2.63 um/V
    v2um = 2.63;
    
    %% Define the lookup tables for R and E
    global Rvalues;
    Rvalues_unscaled = table2array(readtable('Lookup Tables/Rvalues_unscaled_55Hz_200.csv'));
    Rvalues = -1j*(aL/pi)*Rvalues_unscaled;
    
    global energies;
    energies_Hz = importdata('Lookup Tables/EnergyHz_55Hz_200.txt');
    energies = h*(energies_Hz);
    
    %% Trap parameters
    wXDT = 2*pi*42.5; %2*pi*Hz
    tunneling = 563.4109123332288;
    
    %% Put Temp and Gamma guesses in units required for qfit functions
    T = Tpred*tunneling*h/kb; %K 4*tunneling*h/kb; %K
    G = Gpred; %s^-1
    
    %% Create data points
    d = [];
    f = [10:1:150];
    for ff = 1:length(f)
        d(ff) = hbar*2*pi*f(ff)*amp_desired/(aL^2*m*wXDT^2*sqrt(qfit_real(T,G,2*pi*f(ff))^2+qfit_imag(T,G,2*pi*f(ff))^2))/v2um; %V
    end
    
    %% Fit the response
    
    %Find the Minimum of the required drive(f)
    [d0,ind]=min(d);
    f0 = f(ind);
    
    %Quick fourth order fit to find initial guesses
    pp = polyfit(f-f0,d,4);
    
    %Fit the high frequency and low frequency regimes separately
    WH = [f>=f0]';
    WL = [f<=f0]';
    
    %Define fitting function (even 8th order polynomial)
    myfit = fittype(@(a8,a6,a4,a2,x) d0 + a2*(x-f0).^2 + a4*(x-f0).^4+ a6*(x-f0).^6+ a8*(x-f0).^8,...
        'independent',{'x'},'coefficients',{'a8','a6','a4','a2'});
    opt = fitoptions(myfit);
    
    %Fitting options
    opt.StartPoint = [0 0 pp(1) pp(2)];
    opt.Robust = 'bisquare';
    
    %Fit the high frequency regime
    opt.Weights = double(WH);
    foutH = fit(f',d',myfit,opt);
    
    %Fit the low frequency regime
    opt.Weights = double(WL);
    foutL = fit(f',d',myfit,opt);

    %% Define function output
    x0 = round(f0,3);
    y0 = round(d0,4);
    aL = [foutL.a2 foutL.a4 foutL.a6 foutL.a8];
    aH = [foutH.a2 foutH.a4 foutH.a6 foutH.a8];
    
    %% Plotting
    % Find Figure... or make it
    FigName = 'Drive';
    ff=get(groot,'Children');
    fig=[];
    for kk=1:length(ff)
        if isequal(ff(kk).Name,FigName)
            fig = ff(kk);
        end
    end
    
    if isempty(fig)
        fig=figure;
        fig.Name=FigName;
        fig.WindowStyle='docked';
        fig.Color='w';
    end

    %Clear figure
    clf(fig);
    fig.NumberTitle='off';
    co=get(gca,'colororder');
    
    %Plot the calculated drive amplitude
    plot(f,d,'k.-')
    hold on;
    xlabel('drive frequency (Hz)');
    ylabel('drive amplitude (V)');
    
    % plot(xx,yy,'r')
    % plot(x2,y2,'b')
    xlim([10,130])
    
    plot(f(f>=(f0)),feval(foutH,f(f>=(f0))),'r-','linewidth',1)
    plot(f(f<=f0),feval(foutL,f(f<=f0)),'b-','linewidth',1)
    
    s = ['$y = y_0 + a_2(x-x_0)^2 + a_4(x-x_0)^4 + a_6(x-x_0)^6 + a_8(x-x_0)^8$'];
    s = [s newline '$(x_0,y_0) = ' num2str(x0) ',' num2str(y0) '$'];
    s = [s newline '$(a_2,a_4,a_6,a_8)_L = ($' num2str(foutL.a2,'%.2e') ',' ...
        num2str(foutL.a4,'%.2e') ', ' ...
        num2str(foutL.a6,'%.2e') ', ' ...
        num2str(foutL.a8,'%.2e') '$)$'];
    s = [s newline '$(a_2,a_4,a_6,a_8)_H = ($' num2str(foutH.a2,'%.2e') ',' ...
        num2str(foutH.a4,'%.2e') ', ' ...
        num2str(foutH.a6,'%.2e') ', ' ...
        num2str(foutH.a8,'%.2e') '$)$'];
    
    text(.01,.98,s,'interpreter','latex','units','normalized','fontsize',12,...
        'verticalalignment','top');
    title(['T/t = ' num2str(T/(h*tunneling/kb)) , ', \Gamma/t = ' num2str(G/(2*pi*tunneling)) ', Desired Amp. = ' num2str(amp_desired) '\mum' ])

end

