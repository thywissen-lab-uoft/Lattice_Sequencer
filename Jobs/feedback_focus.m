function feedback_focus(data)
%FEEDBACK_FOCUS Summary of this function goes here
        doFeedback=1;
        src ='KFocusing';
        ControlVariable = 'piezo_offset';
        clear focus
        try
            % Collect Focus Data
            warning off
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
                        Vpiezo(end+1) = P.objective_piezo;
                    else
                        focus(1) = data{l}.(src)(1);
                        X(1) = P.(ControlVariable);
                        t(1) = P.ExecutionDate;
                        Vpiezo(1) = P.objective_piezo;
                    end
                end
            end   
            warning on
            t = datetime(t,'convertfrom','datenum');
            tNow = datetime(now,'convertfrom','datenum');

            timeAgo = minutes(tNow-t);

            maxScore=zeros(length(focus),1);
            for mm=1:length(focus)
                maxScore(mm)=max([focus(mm).Scores]);                
            end
            
            % Piezo Focus Posistion
            V_best = [focus.FocusCenter];
            
            V_best_offset = V_best-Vpiezo;
            
            % Total Piezo Voltage
            Vtot = Vpiezo + X;
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
            co=get(gca,'colororder');

            ax1=subplot(3,2,1,'Parent',fig);
            plot(t,V_best,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
                'linewidth',1,'markersize',8,'parent',ax1);
            ylabel(ax1,'best piezo (V)');

            ax2=subplot(3,2,3,'Parent',fig);
            plot(t,X,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
                'linewidth',1,'markersize',8,'parent',ax2);
            ylabel(ax2,'piezo offset (V)');     
            
            
            ax3=subplot(3,2,5,'Parent',fig);
            plot(t,maxScore,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
                'linewidth',1,'markersize',8,'parent',ax3);
            ylabel(ax3,'peak score (arb.)');
            
            
%             
            ax4=subplot(2,2,2,'Parent',fig);
            plot(timeAgo,X,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
                'linewidth',1,'markersize',8,'parent',ax4);
            ylabel(ax4,'piezo offset (V)');
            xlabel(ax4,'time ago (min.)');
            hold(ax4,'on');

            ax5=subplot(2,2,4,'Parent',fig);
            plot(timeAgo,V_best_offset-X,'o-','markerfacecolor',co(1,:),'markeredgecolor',co(1,:)*.5,...
                'linewidth',1,'markersize',8,'parent',ax5);
            ylabel(ax5,'best piezo - piezo');
            xlabel(ax5,'time ago (min.)');


            if doFeedback
                errorAll = V_best_offset(1)-X(1);
                
                error_P = errorAll(1);
                gain_P = 0.5;
                                
                % Integral Error
                tau_I = 10; % tau in minutes                
                exp_weights = exp(-(timeAgo-timeAgo(1))/tau_I);                
                error_I = sum(errorAll.*exp_weights)/sum(exp_weights);                
                gain_I = 1-gain_P;                
                error_T = error_P*gain_P+error_I*gain_I;                
                kappa = 1;
                
                d_piezo_offset = 1*kappa*error_T;
                if abs(d_piezo_offset)>0.05
                   d_piezo_offset = 0.05*sign(d_piezo_offset); 
                end
                
                old_piezo_offset = X(1);                
                piezo_offset=round(old_piezo_offset+d_piezo_offset,2);
                
                %Prevents microscope from moving too far
                if (getVarOrdered('objective_piezo') + piezo_offset) >= 10 || ...
                        (getVarOrdered('objective_piezo') + piezo_offset) <= 0
                    piezo_offset = old_piezo_offset;
                end
                                
                plot(0,piezo_offset,'o-','markerfacecolor',co(2,:),'markeredgecolor',co(2,:)*.5,...
                 'linewidth',1,'markersize',8,'parent',ax4);
                save('piezo_offset.mat','piezo_offset');                             
            end

            
        catch ME
%             keyboard
        end

end

