classdef sequencer_watcher < handle
% Author : CJ Fujiwara
% 
% This class hanldes the mainGUI handles such as the status of the adiwin,
% the wait time, any sequences being run, and any events.
properties
    AdwinGraphicTimer       % timer     : updates the AdwinTimer
    AdwinStartTime          % datetime  : time at which adwin began
    AdwinTime               % numeric   : durationn of adwin cycle
    AdwinStr1               % graphic   : string for current adwin time
    AdwinStr2               % graphic   : string for ending adwin time
    AdwinBar                % graphic   : status bar

    WaitEnable              % boolean  : use the waittimer
    WaitGraphicTimer        % timer    : updates the WaitTimer
    WaitStartTime           % datetime : Time at which waiting began
    WaitTime                % numeric  : Time to wait between executions
    WaitStr1                % graphic  : string for current wait time
    WaitStr2                % graphic  : string for ending  wait time
    WaitBar                 % graphic  : status bar

    StatusStr
    isRunning
    % SequenceText
end

events
    CycleComplete
    AdwinComplete    
end

methods

% Class constructor
function this = sequencer_watcher(handles)
    % Initialize Adwin Timer Objects
    this.AdwinGraphicTimer = timer(...
        'ExecutionMode','FixedSpacing', ...
        'Period',0.05,'name','AdwinGraphicTimer',...
        'TimerFcn',@this.updateAdwin);
    this.AdwinStr1          = handles.AdwinStr1;
    this.AdwinStr2          = handles.AdwinStr2;            
    this.AdwinBar           = handles.AdwinBar;

    % Initialize Wait Timer Objects
    this.WaitEnable         = true;
    this.WaitGraphicTimer = timer(...
        'ExecutionMode','FixedSpacing', ...
        'Period',0.05,'name','WaitGraphicTimer',...
        'TimerFcn',@this.WaitTimerFcn);    
    this.WaitTime           = 5;
    this.WaitStr1           = handles.WaitStr1;
    this.WaitStr2           = handles.WaitStr2;    
    this.WaitBar            = handles.WaitBar;  

    this.isRunning          = 0; 
    this.StatusStr          = handles.StatusStr;           
    % this.SequenceText       = handles.SequenceText;
end

function updateWait(this,WaitTime,WaitEnable)
    this.WaitEnable = WaitEnable;
    this.WaitTime = WaitTime;
    this.WaitStr2.String=[num2str(this.WaitTime,'%.2f') ' s'];  
end

function [AdwinTimerRunning,WaitTimerRunning] = getSequencerStatus(obj)
    AdwinTimerRunning = obj.AdwinGraphicTimer.Running;
    WaitTimerRunning = obj.WaitGraphicTimer.Running;
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
    dT0 = this.AdwinTime;
    if dT>=dT0
        stop(src);  
        this.AdwinBar.XData = [0 1 1 0];             
        this.AdwinStr1.String=[num2str(dT0,'%.2f') ' s'];
        this.AdwinStr2.String=[num2str(dT0,'%.2f') ' s']; 
        this.notify('AdwinComplete');
        if this.WaitTime>0
            this.WaitStartTime = datetime;                
            this.StatusStr.String = 'waiting ...';
            this.StatusStr.ForegroundColor = 'k';
            start(this.WaitGraphicTimer);
        else
            this.cycleComplete();
        end
    else
        this.AdwinBar.XData = [0 1 1 0]*dT/dT0;             
        this.AdwinStr1.String=[num2str(dT,'%.2f') ' s'];
        this.AdwinStr2.String=[num2str(dT0,'%.2f') ' s']; 
    end    
end

% callback for wait timer; updates graphics
function WaitTimerFcn(this,src,evt)
    dT = seconds(datetime-this.WaitStartTime);      
    if dT>=this.WaitTime || ~this.WaitEnable
        stop(src);       
        this.WaitBar.XData = [0 1 1 0];         
        this.WaitStr1.String=[num2str(this.WaitTime,'%.2f') ' s'];
        this.WaitStr2.String=[num2str(this.WaitTime,'%.2f') ' s'];  
        this.cycleComplete;
    else
        this.WaitBar.XData = [0 1 1 0]*dT/this.WaitTime;             
        this.WaitStr1.String=[num2str(dT,'%.2f') ' s'];
        this.WaitStr2.String=[num2str(this.WaitTime,'%.2f') ' s'];  
    end              
end

% start timers
function start(this)
    this.isRunning=1;
    this.AdwinStartTime = now;            
    this.WaitBar.XData = [0 0 0 0];         
    this.AdwinBar.XData = [0 0 0 0];         
    this.WaitStr1.String=[num2str(0,'%.2f') ' s'];
    this.WaitStr2.String=[num2str(this.WaitTime,'%.2f') ' s'];
    this.AdwinStr1.String=[num2str(0,'%.2f') ' s'];
    this.AdwinStr2.String=[num2str(this.AdwinTime,'%.2f') ' s'];   
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