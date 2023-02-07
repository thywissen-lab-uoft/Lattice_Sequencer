classdef sequencer_watcher < handle
    properties
        AdwinStartTime
        WaitStartTime    
        RequestAdwinTime
        RequestWaitTime
        AdwinTimer
        WaitTimer
        WaitStr1
        WaitStr2
        AdwinStr1
        AdwinStr2   
        AdwinBar
        WaitBar  
        WaitTable
        WaitButtons
        StatusStr
        isRunning
        WaitMode
    end
    
    events
        CycleComplete
    end
    methods
        function this = sequencer_watcher(handles)
            this.AdwinTimer = timer('ExecutionMode','FixedSpacing', ...
                'Period',0.05,'name','AdwinTimer');
            this.WaitTimer = timer('ExecutionMode','FixedSpacing', ...
                'Period',0.05,'name','WaitTimer');
            this.isRunning = 0;
            this.WaitStr1 = handles.WaitStr1;
            this.WaitStr2 = handles.WaitStr2;            
            this.AdwinStr1 = handles.AdwinStr1;
            this.AdwinStr2 = handles.AdwinStr2;            
            this.AdwinBar = handles.AdwinBar;
            this.WaitBar = handles.WaitBar;            
            this.WaitTable=handles.WaitTable;
            this.WaitButtons=handles.WaitButtons;       
            this.AdwinTimer.TimerFcn = @this.updateAdwin;
            this.WaitTimer.TimerFcn = @this.updateWait;   
            this.WaitButtons.SelectionChangedFcn = @(src,evt) this.chWaitMode(evt.NewValue.UserData);
            this.WaitMode = this.WaitButtons.SelectedObject.UserData;
            this.StatusStr = handles.StatusStr;           
            this.WaitTable.CellEditCallback = @(src,evt) this.chWaitTime(src,evt);
        end
        
        function chWaitTime(this,src,evt)
             x = evt.NewData;
            
            if isnumeric(x) && x>=0 && ~isinf(x) && ~isnan(x)
                src.Data = x;
                this.RequestWaitTime = x;
                this.WaitStr2.String=[num2str(x,'%.2f') ' s'];  
            else 
                src.Data = evt.PreviousData;
            end
            
        end
        
        function chWaitMode(this,waitMode)     
            
            ch=this.WaitButtons.Children;
            
            for kk=1:length(ch)
               if ch(kk).UserData == waitMode
                   ch(kk).Value = 1;
               else
                   ch(kk).Value = 0;
               end
            end
            
            this.WaitMode = waitMode;            
            if waitMode == 0
               this.WaitTable.Enable = 'off';
               this.RequestWaitTime = 0;
            else
               this.WaitTable.Enable = 'on';
               this.RequestWaitTime = this.WaitTable.Data;
            end
        end
    
        function cycleComplete(this)
            disp('cycle complete');
            this.isRunning=0;
            this.AdwinStartTime=[];
            this.WaitStartTime=[];
            this.StatusStr.String = 'idle';
            this.StatusStr.ForegroundColor = [0 128 0]/255;
            this.notify('CycleComplete') 
        end
        
        function updateAdwin(this,src,evt)
            dT = (now - this.AdwinStartTime)*24*60*60;
            dT0 = this.RequestAdwinTime;
            if dT>=dT0
                stop(src);  
                this.AdwinBar.XData = [0 1 1 0];             
                this.AdwinStr1.String=[num2str(dT0,'%.2f') ' s'];
                this.AdwinStr2.String=[num2str(dT0,'%.2f') ' s']; 
                if this.RequestWaitTime>0
                    this.WaitStartTime = now;                
                    this.StatusStr.String = 'waiting ...';
                    this.StatusStr.ForegroundColor = 'k';
                    start(this.WaitTimer);
                else
                    this.cycleComplete;
                end
            else
                this.AdwinBar.XData = [0 1 1 0]*dT/dT0;             
                this.AdwinStr1.String=[num2str(dT,'%.2f') ' s'];
                this.AdwinStr2.String=[num2str(dT0,'%.2f') ' s']; 
            end    
        end
        
        function updateWait(this,src,evt)
            dT0 = this.RequestWaitTime;

            switch this.WaitMode
                case 0
                    dT = 0;
                    dT0=0;
                case 1
                    dT = (now - this.WaitStartTime)*24*60*60;
                case 2
                    dT = (now - this.AdwinStartTime)*24*60*60;
            end            
            
            if dT>=dT0
                stop(src);       
                this.WaitBar.XData = [0 1 1 0];         
                this.WaitStr1.String=[num2str(dT0,'%.2f') ' s'];
                this.WaitStr2.String=[num2str(dT0,'%.2f') ' s'];  
                this.cycleComplete;
            else
                this.WaitBar.XData = [0 1 1 0]*dT/dT0;             
                this.WaitStr1.String=[num2str(dT,'%.2f') ' s'];
                this.WaitStr2.String=[num2str(dT0,'%.2f') ' s'];  
            end              
        end
        
        function start(this)
            this.isRunning=1;
            this.AdwinStartTime = now;            
            this.WaitBar.XData = [0 0 0 0];         
            this.AdwinBar.XData = [0 0 0 0];         
            this.WaitStr1.String=[num2str(0,'%.2f') ' s'];
            this.WaitStr2.String=[num2str(this.RequestWaitTime,'%.2f') ' s'];
            this.AdwinStr1.String=[num2str(0,'%.2f') ' s'];
            this.AdwinStr2.String=[num2str(this.RequestAdwinTime,'%.2f') ' s'];   
            this.StatusStr.String = 'adwin is running';
            this.StatusStr.ForegroundColor = 'r';
            start(this.AdwinTimer); 
        end
        
        function delete(this)
            stop(this.AdwinTimer);
            stop(this.WaitTimer);
            pause(0.1);
            delete(this.AdwinTimer);
            delete(this.WaitTimer);
        end
    end
end