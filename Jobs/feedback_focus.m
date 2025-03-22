function feedback_focus(data,doFeedback)
global mainGUI_Directory

%% Settings
if nargin ==1
   doFeedback = 0; 
end
src ='Focus';
ControlVariable = 'piezo_offset';
clear focus

%% PID Gain Settings
% Because we know the feedback slope, the gains gain be calculated exactly.
% For this reason the sums of gains should equal to one.
gain_P = 0.5;          
gain_I = 1 - gain_P;

kappa = 0.1;
        
% Integral time constant [min.]
tau_I = 5;            

% T
Time_max = 10;

% Max Step
dV_max = 0.05;

% Minutes to plot things
tMinLim=60;

% String Descriptor of PID
strPID = ['$(G_p,G_I,\tau,\kappa) : (' num2str(gain_P) ',' ...
    num2str(gain_I) ',' num2str(tau_I) '~\mathrm{min.},' ...
    num2str(kappa) '~\mathrm{kHz/plane})$'];

%% Collect Data
try
    for l=1:length(data)                
        if isfield(data{l},src)
            P = data{l}.Params;                    
            if ~isfield(P,ControlVariable)
                P.(ControlVariable)=NaN;
            end                    
            if exist('focus','var')
                focus(end+1) = data{l}.(src)(1);
                X(end+1) = P.(ControlVariable);
                t(end+1) = P.ExecutionDate;
                
%               Vpiezo(end+1) = P.objective_piezo;
%               Vpiezo0(end+1)=P.objective_piezo_center;
            else
                focus(1) = data{l}.(src)(1);
                X(1) = P.(ControlVariable);
                t(1) = P.ExecutionDate;

%               Vpiezo(1) = P.objective_piezo;
%               Vpiezo0(1)=P.objective_piezo_center;
            end
        end
    end   
%% Process Data
    %warning on
    t = datetime(t,'convertfrom','datenum');
    tNow = datetime(now,'convertfrom','datenum');

    timeAgo = minutes(tNow-t);
    
    for jj=1:length(focus)
        s1(jj) = focus(jj).Scores(1);
        s2(jj) = focus(jj).Scores(2);
        s3(jj) = focus(jj).Scores(3);
        c1(jj) = focus(jj).Counts(1);
        c2(jj) = focus(jj).Counts(2);
        c3(jj) = focus(jj).Counts(3);
        v1(jj) = focus(jj).Piezos(1);
        v2(jj) = focus(jj).Piezos(2);
        v3(jj) = focus(jj).Piezos(3);
        
        pp = polyfit(focus(jj).Piezos,focus(jj).Scores,2);
        
        best_v(jj) = -pp(2)/(2*pp(1));
        curve_v_sign(jj) = sign(pp(2));
    end    
    amp_v = abs((v2-v3)/2);
    center_v = (v2+v3)/2;
    
    
    best_dv = best_v-center_v;
    
   inds_H=[best_dv>amp_v];
   inds_L=[best_dv<-amp_v];
   
   best_dv(inds_H)=amp_v(inds_H);
   best_dv(inds_L)=-amp_v(inds_L);
   
    S = s1+s2+s3;       
    C = c1+c2+c3;   


    P=[focus.Params];
    piezo_offset_all = [P.piezo_offset];
    plane_shift = [P.qgm_planeShift_N];
    objective_piezo         = [P.objective_piezo];
    
    best_offset = best_dv+piezo_offset_all;
    

%% Caclcultate PID Stuff

%% Display Details

%% Initialize Figure
     % Find Figure... or make it
    FigName = 'Focus';
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

    clf(fig);
    fig.NumberTitle='off';
        
%% Initialize Tabs
    hpTG = uitabgroup(fig,'units','normalized','position',[0 0 1 1]);
    tSummary = uitab(hpTG,'Title','summary','backgroundcolor','w');
    tDetails = uitab(hpTG,'Title','details','backgroundcolor','w');

    %% Plot Recent Piezo Data
    % Box Counts
    % Last Few images? --> is that too much data?
    
    co=get(gca,'colororder');
% 
    ax1=subplot(2,3,1,'Parent',tDetails);
    plot(t,c1,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax1);
    hold on
    plot(t,c2,'o-','markerfacecolor',co(2,:),'markeredgecolor',co(2,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax1);
    plot(t,c3,'o-','markerfacecolor',co(3,:),'markeredgecolor',co(3,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax1);
    ylabel(ax1,'box counts');
% 
    ax2=subplot(2,3,2,'Parent',tDetails);
    plot(t,s1,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax2);
    hold on
    plot(t,s2,'o-','markerfacecolor',co(2,:),'markeredgecolor',co(2,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax2);
    plot(t,s3,'o-','markerfacecolor',co(3,:),'markeredgecolor',co(3,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax2);
    ylabel(ax2,'scores');
    
    ax3=subplot(2,3,3,'Parent',tDetails);
    plot(t,s1./S,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax3);
    hold on
    plot(t,s2./S,'o-','markerfacecolor',co(2,:),'markeredgecolor',co(2,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax3);
    plot(t,s3./S,'o-','markerfacecolor',co(3,:),'markeredgecolor',co(3,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax3);
    ylabel(ax3,'normalized scores');
    
    ax4 = subplot(2,3,4,'parent',tDetails);
    plot(t,piezo_offset_all,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax4);
    ylabel(ax4,'piezo offset (V)');
    
    ax5 = subplot(2,3,5,'parent',tDetails);
    plot(t,objective_piezo,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax5);
    ylabel(ax5,'piezo offset (V)');
    
        
    ax6 = subplot(2,3,6,'parent',tDetails);
    plot(t,plane_shift,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax6);
    ylabel(ax6,'plane');
    
    %% Convert
    timeAgo = minutes(tNow-t);  
    

    bad_Time    = [timeAgo>Time_max];       % Bad Time
    bad_Curvature = [curve_v_sign==-1];     % Bad Curvature
    bad_PlaneShift = [plane_shift~=plane_shift(1)];             % Only consider first plane shift
    bad_Objective = [objective_piezo~=objective_piezo(1)];             % Only consider first plane shift

    
    bad_inds    = bad_Time+bad_Curvature+bad_PlaneShift+bad_Objective;
    bad_inds    = logical(bad_inds);        
     
    % Remove bad data points from feedback data
    timeAgo_fb = timeAgo;timeAgo_fb(bad_inds)=[];
    piezo_offset_fb = piezo_offset_all; piezo_offset_fb(bad_inds)=[];
    best_offset_fb = best_offset; best_offset_fb(bad_inds)=[];

    % Save the bad data point values
    piezo_offset_bad = piezo_offset_all(bad_inds);
    timeAgo_bad = timeAgo(bad_inds);
    best_offset_bad = best_offset(bad_inds);
    
    %% Plot Stuff 
    % Plot Piezo Offset values
    ax1=subplot(1,2,1,'Parent',tSummary);
    pPiezo_FB=plot(timeAgo_fb,piezo_offset_fb,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax1);
    ylabel(ax1,'piezo offset (V)');
    xlabel(ax1,'time ago (min.)');
    hold(ax1,'on');
    pPiezo_BAD=plot(timeAgo_bad,piezo_offset_bad,'rx',...
        'linewidth',1,'markersize',8,'parent',ax1);
    tStr = ['Now : ' datestr(datetime(now,'convertfrom','datenum'))];
    text(.01,.99,tStr,'units','normalized','parent',ax1,...
        'verticalalignment','top','horizontalalignment','left');
    title('frequency offset (control)','parent',ax1);
    set(ax1,'XLim',[0 tMinLim]);
    
  % Plot Best Piezo Offset Value
    ax2=subplot(1,2,2,'Parent',tSummary);
    pBest_FB=plot(timeAgo_fb,best_offset_fb,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
        'linewidth',1,'markersize',8,'parent',ax2);
    ylabel(ax2,'best piezo offset (V)');
    xlabel(ax2,'time ago (min.)');
    hold(ax2,'on');
    pBest_BAD=plot(timeAgo_bad,best_offset_bad,'rx',...
        'linewidth',1,'markersize',8,'parent',ax2);
    tStr = ['Now : ' datestr(datetime(now,'convertfrom','datenum'))];
    text(.01,.99,tStr,'units','normalized','parent',ax2,...
        'verticalalignment','top','horizontalalignment','left');
    title('best piezo offset (control)','parent',ax2);
    set(ax2,'XLim',[0 tMinLim]);
    
    %% Apply Feedback
% 
        if doFeedback&& ~bad_inds(1) 
            piezo_offset_now = piezo_offset_fb(1);
            piezo_offset_best = best_offset_fb(1);
            
            if abs(piezo_offset_best-piezo_offset_now)>0.02 && abs(piezo_offset_best-piezo_offset_now)<0.1
               piezo_offset = piezo_offset_best; 
               plot(0,piezo_offset,'o-','markerfacecolor',co(2,:),'markeredgecolor',co(2,:)*.5,...
                    'linewidth',1,'markersize',8,'parent',ax2);
                save(fullfile(mainGUI_Directory,'piezo_offset.mat'),'piezo_offset');     
            else
               piezo_offset = piezo_offset_now; 
               plot(0,piezo_offset,'o-','markerfacecolor',co(3,:),'markeredgecolor',co(3,:)*.5,...
                    'linewidth',1,'markersize',8,'parent',ax2);
            end                                    
        end


catch ME
    warning(getReport(ME,'extended','hyperlinks','on'))
end

end

