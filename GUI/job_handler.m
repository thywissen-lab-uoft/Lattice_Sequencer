classdef job_handler < handle
    %SEQUENCER_JOB Summary of this class goes here
    %   Detailed explanation goes here
    
    properties        
        CurrentJob
        SequencerJobs
        lh
    end    
    events
       BatchComplete
    end
    
    methods
        function obj = job_handler()           
            obj.SequencerJobs={};
        end   
        
        function addJob(obj,job)
            obj.SequencerJobs{end+1} = job;
        end
        
        function clearJobs(obj)
            for kk=1:length(obj.SequencerJobs)
               delete(obj.SequencerJobs{kk}); 
            end
            obj.SequencerJobs={};
        end
        
        function start(obj)      
            % Find the first non complete job
           for kk=1:length(obj.SequencerJobs)
               if ~obj.SequencerJobs{kk}.isComplete
                 obj.CurrentJob = obj.SequencerJobs{kk};
                 obj.CurrentJob.start;
                  obj.lh=listener(obj.CurrentJob,...
                      'JobComplete',@(src, evt) obj.CurrentJobComplete);
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
        end                
        
        function delete(obj)
            % delete any listeners
            obj.clearJobs;
            
        end
    end
end

