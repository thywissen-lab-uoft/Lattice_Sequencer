function [Inew,Iold] = stripe_feedback

global seqdata

if ~isfield(seqdata,'IxonGUIAnalayisHistoryDirectory') || ~exist(seqdata.IxonGUIAnalayisHistoryDirectory,'dir')
    warning('No feedback directory to run on');
    return;    
end


               names = dir([seqdata.IxonGUIAnalayisHistoryDirectory filesep '*.mat']);
               names = {names.name};
               names = flip(sort(names)); % Sort by most recent               
               N = 10;               
               % Get the most recent runs
               names = [names(1:N)];               
               tnow = datenum(now);
                t=[];theta=[];L=[];phi=[];v=[];B=[];
               for n = 1:length(names) 
                  data = load(fullfile(seqdata.IxonGUIAnalayisHistoryDirectory,names{n}));
                  data=data.gui_saveData;                  
                  if isfield(data,'Stripe')
                      t(end+1) = datenum(data.Date);
                      v(end+1) = data.Params.qgm_plane_tilt_dIz;                      
                      theta(end+1,1) = data.Stripe.theta;
                      theta(end,2) = data.Stripe.theta_err;                      
                      L(end+1,1) = data.Stripe.L;                      
                      L(end,2) = data.Stripe.L_err;                      
                      phi(end+1,1) = data.Stripe.phi; 
                      phi(end,2) = data.Stripe.phi_err;  
                      B(end+1,1) = data.Stripe.B; 
                      B(end,2) = data.Stripe.B_err;    
                  end
               end               
                dT = (tnow - t)*24*60*60;
                phiset = 0.9 * (2*pi);

               doDebug = 1;
               if doDebug
                    figure(1102); 
                    subplot(221)
                    errorbar(dT,phi(:,1),phi(:,2),'o');
                    xlabel('time ago(s)');
                    ylabel('phase (rad)');
                    ylim(phiset+[-pi pi]);
                    subplot(222)
                    errorbar(dT,L(:,1),L(:,2),'o');
                    xlabel('time ago(s)');
                    ylabel('wavelength (px)');
                    subplot(223)
                    errorbar(dT,theta(:,1),theta(:,2),'o');   
                    xlabel('time ago(s)');
                    ylabel('angle (deg)');
                    subplot(224)
                    plot(dT,v,'o');  
                    xlabel('time ago(s)');
                    ylabel('current (A)');
               end             
               
               % Modulus math to calculate -pi,pi phase error from phiset
               phi_err = ((phi(:,1)-phiset)/(2*pi)-round((phi(:,1)-phiset)/(2*pi)))*2*pi;               
               isGood = ones(size(phi,1),1);               
               theta_bounds = [88.5 89.5];
               L_bounds = [70 73];               
               minB = 0.45;
               
               for kk=1:size(phi,1)                   
                   % Ignore large phi data
                   if phi(kk,2)>.35;isGood(kk) = 0;end                   
                   % Ignore phi error close to +-pi/2
                   if abs(phi_err(kk))>(.45*pi);isGood(kk) = 0;end  
                   % Ignore larger theta uncertainty that 0.5 deg
                   if abs(theta(kk,2))>.5;isGood(kk) = 0;end   
                  % Ignore theta outside of boundaries
                   if theta(kk,1)<theta_bounds(1) || ...
                           theta(kk,1)>theta_bounds(2)
                       isGood(kk) = 0;                       
                   end                                                          
                   % Ignore L uncertainty than 0.6 px
                   if abs(L(kk,2))>.6;isGood(kk) = 0;end   
                  % Ignore L outside of boundaries
                   if abs(L(kk,1))<L_bounds(1) || ...
                           abs(L(kk,1))>L_bounds(2)
                       isGood(kk) = 0;                       
                   end                     
                   if B(kk,1)<minB; isGood(kk) = 0; end  
               end                     
                t_memory = 1800;
               isGood = isGood.*[dT<t_memory]';               
               isGood=logical(isGood);
               
               % Remove fits with suspect noise
                phi(~isGood,:)=[];
                t(~isGood) =[];
                theta(~isGood,:)=[];
                L(~isGood,:) = [];
                phi_err(~isGood) = [] ;
                v(~isGood) = [];
                B(~isGood,:)= [];
                dT(~isGood) = [];
                 
                 if length(dT)>5
                     beta = 0.9;                     
                     err_avg = mean(phi_err)/(2*pi);
                     err_this = phi_err(end)/(2*pi);                     
                     err_eff = err_this*(1-beta)+err_avg*beta;                     
                     dIz_old = v(end);                         
                     kappa = 1e-3/0.14;                     
                     dIz_new = dIz_old - kappa*err_eff;                     
                     defVar('qgm_plane_tilt_dIz',dIz_new,'A');
                     
                     disp(err_avg);
                     disp(err_eff);
                     disp(dIz_new);
                 end  
            
end

