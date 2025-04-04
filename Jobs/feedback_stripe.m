function doExitPID = feedback_stripe(data,doFeedback)
doExitPID = 0;
global mainGUI_Directory;
clear freqs
clear phi
clear stripes
src ='StripeCircular';
clear t
clear phi

%% Engage Feedback
% Engage Feedback?
% doFeedback=1;

if nargin==1
    doFeedback=0;
end

%% Feedback Settings

% (X,Y) pixel position to stabilize the phase
% CJF: Warning! Do not change this without careful thought. Changing this
% value will change what magnetic field the stripes stabilize to
nCenter = [276,256]; 

% Feedback bounds
Lambda_Lim = [70 80];   % [px] Wavelength bounds for stripes
Theta_Lim = [-3 2];   % [deg] Angle bounds for stripes
Time_max = 40;          % [min] maximum number of minutes to feedback on    
    
% Plane Separation [kHz/plane]
kappa = 80;

% Maximum Step Size [kHz]
df_max = 20;

% PID Gain Settings
% Because we know the feedback slope, the gains gain be calculated exactly.
% For this reason the sums of gains should equal to one.
gain_P = 0.6;          
gain_I = 1 - gain_P;
        
% Integral time constant [min.]
tau_I = 15;             

% Minutes to plot things
tMinLim=60;

% String Descriptor of PID
strPID = ['$(G_p,G_I,\tau,\kappa) : (' num2str(gain_P) ',' ...
    num2str(gain_I) ',' num2str(tau_I) '~\mathrm{min.},' ...
    num2str(kappa) '~\mathrm{kHz/plane})$'];

%% Collect Data

try
    % Collect stripes, local phase, and freqs
    warning off
    for l=1:length(data)
        if isfield(data{l},src)
            if exist('stripes','var')
                stripes(end+1) = data{l}.(src)(1);
                freqs(end+1) = data{l}.Params.f_offset;
                t(end+1) = data{l}.Params.ExecutionDate;
                plane_shift(end+1) = data{l}.Params.qgm_planeShift_N;
                phi(end+1) = stripes(end).PhaseFunc(nCenter(1),nCenter(2));
            else
                stripes(1) = data{l}.(src)(1);
                freqs(1) = data{l}.Params.f_offset;
                t(1) = data{l}.Params.ExecutionDate;
                phi(1) = stripes(end).PhaseFunc(nCenter(1),nCenter(2));
                plane_shift(1) = data{l}.Params.qgm_planeShift_N;
            end
        end
    end    
    warning on

    t= datetime(t,'convertfrom','datenum');

    % Collect Wavelength, Radius, Theta
    Lambda = [stripes.Lambda];
    Theta = [stripes.Theta]*180/pi;
    Radius = [stripes.Radius];
    phi_plane = (mod(phi+pi,2*pi)-pi)/(2*pi); % Map phase from [-.5,.5]   
%% Initialize Figure
    % Find Figure... or make it
    FigName = 'Stripe';
    ff=get(groot,'Children');
    fig=[];
    for kk=1:length(ff)
        if isequal(ff(kk).Name,FigName)
            fig = ff(kk);
        end
    end

    % Set figure settings
    if isempty(fig)
        fig=figure;
        fig.Name=FigName;
%         fig.WindowStyle='docked';
        fig.Color='w';
        fig.Position=[1 5 1080 260];
    end
    
    

    clf(fig);
    co=get(gca,'colororder');
    fig.NumberTitle='off';
    set(fig,'menubar','none','toolbar','none');
    tNow = datetime(now,'convertfrom','datenum');

    %% initialize tabs
hpTG = uitabgroup(fig,'units','normalized','position',[0 0 1 1]);
tSummary = uitab(hpTG,'Title','summary','backgroundcolor','w');
tDetails = uitab(hpTG,'Title','details','backgroundcolor','w');

    %% Plot Recent Stripe Data
    
    % Wavelength Plot
    axW=subplot(2,3,1,'Parent',tDetails);
    plot(t,Lambda,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',axW);
    ylabel(axW,'Wavelength \lambda (sites)');
    set(axW,'XLim',tNow+[-minutes(tMinLim) 0]);
   
    
    % Angle Plot
    axA=subplot(2,3,2,'Parent',tDetails);
    plot(t,Theta,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',axA);
    ylabel(axA,'Rot. Angle \theta (deg)');
    set(axA,'XLim',tNow+[-minutes(tMinLim) 0]);

    % Radius Plot
    axR=subplot(2,3,3,'Parent',tDetails);
    plot(t,Radius,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',axR);
    ylabel(axR,'Radius R (sites)');       
    set(axR,'XLim',tNow+[-minutes(tMinLim) 0]);

    % Phase plot
    axP=subplot(2,3,4,'Parent',tDetails);
    plot(t,phi_plane,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',axP);
    ylabel(axP,'Phase \phi (planes)');  
    set(axP,'XLim',tNow+[-minutes(tMinLim) 0]);

    % Frequencies
    axF=subplot(2,3,5,'Parent',tDetails);
    plot(t,freqs,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',axF);
    ylabel(axF,'freq (kHz)');  
    set(axF,'XLim',tNow+[-minutes(tMinLim) 0]);
    
    % Plane Shift
     axS=subplot(2,3,6,'Parent',tDetails);
    plot(t,plane_shift,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',axS);
    ylabel(axS,'plane shift (planes)');  
    set(axS,'XLim',tNow+[-minutes(tMinLim) 0]);
    
    

%% Calculate Stuff
    % Get Time now
    timeAgo = minutes(tNow-t);

    % Find data that is outside the limits
    bad_Lambda  = [Lambda<Lambda_Lim(1)]+[Lambda>Lambda_Lim(2)];% Bad Wavelength
    bad_Theta   = [Theta<Theta_Lim(1)]+[Theta>Theta_Lim(2)];    % Bad Angle
    bad_Time    = [timeAgo>Time_max];                           % Bad Time
    bad_PlaneShift = [plane_shift~=plane_shift(1)];             % Only consider first plane shift
    bad_inds    = bad_Lambda+bad_Theta+bad_Time+bad_PlaneShift;
    bad_inds    = logical(bad_inds);

    % Remove bad data points from feedback data
    freqs_fb = freqs;freqs_fb(bad_inds)=[];
    timeAgo_fb = timeAgo;timeAgo_fb(bad_inds)=[];
    phi_plane_fb = phi_plane;phi_plane_fb(bad_inds)=[];          

    % Save the bad data point values
    freqs_bad = freqs(bad_inds);
    timeAgo_bad = timeAgo(bad_inds);
    phi_plane_bad = phi_plane(bad_inds);    
%%
    % Plot Frequency Feedback Values
    ax1=subplot(1,2,1,'Parent',tSummary);
    pFreq_FB=plot(timeAgo_fb,freqs_fb,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax1);
    ylabel(ax1,'freq (kHz)');
    xlabel(ax1,'time ago (min.)');
    hold(ax1,'on');
    pFreq_BAD=plot(timeAgo_bad,freqs_bad,'rx',...
        'linewidth',1,'markersize',8,'parent',ax1);
    tStr = ['Now : ' datestr(datetime(now,'convertfrom','datenum'))];
    text(.01,.99,tStr,'units','normalized','parent',ax1,...
        'verticalalignment','top','horizontalalignment','left');
    title('frequency offset (control)','parent',ax1);
    set(ax1,'XLim',[0 tMinLim]);
    
    
    % Plot Phase Values
    ax2=subplot(1,2,2,'Parent',tSummary);
    pPhase_FB=plot(timeAgo_fb,phi_plane_fb,'o-',...
        'markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax2);
    hold(ax2,'on');
    pPhase_BAD=plot(timeAgo_bad,phi_plane_bad,'rx',...
        'linewidth',1,'markersize',8,'parent',ax2);    
    ylabel(ax2,'Phase \phi (planes)');
    xlabel(ax2,'time ago (min.)');
    text(.01,.99,tStr,'units','normalized','parent',ax2,...
        'verticalalignment','top','horizontalalignment','left');
    title('measured phase (error)','parent',ax2);
    set(ax2,'XLim',[0 tMinLim],'YLim',[-.5 .5],'YTick',[-.5:.1:.5],'YGrid','on');
    
    text(.01,.01,strPID,'units','normalized','parent',ax2,...
        'verticalalignment','bottom','horizontalalignment','left',...
        'interpreter','latex');
    
    legend([pPhase_FB pPhase_BAD],{'feedback','ignore'},...
        'location','best');



    if doFeedback && ~bad_inds(1) && length(phi_plane_fb)>1
        % Proportional Error (most recent error)
        error_P = phi_plane_fb(1);
        % Integral Error (time average error with exp weight)
        exp_weights = exp(-(timeAgo_fb-timeAgo_fb(1))/tau_I);                
        error_I = sum(phi_plane_fb.*exp_weights)/sum(exp_weights);  
        % Total Error
        error_T = error_P*gain_P+error_I*gain_I;        
        % Frequency Shift
        dfreq = kappa*error_T;          

        % Limit total frequency shift
        if abs(dfreq)>df_max;dfreq=df_max*sign(dfreq);end

        % Find new frequency
        freq_previous = freqs_fb(1);
        freq_new = freq_previous+dfreq;  

        % Plot it
        pFreq_next=plot(0,freq_new,'o-','markerfacecolor',co(2,:),'markeredgecolor',co(2,:)*.5,...
         'linewidth',1,'markersize',8,'parent',ax1);

        % Save this frequency to file
        f_offset=freq_new;
        save(fullfile(mainGUI_Directory,'f_offset.mat'),'f_offset');
            s3 = 'next fb on';
        
         % Allow exiting of PID if small phase error
        if abs(error_P)<0.1 && abs(dfreq)<10
            doExitPID=1;
        end
       

    else
        % Load the saved f_offset.mat since that will be next
        d = load(fullfile(mainGUI_Directory,'f_offset.mat'));
        f_offset = d.f_offset;

        % Plot it
        pFreq_next=plot(0,f_offset,'o-','markerfacecolor',co(3,:),'markeredgecolor',co(3,:)*.5,...
            'linewidth',1,'markersize',8,'parent',ax1);
        s3 = 'next fb off';
    end    
     legend([pFreq_FB pFreq_BAD pFreq_next],{'feedback','ignore',s3},...
        'location','best');


catch ME
            
end
end


