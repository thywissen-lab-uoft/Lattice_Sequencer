function feedback_stripe(data)

global mainGUI_Directory;
clear freqs
clear phi
clear stripes
src ='StripeCircular';
clear t
clear phi

%% Engage Feedback
% Engage Feedback?
doFeedback=1;

%% Feedback Settings

% (X,Y) pixel position to stabilize the phase
% CJF: Warning! Do not change this without careful thought. Changing this
% value will change what magnetic field the stripes stabilize to
nCenter = [276,256]; 

% Feedback bounds
Lambda_Lim = [66 77];   % [px] Wavelength bounds for stripes
Theta_Lim = [-2 4];     % [deg] Angle bounds for stripes
Time_max = 40;          % [min] maximum number of minutes to feedback on    
    
% Plane Separation [kHz/plane]
kappa = 80;

% Maximum Step Size [kHz]
df_max = 20;

% PID Gain Settings
% Because we know the feedback slope, the gains gain be calculated exactly.
% For this reason the sums of gains should equal to one.
gain_P = 0.5;          
gain_I = 1 - gain_P;
        
% Integral time constant [min.]
tau_I = 10;             


%%

try
    % Collect stripes, local phase, and freqs
    warning off
    for l=1:length(data)
        if isfield(data{l},src)
            if exist('stripes','var')
                stripes(end+1) = data{l}.(src)(1);
                freqs(end+1) = data{l}.Params.f_offset;
                t(end+1) = data{l}.Params.ExecutionDate;
                phi(end+1) = stripes(end).PhaseFunc(nCenter(1),nCenter(2));
            else
                stripes(1) = data{l}.(src)(1);
                freqs(1) = data{l}.Params.f_offset;
                t(1) = data{1}.Params.ExecutionDate;
                phi(1) = stripes(end).PhaseFunc(nCenter(1),nCenter(2));
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
        fig.WindowStyle='docked';
        fig.Color='w';
    end

    clf(fig);
    co=get(gca,'colororder');
    fig.NumberTitle='off';

    %% Plot Recent Stripe Data
    
    % Wavelength Plot
    ax1=subplot(5,2,1,'Parent',fig);
    plot(t,Lambda,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax1);
    ylabel(ax1,'Wavelength \lambda (sites)');

    % Angle Plot
    ax2=subplot(5,2,3,'Parent',fig);
    plot(t,Theta,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax2);
    ylabel(ax2,'Rot. Angle \theta (deg)');

    % Radius Plot
    ax3=subplot(5,2,5,'Parent',fig);
    plot(t,Radius,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax3);
    ylabel(ax3,'Radius R (sites)');       

    % Phase plot
    ax4=subplot(5,2,7,'Parent',fig);
    plot(t,phi_plane,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax4);
    ylabel(ax4,'Phase \phi (planes)');  

    % Frequencies
    ax5=subplot(5,2,9,'Parent',fig);
    plot(t,freqs,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax5);
    ylabel(ax5,'freq (kHz)');  

    % Get Time now
    tNow = datetime(now,'convertfrom','datenum');
    timeAgo = minutes(tNow-t);

    % Find data that is outside the limits
    bad_Lambda  = [Lambda<Lambda_Lim(1)]+[Lambda>Lambda_Lim(2)];% Bad Wavelength
    bad_Theta   = [Theta<Theta_Lim(1)]+[Theta>Theta_Lim(2)];    % Bad Angle
    bad_Time    = [timeAgo>Time_max];                           % Bad Time
    bad_inds    = bad_Lambda+bad_Theta+bad_Time;
    bad_inds    = logical(bad_inds);

    % Remove bad data points from feedback data
    freqs_fb = freqs;freqs_fb(bad_inds)=[];
    timeAgo_fb = timeAgo;timeAgo_fb(bad_inds)=[];
    phi_plane_fb = phi_plane;phi_plane_fb(bad_inds)=[];          

    % Save the bad data point values
    freqs_bad = freqs(bad_inds);
    timeAgo_bad = timeAgo(bad_inds);
    phi_plane_bad = phi_plane(bad_inds);    

    % Plot Frequency Feedback Values
    ax1=subplot(2,2,2,'Parent',fig);
    plot(timeAgo_fb,freqs_fb,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax1);
    ylabel(ax1,'freq (kHz)');
    xlabel(ax1,'time ago (min.)');
    hold(ax1,'on');
    plot(timeAgo_bad,freqs_bad,'rx',...
        'linewidth',1,'markersize',8,'parent',ax1);
    
    % Plot Phase Values
    ax2=subplot(2,2,4,'Parent',fig);
    plot(timeAgo_fb,phi_plane_fb,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax2);
    ylabel(ax2,'Phase \phi (planes)');
    xlabel(ax2,'time ago (min.)');
    % Dont plot bad phases
%     plot(timeAgo_bad,phi_plane_bad,'rx',...
%         'linewidth',1,'markersize',8,'parent',ax2);

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
        plot(0,freq_new,'o-','markerfacecolor',co(2,:),'markeredgecolor',co(2,:)*.5,...
         'linewidth',1,'markersize',8,'parent',ax1);

        % Save this frequency to file
        f_offset=freq_new;
        save(fullfile(mainGUI_Directory,'f_offset.mat'),'f_offset');
    else
        % Load the saved f_offset.mat since that will be next
        d = load(fullfile(mainGUI_Directory,'f_offset.mat'));
        f_offset = d.f_offset;

        % Plot it
        plot(0,f_offset,'o-','markerfacecolor',co(3,:),'markeredgecolor',co(3,:)*.5,...
            'linewidth',1,'markersize',8,'parent',ax1);
    end


catch ME
%             keyboard
end
end


