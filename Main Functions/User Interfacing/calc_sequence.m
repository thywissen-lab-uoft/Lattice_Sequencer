%------
%Author: David McKay
%Created: July 2009
%Summary: This function calculates the current sequence (creates the array
%to send to the ADWIN)
%------
function calc_sequence(doProgramDevices)

global seqdata;
global adwin_processor_speed;

fprintf('Calculating sequence...');

if nargin == 0
    doProgramDevices = 1;
end

%% Process DDS Sweeps
if doProgramDevices && ~seqdata.debugMode
disp('DDS...');    
    if seqdata.numDDSsweeps ~= 0    
        % Create TCP/IP object 't'. Specify server machine and port number. 
        t(1) = udp('192.168.1.155', 37829, 'LocalPort', 4629); % RF
        t(2) = udp('192.168.1.156', 37829, 'LocalPort', 4630); % 4 Pass         
        t(3) = udp('192.168.1.157', 37829, 'LocalPort', 4631); % Rb Trap Offset Lock
        
%                 t(4) = udp('192.168.1.154', 37829, 'LocalPort', 4628); % K Trap DDS Test

        % Set size of receiving buffer, if needed. 
        for i = 1:3 
            set(t(i), 'InputBufferSize', 30000);
            % Open connection to the server. 
            try                
                fopen(t(i)) ;   
            catch ME
               warning(['unable to connect to DDS ' num2str(i)]); 
            end                
        end        
        
        %DDS commands (See Alan Stummer's website for details)
        add_cmd = char(hex2dec('C1'));
        exc_cmd = char(hex2dec('C4'));
        clr_cmd = char(hex2dec('C0'));
        adwin_trig_cmd = char(hex2dec('A4'));
        hrt_beat_cmd = char(hex2dec('7F'));        
        cmd_string = {};
        
        % Resync DDS multiple times to reset (is this needed?)
        for i = 1:3
            for j = 1:20 %10
                fwrite(t(i),clr_cmd,'sync');
            end
        end

        %Go through each DDS Sweep
        for i = 1:seqdata.numDDSsweeps
            %DDS id
            if ~(seqdata.DDSsweeps(i,1) == 1 || seqdata.DDSsweeps(i,2)) %assume DDS_ID==1 is the evaporation DDS
                warning('Specified DDS does not exist')                
            else                
                DDS_id = seqdata.DDSsweeps(i,1);            % DDS id     
                freq1 = seqdata.DDSsweeps(i,2);             % f1
                freq2 = seqdata.DDSsweeps(i,3);             % f2
                sweep_time = seqdata.DDSsweeps(i,4);        % sweep time    
                
                % Sync trigger (?)
                fwrite(t(DDS_id),...
                    [add_cmd adwin_trig_cmd],'sync');
                % Get the sweep command
                cmd_string = ramp_DDS_freq(sweep_time,freq1,freq2,DDS_id);
                % Write the command
                for j = 1:length(cmd_string)
                    fwrite(t(DDS_id),cmd_string{j},'sync');
                end            
            end   
        end    

        % Write to DDS an ending command (?)
        for i = 1:3
            fwrite(t(i),[exc_cmd char(hex2dec('00'))],'sync'); % write
            fclose(t(i)); % disconnect
        end
        
        % Remove TCP/IP handle
        delete(t); 
        clear t      
    end    
else 
    disp('skipping dds...');
end
%% Program GPIB devices

if doProgramDevices && isfield(seqdata,'gpib') && ~seqdata.debugMode
    try    
        fprintf('gpib...');
        % send commands; (..,1) to display query results in command window
        SendGPIBCommands(seqdata.gpib,1);
    catch ME
       warning(ME.message);
    end
else
    fprintf('skipping gpib...');
end

%% Program VISA devices

if doProgramDevices && isfield(seqdata,'visa') && ~seqdata.debugMode
    try
        fprintf('visa...');
        SendVISACommands(seqdata.visa,1);
    catch ME
       warning(ME.message);
    end
else
    fprintf('skipping visa ...');
end

%% Convert Analog values into 16 bit
%disp(repmat('-',1,60));
%disp('Converting analog voltages to b16 ...');

fprintf('analog...');

%Used to be in the ADWIN, but moved here so that we can use a long for the
%ADWIN data array
%FC - If an analog channel isn't addressed throughout the sequence then this
%throws an error.
% if (~isempty(seqdata.analogadwinlist))
%     seqdata.analogadwinlist(:,3) = (seqdata.analogadwinlist(:,3)+10)/20*2^(16);
% else
%     error('No analog channel was referenced during sequence.');
% end

% Convert analog voltage commands [-10V, 10V] into [0 2^16] for adwin write
analogAdwin = seqdata.analogadwinlist;

analogAdwin(:,3) = (seqdata.analogadwinlist(:,3)+10)/20*2^(16);


%% Reformat Digital Channel Update Array
%Change the digital update array into an array of update words

if (~isempty(seqdata.digadwinlist))
fprintf('digital...');

    %pre-allocate, can be no bigger than the current update list
    new_digarray = zeros(length(seqdata.digadwinlist(:,1)),3);

    %first sort the digital array by time
    [tempdigarray, sortindices] = sort(seqdata.digadwinlist(:,1));
    sorteddiglist = seqdata.digadwinlist(sortindices(:,1),:);
    curcardindex=zeros(1,length(seqdata.digcardchannels));
    curindex = 0;

    for i = 1:length(seqdata.digcardchannels)

        %get the elements associated with this card
        ind = logical(sorteddiglist(:,4)==seqdata.digcardchannels(i));
        curdigarray = sorteddiglist(ind,:);  
        for j = 1:length(curdigarray(:,1))
            
            %if the same update time then just change the bit
            if ((curcardindex(i)>0)&&(curdigarray(j,1)==new_digarray(curindex,1))&&(curdigarray(j,4)==new_digarray(curindex,2))) 
                new_digarray(curindex,3) = bitset(new_digarray(curindex,3),curdigarray(j,5),curdigarray(j,3));
            else
                %new update, start with the current output word, then change
                %only the relevant channel
                if (curcardindex(i)==0)
                    curcardindex(i) = 1;
                    curindex = curindex+1;
                    new_digarray(curindex,:) = [curdigarray(j,1) curdigarray(j,4) seqdata.diglastvalue(i)];
%                     disp(dec2bin(new_digarray(1,3)));
                else
                    curindex = curindex + 1;
                    new_digarray(curindex,:) = [curdigarray(j,1) curdigarray(j,4) new_digarray(curindex-1,3)];
                end
                new_digarray(curindex,3) = bitset(new_digarray(curindex,3),curdigarray(j,5),curdigarray(j,3));
            end
        end
    end
%     disp(dec2bin(new_digarray(:,3)));
    %FC - Not sure why we do the following, it gets changed back once
    %variables are passed to the ADbasic file
    %if the 32nd bit is set, then add a sign
    ind = (bitget(new_digarray(1:curindex,3),32)==1);
    new_digarray(ind,3) = new_digarray(ind,3) - 2^(31);
    new_digarray(ind,2) = new_digarray(ind,2)+seqdata.digcardnum;
    
%     new_digarray

    %append the digital array to the current analog array
%     adwinlist = [seqdata.analogadwinlist; new_digarray(1:curindex,:)];    
    adwinlist = [analogAdwin; new_digarray(1:curindex,:)];    
else    
%     adwinlist = [seqdata.analogadwinlist];    
    adwinlist = [analogAdwin];
end


%% Process Main Array
fprintf('timings...');

%sort the adwin list by times
[templist, sortindices] = sort(adwinlist,1);

adwinlist = adwinlist(sortindices(:,1),:);

%for some reason the ADWIN starts at the second element in these arrays
%FC - its because in the ADbasic code, the index counter starts at 2 rather
%than 1, could be changed?
seqdata.chnum = [0; adwinlist(:,2)];
seqdata.chval = [0; adwinlist(:,3)];

%The maximum compression value (in cycle units)
maxwaittime = floor(2^30/adwin_processor_speed/seqdata.deltat);

%this is an array which is the difference between the current update and
%the last update
%Options:
%0: Same update interval as the previous (increment the update list)
%1: Next update interval (create new update entry)
%>1: Many cycles passed since the last update. Create an update entry to
%reflect the gap and then another one to reflect the new update.

deltat_list = adwinlist(1:end,1)-[-1; adwinlist(1:end-1,1)];

%Optimized code for making the update list
%Added July 2010 - DCM

%determine the number of sequential zeros in the delta time update list so
%that we know how many updates to do in one cycle when creating the
%"updatelist"
zero_list = (deltat_list==0);
temp_zero_list1 = zero_list;
temp_zero_list2 = zero_list;
count = 0;

while sum(temp_zero_list1) ~= 0
    temp_zero_list1 = (temp_zero_list1 + [temp_zero_list1(2:end); 0]).*temp_zero_list2;
    zero_list = zero_list + temp_zero_list1;
    
    count = count + 2;
    
    temp_zero_list1 = (zero_list>count);
end

zero_list = zero_list/2;

%find times at which many updates are done
seqdata.numupdatelist = [zero_list(2:end);0] + 1;
seqdata.numupdatelist = [adwinlist(deltat_list~=0,1)*seqdata.deltat/seqdata.timeunit ...
    seqdata.numupdatelist(deltat_list~=0)];
% disp(sprintf('Maximal number of updates in one cylce: %g',max(unique(seqdata.numupdatelist(:,2)))));

%make expanded array for the update list
deltat_list2 = ones(length(deltat_list)*3,1);
deltat_list2(1:3:(length(deltat_list2)-1)) = (deltat_list-1);
deltat_list2(2:3:(length(deltat_list2)-1)) = -2.5; %placeholder
deltat_list2(3:3:(length(deltat_list2))) = [zero_list(2:end);0] + 1;

%clear repeated updates
ind = (deltat_list2 ~= -1);
deltat_list2 = deltat_list2.*ind;
deltat_list2 = deltat_list2.*[1; ind(1:(end-1))];
deltat_list2 = deltat_list2.*[1; 1; ind(1:(end-2))];

%set the wait times to negative
deltat_list2(1:3:(length(deltat_list2)-1)) = deltat_list2(1:3:(length(deltat_list2)-1))*-1;

%take out all the zeros in the array
temp_update_list = nonzeros(deltat_list2);

ind = (temp_update_list ==-2.5);

%add zeros that need to be after each wait time
ind2 = (temp_update_list.*([ind(2:end);1])<0);

%take one wait cycle off each wait time
temp_update_list = temp_update_list + ind2;

%remove unnecessary zeros when doing sequential updates
ind2 = (temp_update_list.*([ind(2:end);1])>0);
temp_update_list = temp_update_list.*(~[0;ind2(1:end-1)]);

temp_update_list = nonzeros(temp_update_list);

%replace -2.5 with 0
ind = (temp_update_list==-2.5);
temp_update_list = [0; temp_update_list.*(~ind)];

%check for wait times that are larger than allowed
temp_update_list = temp_update_list';

%find the number of wait periods that exceed the maximum allowed wait
%period
ind = (temp_update_list<-maxwaittime);

%this is the number of additional rows we need
expansion_size = sum(floor((-1*temp_update_list)/maxwaittime).*ind);

if expansion_size>0

    %row indices of the wait times that need to be expanded
    index_list = nonzeros(ind.*(1:length(temp_update_list)));

    %preallocate a new array
    temp_update_list2 = zeros(1,length(temp_update_list)+expansion_size);

    cur_index = 1;
    num_adds = 0;
    
    %go through for each section that needs to be expanded
    for i = 1:length(index_list)
        
        %put all the before elements into the new array
        temp_update_list2((cur_index+num_adds):(index_list(i)+num_adds-1)) = temp_update_list(cur_index:(index_list(i)-1));
        
        num_adds2 = floor((-1*temp_update_list(index_list(i)))/maxwaittime);
        
        temp_update_list2((index_list(i)+num_adds):(index_list(i)+num_adds+num_adds2-1)) = -maxwaittime;
        
        temp_update_list2((index_list(i)+num_adds+num_adds2)) = -rem(-temp_update_list(index_list(i)),maxwaittime);
        
        cur_index = index_list(i)+1;
        num_adds = num_adds + num_adds2;
        
    end
    
    temp_update_list2((cur_index+num_adds):end) = temp_update_list((index_list(i)+1):end);
    temp_update_list = temp_update_list2;
    
end

seqdata.updatelist = temp_update_list;

%Add 5 cycle waits at the end
seqdata.updatelist(end+1) = -5;

%% Finishing


%calculate the sequence time
seqdata.sequencetime = 0;

%add up all the update cycles
ind = logical(seqdata.updatelist>=0);
seqdata.sequencetime = length(seqdata.updatelist(ind));

%add up all the wait time cycles
ind = logical(seqdata.updatelist<0);
seqdata.sequencetime = seqdata.sequencetime+ sum(seqdata.updatelist(ind)*-1);

seqdata.sequencetime = seqdata.sequencetime*seqdata.deltat;

%add a thousand cycles onto the time (for good measure)
seqdata.sequencetime = seqdata.sequencetime + 1E3*seqdata.deltat;

%reset the number of DDS sweeps
seqdata.numDDSsweeps = 0;

%the sequence has been calculated
seqdata.seqcalculated = 1;


seqdata = orderfields(seqdata);

disp('done.');
end