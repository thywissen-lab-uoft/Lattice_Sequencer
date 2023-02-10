classdef sequencer_job < handle
    %SEQUENCER_JOB Summary of this class goes here
    %   Detailed explanation goes here
    
    properties        
        SequenceFunctions  
        ScanCyclesRequested  
        ScanCyclesCompleted
        ScanCycle
        Options   
        JobName
        ImageSaveDirectory
        SequencerWatcher  
        continueRunning
        isComplete
        lh
        ExecutionDates
    end    
    events
        CycleComplete
        JobComplete
    end
    
    methods
        function obj = sequencer_job(SequenceFunctions,JobName,ScanCyclesRequested)           
            obj.SequencerWatcher = obj.findSequencerWatcher;
            obj.JobName = JobName;            
            obj.SequenceFunctions = SequenceFunctions;
            obj.ScanCyclesRequested = ScanCyclesRequested;
            obj.ScanCyclesCompleted = [];    
            obj.ScanCycle = [];
            obj.isComplete = false;
            obj.ExecutionDates = [];
        end    
        
        function JobCompleteFcn(obj)        
            obj.isComplete = true;
            obj.notify('JobComplete');
            for kk=1:length(obj.ExecutionDates)
               disp(datestr(obj.ExecutionDates(kk)) )
            end
        end
        
        function CycleCompleteFcn(obj)
            obj.notify('CycleComplete');
            delete(obj.lh);            
            obj.ScanCyclesCompleted(end+1) = obj.ScanCycle;            
            cycles_left = setdiff(obj.ScanCyclesRequested,...
                obj.ScanCyclesCompleted);
            
            if obj.continueRunning            
                if isempty(cycles_left) 
                    obj.JobCompleteFcn;
                else
                    obj.start;
                end
            else
                disp('job has stopped');
            end
        end
                
        function SequencerWatcher=findSequencerWatcher(obj)
            figs = get(groot,'Children');
            fig = [];
            for i = 1:length(figs)
                if isequal(figs(i).UserData,'sequencer_gui')        
                    fig = figs(i);
                end
            end             
            d=guidata(fig);            
            SequencerWatcher = d.SequencerWatcher;
        end
        
        function stop(obj)
           obj.continueRunning = 0;
           disp('stopping job');
        end
        
        function start(obj)
            obj.continueRunning = 1;
            cycles_left = setdiff(obj.ScanCyclesRequested,...
                obj.ScanCyclesCompleted);
            
            if isempty(cycles_left)
                error('no more runs to do');
            end                   
            opts=struct;
            opts.ScanCycle = cycles_left(1);          
            
            obj.ScanCycle = opts.ScanCycle;
            
            global seqdata
            seqdata.scancycle = obj.ScanCycle;
            
            t=runSequence(obj.SequenceFunctions,opts);              
            obj.ExecutionDates(end+1) = t;
            obj.lh=listener(obj.SequencerWatcher,'CycleComplete',@(src, evt) obj.CycleCompleteFcn);
        end
        
        function delete(this)
            % delete any listeners
        end
    end
end

