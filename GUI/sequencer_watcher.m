classdef sequencer_watcher < handle
% Author : CJ Fujiwara
% 
% This class hanldes the mainGUI handles such as the status of the adiwin,
% the wait time, any sequences being run, and any events.
properties
    AdwinStartTime
    WaitStartTime    
    RequestAdwinTime
    RequestWaitTime
    AdwinGraphicTimer       % Updates the AdwinTimer bar
    WaitGraphicTimer        % Updates the WaitTimer
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
    SequenceText
end

events
    CycleComplete
end

methods

% Class constructor
function this = sequencer_watcher(handles)
    this.AdwinGraphicTimer = timer(...
        'ExecutionMode','FixedSpacing', ...
        'Period',0.05,'name','AdwinGraphicTimer',...
        'TimerFcn',@this.updateAdwin);
    this.WaitGraphicTimer = timer(...
        'ExecutionMode','FixedSpacing', ...
        'Period',0.05,'name','WaitGraphiTimer',...
        'TimerFcn',@this.updateWait);
    this.isRunning          = 0;
    this.WaitStr1           = handles.WaitStr1;
    this.WaitStr2           = handles.WaitStr2;            
    this.AdwinStr1          = handles.AdwinStr1;
    this.AdwinStr2          = handles.AdwinStr2;            
    this.AdwinBar           = handles.AdwinBar;
    this.WaitBar            = handles.WaitBar;            
    this.WaitTable          = handles.WaitTable;
    this.WaitButtons        = handles.WaitButtons;       

    % Wait graphics to be changed
    this.WaitMode           = this.WaitButtons.Value;
    this.WaitButtons.Callback = @this.chWaitMode;
    this.WaitTable.CellEditCallback = @(src,evt) this.chWaitTime(src,evt);
    this.RequestWaitTime    = 30;


    this.StatusStr          = handles.StatusStr;           
    this.SequenceText       = handles.SequenceText;
end

% function that updates the sequence file text
function updateSequenceFileText(obj,SequenceFunctions)
    mystr =[];
    for kk = 1:length(SequenceFunctions)
        mystr = [mystr '@' func2str(SequenceFunctions{kk}) ','];
    end
    mystr(end)=[];
    obj.SequenceText.String=mystr;
end
% 
% % Change the wait time
% function chWaitTime(this,WaitMode,JobWaitTime)
%     this.WaitMode = WaitMode;   % Wait time mode
% 
%     switch this.WaitMode
%         case 0
%             this.WaitTime = 0;
%         case 1
%             this.WaitTime = 
%         case 2
%     end
% 
% 
% 
% 
%     this.WaitTime = WaitTime;
% end

% callback for wait time table edit
function chWaitTime(this,src,evt)
  
    % x=evt.Source.Value;
    x= evt.NewData;

    if isnumeric(x) && x>=0 && ~isinf(x) && ~isnan(x)
        src.Data = x;
        this.RequestWaitTime = x;
        this.WaitStr2.String=[num2str(x,'%.2f') ' s'];  
    else 
        src.Data = evt.PreviousData;
    end
end

% callback for wait mode change
function chWaitMode(this,src,evt)   
    WaitMode = evt.Source.Value;

    this.WaitMode = WaitMode;            
    if WaitMode == 1
       this.WaitTable.Enable = 'off';
       this.RequestWaitTime = 0;
    else
       this.WaitTable.Enable = 'on';
       this.RequestWaitTime = this.WaitTable.Data;
    end
end

% function upon cyclecomplete, mainly graphical, notifies the event
function cycleComplete(this)
    this.isRunning=0;
    this.AdwinStartTime=[];
    this.WaitStartTime=[];
    this.StatusStr.String = 'idle';
    this.StatusStr.ForegroundColor = [0 128 0]/255;
    this.notify('CycleComplete') 
end

% callback for adwin timer; updates graphics and starts wait timer
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
            start(this.WaitGraphicTimer);
        else
            this.cycleComplete;
        end
    else
        this.AdwinBar.XData = [0 1 1 0]*dT/dT0;             
        this.AdwinStr1.String=[num2str(dT,'%.2f') ' s'];
        this.AdwinStr2.String=[num2str(dT0,'%.2f') ' s']; 
    end    
end

% callback for wait timer; updates graphics
function updateWait(this,src,evt)
    dT0 = this.RequestWaitTime;
    switch this.WaitMode
        case 1
            dT = 0;
            dT0=0;
        case 2
            dT = (now - this.WaitStartTime)*24*60*60;
        case 3
            dT = (now - this.AdwinStartTime)*24*60*60;
        otherwise
            keyboard
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

% start timers
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
    start(this.AdwinGraphicTimer); 
end

% delete funcion
function delete(this)
    stop(this.AdwinGraphicTimer);
    stop(this.WaitGraphicTimer);
    pause(0.1);
    delete(this.AdwinGraphicTimer);
    delete(this.WaitGraphicTimer);
end
end
end