function t = mainGUI_timer(fig)
global seqdata

% The adwin progress timer object
t=timer('Name','sequencer_gui_timer','ExecutionMode','FixedSpacing',...
    'TimerFcn',@update,'Period',.05,...
    'StopFcn',@stopAdwinTimer,'StartFcn',@startAdwinTimer);

dQ = struct;

t.UserData = struct;
t.UserData.GUI = fig;
t.UserData.CommandQueue = dQ;
t.UserData.ElapsedTime = 0;
t.UserData.AdwinTime = 3;
t.UserData.WaitTime = 2;
t.UserData.Status = 'off';

% Need to break up run sequence if want to use this because the timer
% begings as soon as start fcn is called.

% Function to run when the adwin starts the sequence.
function startAdwinTimer(src,evt)        
    if isempty(src.UserData.CommandQueue)
        warning('No commands in queue to run.');
       return; 
    end
    
    src.UserData.TimerStart = now;      % Start time
    src.UserData.ElapsedTime = 0;       % Reset timer
    q = src.UserData.CommandQueue(1);   % Get the next command to run
end

% Timer update function
function update(src,evt)
    dT          = 24*60*60*(now - src.UserData.TimerStart); % Elapsped Time
    dT_adwin    = src.UserData.AdwinTime;                   % Adwin Time
    dT_wait     = src.UserData.WaitTime;                    % Wait Time
    
    src.UserData.ElapsedTime = dT;      % Elapsed Time   
    data=guidata(src.UserData.GUI);         % GUI Data
    
    if dT<=dT_adwin    
        
        % Update partial adwin bar
        data.pAdWinBar.XData    = [0 1 1 0]*dT/dT_adwin;
        data.tAdWinTime1.String = [num2str(dT,'%.2f') ' s'];
        data.tAdWinTime2.String = [num2str(dT_adwin,'%.2f') ' s'];
    else
        % Update complete adwin bar
        data.pAdWinBar.XData = [0 1 1 0];
        data.tAdWinTime1.String = [num2str(dT_adwin,'%.2f') ' s'];
        data.tAdWinTime2.String = [num2str(dT_adwin,'%.2f') ' s'];
        
        dTw = dT-dT_adwin;         
        if dTw<dT_wait
            % Update partial wait bar
            data.pWaitBar.XData    = [0 1 1 0]*dTw/dT_wait;
            data.tWaitTime1.String = [num2str(dTw,'%.2f') ' s'];
            data.tWaitTime2.String = [num2str(dT_wait,'%.2f') ' s'];
        else
            % Update complete wait bar
            data.pWaitBar.XData = [0 1 1 0];
            data.tWaitTime1.String = [num2str(dT_wait,'%.2f') ' s'];
            data.tWaitTime2.String = [num2str(dT_wait,'%.2f') ' s'];
        end        
    end
    
    % End the timer
    if dT>(dT_adwin+dT_wait)
       stop(src); 
    end
end

% Function to evaluate when the sequence is done
function stopAdwinTimer(src,evt)
    if ~isempty(src.UserData.CommandQueue)        
        src.UserData.CommandQueue(1)=[];
    end
    
    if ~isempty(src.UserData.CommandQueue)
        start(src);
    else
        disp('Queue is empty');
    end
end

end

