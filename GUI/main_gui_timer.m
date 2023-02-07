function t = main_gui_timer(fig)


  

% The adwin progress timer object
t=timer('Name','mytimer','ExecutionMode','FixedSpacing',...
    'TimerFcn',@update,'Period',.05,...
    'StopFcn',@stopAdwinTimer,'StartFcn',@startAdwinTimer);

dQ = struct;
dQ(1).Name = 'bob';
dQ(2).Name = 'tom';

t.UserData = struct;
t.UserData.GUI = fig;
t.UserData.CommandQueue = dQ;
t.UserData.ElapsedTime = 0;
t.UserData.AdwinTime = 3;
t.UserData.WaitTime = 2;
t.UserData.Status = 'off';

% Function to run when the adwin starts the sequence.
function startAdwinTimer(src,evt)        
    src.UserData.TimerStart = now;      % Start time
    src.UserData.ElapsedTime = 0;       % Reset timer
    q = src.UserData.CommandQueue(1);   % Get the next command to run
    disp(q);
end

% Timer update function
function update(src,evt)
    dT          = 24*60*60*(now - src.UserData.TimerStart); % Elapsped Time
    dT_adwin    = src.UserData.AdwinTime;                   % Adwin Time
    dT_wait     = src.UserData.WaitTime;                    % Wait Time
    
    src.UserData.ElapsedTime = dT;      % Elapsed Time   
    data=guidata(src.UserData);         % GUI Data
    
    if dT<=dT_adwin    
        % Update partial adwin bar
        data.pAdWinBar.XData    = [0 1 1 0]*dT/dT_adwin;
        data.tAdWinTime1.String = [num2str(dT,'%.2f') ' s'];
        data.tAdWinTime2.String = [num2str(dT0,'%.2f') ' s'];
    else
        % Update complete adwin bar
        data.pAdWinBar.XData = [0 1 1 0];
        data.tAdWinTime1.String = [num2str(dT0,'%.2f') ' s'];
        data.tAdWinTime2.String = [num2str(dT0,'%.2f') ' s'];
        
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
    src.UserData.CommandQueue(1)=[];
    if ~isempty(src.UserData.CommandQueue)
        start(src);
    else
        disp('Queue is empty');
    end
end

end

