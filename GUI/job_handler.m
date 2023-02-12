classdef job_handler < handle
    % Author : CJ Fujiwara
    %
    % This can organizers and tracks all jobs which are run on the
    % sequencer.
    
    properties        
        CurrentJob
        SequencerJobs
        lh
        TextBox
    end    
    events
       BatchComplete
    end
    
    methods
        function obj = job_handler(gui_handle)           
            obj.SequencerJobs={};            
            d=guidata(gui_handle);          
            obj.TextBox = d.JobTable;
            obj.updateJobText;
        end   
        
        function updateJobText(obj)
            if isempty(obj.SequencerJobs)
               obj.TextBox.Data={};
            else
                for kk = 1:length(obj.SequencerJobs)
                    funcs=obj.SequencerJobs{kk}.SequenceFunctions;
                    mystr =[];
                    for ii = 1:length(funcs)
                        mystr = [mystr '@' func2str(funcs{ii}) ','];
                    end
                    mystr(end)=[];
                    
                    obj.TextBox.Data{kk,2} = obj.SequencerJobs{kk}.Status;
                    obj.TextBox.Data{kk,3} = [num2str(length(obj.SequencerJobs{kk}.ScanCyclesCompleted)) ...
                        '/' num2str(length(obj.SequencerJobs{kk}.ScanCyclesRequested))];
                    obj.TextBox.Data{kk,4} = obj.SequencerJobs{kk}.JobName;
                    obj.TextBox.Data{kk,5} = mystr;


                end
            end
        end
        
        function addJob(obj,job)
            obj.SequencerJobs{end+1} = job;
            obj.updateJobText;
        end
        
        function clearJobs(obj)
            for kk=1:length(obj.SequencerJobs)
               delete(obj.SequencerJobs{kk}); 
            end
            obj.SequencerJobs={};
            obj.updateJobText;
        end
        
        function start(obj)      
            % Find the first non complete job
           for kk=1:length(obj.SequencerJobs)
               if ~obj.SequencerJobs{kk}.isComplete
                 obj.CurrentJob = obj.SequencerJobs{kk};
                 obj.CurrentJob.start;
                  obj.lh=listener(obj.CurrentJob,...
                      'JobComplete',@(src, evt) obj.CurrentJobComplete);
                  obj.updateJobText;

                  return
               end
           end
                      
           
           warning('no more uncompleted jobs to run');
        end
        
        function CurrentJobComplete(obj)
            delete(obj.lh);   
            obj.CurrentJob = [];
            obj.start;
        end
        
        function stop(obj)
            if ~isempty(obj.CurrentJob)
               obj.CurrentJob.stop 
            end
            obj.updateJobText;

        end                
        
        function delete(obj)
            % delete any listeners
            obj.clearJobs;
            obj.updateJobText;
        end
    end
end

