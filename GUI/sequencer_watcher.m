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
            
            this.WaitStr1 = handles.WaitStr1;
            this.WaitStr2 = handles.WaitStr2;
            
            this.AdwinStr1 = handles.AdwinStr1;
            this.AdwinStr2 = handles.AdwinStr2;
            
            this.AdwinBar = handles.AdwinBar;
            this.WaitBar = handles.WaitBar;

            
            this.AdwinTimer.TimerFcn = @this.updateAdwin;
            this.WaitTimer.TimerFcn = @this.updateWait;            
        end
        
        function cycleComplete(this)
            disp('cycle complete');
            this.notify('CycleComplete') 
            this.AdwinStartTime=[];
            this.WaitStartTime=[];
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
            dT = (now - this.WaitStartTime)*24*60*60;
            dT0 = this.RequestWaitTime;
            
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
           this.AdwinStartTime = now;
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