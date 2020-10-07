%------
%Author: David McKay
%Created: July 2009
%Summary: This is the callback function for running cycles
%------
%cycle_sequence(sequencefunc,waittime,targettime,startcycle,endcycle);
% Feb2015(ST): added a target cycle period "targettime" to ensure constant
% cycle lengths
function cycle_sequence_callback(obj,event,curcycle,endcycle,fhandle,waittime,targettime,newcycle)

global wait_timer;
global adwin_trigger_timer;
global seqdata;
global docycle;

%clean up the timers
CleanUpTimers();

if newcycle
    disp('i am run newcycle')
else
    disp('i am an old cycle')
end

%another function turned off the cycle
if docycle

    if newcycle
        disp(['Starting cycle ' num2str(curcycle) ' of function ' func2str(fhandle)]);
        
        start_new_sequence();
        
        seqdata.cycle = curcycle;
        seqdata.cyclecounter = seqdata.cyclecounter+1;
        if (seqdata.doscan);
            seqdata.scancycle = seqdata.scancycle + 1;
            disp(sprintf('Scan is active; current scan count is %g.',seqdata.scancycle));
        end
        
        windows = get(0,'Children');
        lsfigure = windows(strcmpi(get(windows,'Name'),'Lattice Sequencer'));
        buildmon = findobj(lsfigure,'tag','buildmon');
        set(buildmon,'String','building');
        drawnow;
        
        buildtime = now;
        disp('Starting to process matlab code.')
        
        %This 'fhandle' is the sequence file that is defined in the text
        %box of the lattice sequencer GUI. When running the sequence
        % fhandle(0) = Load_MagTrap_sequence(0)
        fhandle(0); % processes the matlab files for sequence building; could disable a few things (like plotting) for this time
        
        %process and send to adwin
        calc_sequence(); % now knowing seqdata.seqtime
        load_sequence();
        buildtime = datevec(now-buildtime)*[0 0 0 3600 60 1]'; % in seconds
        
        disp(sprintf('Sequence time is %gs.', seqdata.sequencetime));
        
        disp(sprintf('Building and loading of sequence took %g seconds!',buildtime));
        set(buildmon,'String',sprintf('built and loaded (%gs)',buildtime));
        drawnow;

        if (seqdata.cyclecounter == 1)
            
            % this is the original call; remove/mute if statement to go back
            run_sequence({@cycle_sequence_callback,curcycle,endcycle,fhandle,waittime,targettime,0});
            
        else
            
            elapsed = datevec(now-seqdata.seqstart)*[0 0 0 3600 60 1]'; %remaining time till new cycle in seconds
            remaining = round(max(0,targettime*seqdata.timeunit-elapsed)*1000)/1000;
            
            if (remaining == 0)&&(targettime>0)
                disp('Warning: Cannot achieve target repetition time; consider reducing wait time or increasing target.')
            end

            adwin_trigger_timer = timer('TimerFcn',{@delay_sequence_callback,curcycle,endcycle,fhandle,waittime,targettime}, ...
                'StartDelay',remaining);

            start(adwin_trigger_timer);
            
            disp(sprintf('Elapsed time since last start: %gs; time to go: %gs.',elapsed,targettime*seqdata.timeunit-elapsed));
            set(buildmon,'String',sprintf('built and loaded (%gs); %gs to go',buildtime,remaining));
            drawnow;
            
            
        end
    
    else

        %sequence ended
        disp('Sequence completed!');
        seqdata.seqend = now; % in days
        
        %increment the cycle and check if we're at the end
        if ~(endcycle==-1)
            if (curcycle>=endcycle)
                disp('***************End of cycle reached.****************');
                lastcycle = 1;
               windows = get(0,'Children');
               lsfigure = windows(strcmpi(get(windows,'Name'),'Lattice Sequencer'));
               buildmon = findobj(lsfigure,'tag','buildmon');
               set(buildmon,'String','idle');              
            else
                curcycle = curcycle+1;
                lastcycle = 0;
            end
        else
            lastcycle = 0;
        end

        %start the wait period (for a MOT load, etc.)
        if ~lastcycle
            disp('Starting Wait Period');
            wait_timer = timer('TimerFcn',{@cycle_sequence_callback,curcycle,endcycle,fhandle,waittime,targettime,1},'StartDelay',round(waittime*seqdata.timeunit*1000)/1000);
            start(wait_timer);
            windows = get(0,'Children');
            lsfigure = windows(strcmpi(get(windows,'Name'),'Lattice Sequencer'));
            buildmon = findobj(lsfigure,'tag','buildmon');
            set(buildmon,'String','waiting');
        end
    end
else
   disp('Cycle Stopped');
   windows = get(0,'Children');
   lsfigure = windows(strcmpi(get(windows,'Name'),'Lattice Sequencer'));
   buildmon = findobj(lsfigure,'tag','buildmon');
   set(buildmon,'String','idle');

end
    
end