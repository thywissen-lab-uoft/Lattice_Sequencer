function var_new = stripe_feedback

var_new = NaN;
global seqdata

try


if ~isfield(seqdata,'IxonGUIAnalayisHistoryDirectory') || ~exist(seqdata.IxonGUIAnalayisHistoryDirectory,'dir')
    warning('No feedback directory to run on');
    return;    
end

N = 10;

varName = 'qgm_plane_tilt_dIz';

% Get most recent data
old_data = getRecentGuiData(N);
            
timeNow = datenum(now);
       
ind = 1;

% Set point of phase
phiSet = 0.3 * (2*pi);

timeVec = [];
varVec = [];

thetaVec = [];
thetaErrVec = [];

LVec = [];
LErrVec = [];

phiVec = [];
phiErrVec = [];

BVec = [];
BErrVec = [];

for n = 1:length(old_data)
    if ~isfield(old_data{n},'StripeFit')
        continue
    end
    
    timeVec(end+1) = datenum(old_data{n}.Date);
    varVec(end+1) = old_data{n}.Params.(varName);
    thetaVec(end+1) = old_data{n}.StripeFit(ind).theta;
    thetaErrVec(end+1) = old_data{n}.StripeFit(ind).theta_err;
    LVec(end+1) = old_data{n}.StripeFit(ind).L;
    LErrVec(end+1) = old_data{n}.StripeFit(ind).L_err;
    phiVec(end+1) = old_data{n}.StripeFit(ind).phi;
    phiErrVec(end+1) = old_data{n}.StripeFit(ind).phi_err;
    BVec(end+1) = old_data{n}.StripeFit(ind).B;
    BErrVec(end+1) = old_data{n}.StripeFit(ind).B_err;
end

% Convert time of acquisition into time ago in seconds.
dTVec = (timeNow - timeVec)*24*60*60;

% Convert measured stripe phases to be within +- pi of phiSet
phiVec = (phiVec/(2*pi)-round((phiVec-phiSet)/(2*pi)))*2*pi;

% Convert measured phases into stripe error [-.5,.5]
stripe_error = (phiVec - phiSet)/(2*pi);

var_old = varVec(1);
         
               
% Modulus math to calculate -pi,pi phase error from phiset
isGood = ones(length(stripe_error),1);            
theta_bounds = [88.5 89.5];
L_bounds = [69 73];               
minB = 0.4;
tL = 1800;
for n=1:length(stripe_error)
    if abs(stripe_error(n))>0.4;isGood(n)=0;end
    if phiErrVec(n)>0.35;isGood(n)=0;end
    if abs(thetaErrVec(n))>0.5;isGood(n)=0;end
    if (thetaVec(n)<theta_bounds(1) || thetaVec(n)>theta_bounds(2));isGood(n)=0;end
    if abs(LErrVec(n))>0.6;isGood(n)=0;end
    if (LVec(n)<L_bounds(1) || LVec(n)>L_bounds(2));isGood(n)=0;end
    if (BVec(n)<minB);isGood(n)=0;end    
    if (dTVec(n)>tL); isGood(n) = 0;end
end        
        
isGood=logical(isGood);

 




% Coefficients
kappa = 1e-3/0.14;
G = 0.7;
beta = 0.25;
               
err_avg = mean(stripe_error(isGood));
err_now = stripe_error(1);
err_eff = err_now*(1-beta) + err_avg*beta;

var_new = var_old - kappa*G*err_eff;
var_new = round(var_new,6);     

% If the most recent data is not good, we have no P coefficient, so give up
if ~isGood(1)
    var_new = var_old;
end

% If too many bad shots, we no I coefficient, so give up
if sum(isGood)<5
   var_new = var_old;
   
end
doDebug = 1;
if doDebug
    hF = figure(1102); 
    hF.Color='w';
    clf
    co=get(gca,'colororder');
    
    subplot(3,2,[1 2])
    errorbar(dTVec(isGood),stripe_error(isGood),phiErrVec(isGood)/(2*pi),'o','linewidth',2,...
        'markersize',8,'markerfacecolor',co(1,:),'color',co(1,:)*.5);
    hold on
    errorbar(dTVec(~isGood),stripe_error(~isGood),phiErrVec(~isGood)/(2*pi),'o','linewidth',2,...
        'markersize',8,'markerfacecolor',co(2,:),'color',co(2,:)*.5);
    
    xlabel('time ago(s)');
    ylabel('stripe error (planes)');
    ylim([-.5 .5]);
    
    str = ['$\epsilon_0 = ' num2str(round(err_now,2)) ',~' '\langle \epsilon \rangle = ' ...
        num2str(round(err_avg,3)) ',~\epsilon_\mathrm{eff}=' num2str( round(err_eff,3)) '$'];
    str = [str ' $\beta=' num2str(beta) ',~G=' num2str(G) ',~N=' num2str(sum(isGood)) '$'];
    str = [str newline 'old : ' num2str(round(var_old,6)) ', new : ' num2str(round(var_new,6))];

    text(.01,.01,str,'units','normalized','fontsize',10,'interpreter','latex',...
        'verticalalignment','bottom');
    
    subplot(323)    
    errorbar(dTVec(isGood),phiVec(isGood),phiErrVec(isGood),'o','linewidth',2,...
        'markersize',8,'markerfacecolor',co(1,:),'color',co(1,:)*.5);
    hold on
    errorbar(dTVec(~isGood),phiVec(~isGood),phiErrVec(~isGood),'o','linewidth',2,...
        'markersize',8,'markerfacecolor',co(2,:),'color',co(2,:)*.5);       
    xlabel('time ago(s)');
    ylabel('phase \phi (rad)');
    ylim(phiSet+[-pi pi]);
    hold on
    plot(get(gca,'XLim'),[1 1]*phiSet,'k-');
     
    
    subplot(324)
    errorbar(dTVec(isGood),LVec(isGood),LErrVec(isGood),'o','linewidth',2,...
        'markersize',8,'markerfacecolor',co(1,:),'color',co(1,:)*.5);
    hold on
    errorbar(dTVec(~isGood),LVec(~isGood),LErrVec(~isGood),'o','linewidth',2,...
        'markersize',8,'markerfacecolor',co(2,:),'color',co(2,:)*.5);    
    xlabel('time ago(s)');
    ylabel('wavelength (px)');
    hold on
    plot(get(gca,'XLim'),[1 1]*L_bounds(1),'k-');
    plot(get(gca,'XLim'),[1 1]*L_bounds(2),'k-');

    subplot(325)
    errorbar(dTVec(isGood),thetaVec(isGood),thetaErrVec(isGood),'o','linewidth',2,...
        'markersize',8,'markerfacecolor',co(1,:),'color',co(1,:)*.5);
    hold on
    errorbar(dTVec(~isGood),thetaVec(~isGood),thetaErrVec(~isGood),'o','linewidth',2,...
        'markersize',8,'markerfacecolor',co(2,:),'color',co(2,:)*.5);       xlabel('time ago(s)');
    ylabel('angle (deg)');
    hold on
    plot(get(gca,'XLim'),[1 1]*theta_bounds(1),'k-');
    plot(get(gca,'XLim'),[1 1]*theta_bounds(2),'k-');
    
    subplot(326)
    plot(dTVec,varVec*1e3,'ko','markerfacecolor','k','markersize',8);  
    xlabel('time ago(s)');
    ylabel('current (mA)');
    
    ylim([min(varVec*1e3)-1 max(varVec*1e3)+1 ]);    
end   


catch ME
   ME.stack
end
            
end

