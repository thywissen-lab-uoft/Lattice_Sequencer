%------
%Author: David McKay
%Created: July 2009
%Summary: This function calculates the current sequence (creates the array
%to send to the ADWIN)
%------
function calc_sequence()

global seqdata;
global adwin_processor_speed;

disp('Calculating Sequence');

%0: disable writing to the Rabbit for testing
dodds = 1;

%% Process DDS Sweeps to the Rabbits
if dodds
disp(repmat('-',1,60));
disp('Sending DDS commands...');
%     disp(seqdata.numDDSsweeps);
    
    if seqdata.numDDSsweeps ~= 0
    
        % Create TCP/IP object 't'. Specify server machine and port number. 
        %t = tcpip('192.168.1.153', 37829); %Phase-O-matic
        %t = udp('192.168.1.156', 37829, 'LocalPort', 4629); %General Purpose DDS #3
        t(1) = udp('192.168.1.155', 37829, 'LocalPort', 4629); %RF 192.168.1.155
        t(2) = udp('192.168.1.156', 37829, 'LocalPort', 4630); %4 Pass AOM 192.168.1.156
        
        % DDS that controls the Rb Trap Offset lock
        t(3) = udp('192.168.1.157', 37829, 'LocalPort', 4631);

%       t(1) = udp('192.168.1.155', 37829, 'LocalPort', 4629); %350MHz for TA lock 192.168.1.156"
%       t(2) = udp('192.168.1.156', 37829, 'LocalPort', 4630); %6.8GHz  
%       t(3) = udp('192.168.1.157', 37829, 'LocalPort', 4631); %RF %192.168.1.157
%       
        
        %NOTE: If this process is interrupted (i.e. fopen runs, but not fclose)
        %you will get a local port
        %binding error next time you run the program. This is fixed by
        %restarting MATLAB
        
%         for i=1:3
%            fclose(t(i)); 
%         end
        
        % Set size of receiving buffer, if needed. 
        for i = 1:3 
            set(t(i), 'InputBufferSize', 30000);
            % Open connection to the server. 
            try                
                fopen(t(i)) ;   
            catch ME
                keyboard
               warning(['unable to connect to DDS ' num2str(i)]); 
            end
                
        end
        
        
        %DDS commands
        add_cmd = char(hex2dec('C1'));
        exc_cmd = char(hex2dec('C4'));
        clr_cmd = char(hex2dec('C0'));
        adwin_trig_cmd = char(hex2dec('A4'));
        hrt_beat_cmd = char(hex2dec('7F'));
        
        cmd_string = {};
        
        %string to send to DDS
        for i = 1:3
            %sending redundant clear commands to (maybe?) help this issue of the DDS
            %turning off
            for j = 1:20 %10
                fwrite(t(i),clr_cmd,'sync');
            end
            %cmd_string{i} = [clr_cmd];
        end
        %cmd_string = [];

        %Go through each DDS Sweep
        for i = 1:seqdata.numDDSsweeps
            %DDS id
            if ~(seqdata.DDSsweeps(i,1) == 1 || seqdata.DDSsweeps(i,2)) %assume DDS_ID==1 is the evaporation DDS

                warning('Specified DDS does not exist')
                
            else
                
                DDS_id = seqdata.DDSsweeps(i,1);
                
                %define the start frequency, end frequency, and sweep time
                freq1 = seqdata.DDSsweeps(i,2);
                freq2 = seqdata.DDSsweeps(i,3);
                sweep_time = seqdata.DDSsweeps(i,4);
               
                fwrite(t(DDS_id),[add_cmd adwin_trig_cmd],'sync')
                %cmd_string{DDS_id} = [cmd_string{DDS_id} add_cmd adwin_trig_cmd];
                
                %cmd_string = [cmd_string add_cmd adwin_trig_cmd ramp_DDS_freq(sweep_time,freq1,freq2,DDS_id)];
                
                cmd_string = ramp_DDS_freq(sweep_time,freq1,freq2,DDS_id);
                for j = 1:length(cmd_string)
                    fwrite(t(DDS_id),cmd_string{j},'sync');
                end
                %cmd_string{DDS_id} = [cmd_string{DDS_id} ramp_DDS_freq(sweep_time,freq1,freq2,DDS_id)];
            
            end   

        end    

        %write to DDS
        for i = 1:3
            fwrite(t(i),[exc_cmd char(hex2dec('00'))],'sync')
            %cmd_string{i} = [cmd_string{i} exc_cmd char(hex2dec('00'))];
            %disp(t(i).ValuesSent)
            
            %fwrite(t(i),cmd_string{i},'sync')
            
             % Disconnect and clean up the server connection. 
            fclose(t(i));             
        end
        delete(t); 
        clear t      
    end    
end
%% Program GPIB devices

% Note: ideally would like to check whether this update differs from
% the last one and only send commands if necessary (they take a long time).
% This, however, will only work well if device settings are never set via
% the front panel.

if isfield(seqdata,'gpib')
    try    
        % send commands; (..,1) to display query results in command window
        SendGPIBCommands(seqdata.gpib,1);
    catch ME
       warning('Unable to send GPIB commands');
       warning(ME.message);
    end
end

%% Program VISA devices

if isfield(seqdata,'visa')
    try
        % send commands; (..,1) to display query results in command window
        SendVISACommands(seqdata.visa,1);
    catch ME
       warning('Unable to send VISA commands');
       warning(ME.message);
    end
end

%% Convert Analog values into 16 bit
disp(repmat('-',1,60));
disp('Converting analog voltages to b16 ...');

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
disp('Processing digital calls ...');

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


%------------------------
%Old updatelist creation code...keep for checking against
%Removed July 2010 (DCM)

%preallocate the update size array (this makes a big difference!)
% ind = find(deltat_list==1);
% updatelistsize = length(ind);
% 
% ind = find(deltat_list>1);
% updatelistsize = updatelistsize + sum(ceil((deltat_list(ind)-1)/maxwaittime)+1);
% 
% seqdata.updatelist = zeros(1,updatelistsize);
% 
% %start the update at the second element of the array
% updatelistcount = 1;

% for i = 1:length(deltat_list)
%     
%     if deltat_list(i)==0 %update at the same time as the previous entry
%         seqdata.updatelist(updatelistcount) = seqdata.updatelist(updatelistcount)+1;
%     else
%         
%         %actual waittime is 1 less (because there is a wait period
%         %implicitly built in)
%         adwin_waittime = deltat_list(i)-1;
% 
%         %we have to put in a wait period into the update array
%         %the wait time is split into two elements...-(waitime-1) and a 0
%         %element
%         if adwin_waittime>0
%         
%             adwin_waittime = adwin_waittime-1;
%             
%             %can only enter into the update list a maximum wait of
%             %'maxwaittime' cycles
%             while adwin_waittime>maxwaittime
%                 updatelistcount = updatelistcount+1;
%                 seqdata.updatelist(updatelistcount) = -maxwaittime;
%                 adwin_waittime = adwin_waittime - maxwaittime;
%             end
% 
%             if (adwin_waittime~=0)
%                 updatelistcount = updatelistcount+1;
%                 seqdata.updatelist(updatelistcount) = -(adwin_waittime);
%             end
%             
%             %have to make a dummy "zero" entry
%             updatelistcount = updatelistcount+1;
%             seqdata.updatelist(updatelistcount) = 0;
%             
%         end
%         
%         %now create an entry for the newest update
%         updatelistcount = updatelistcount+1;
%         seqdata.updatelist(updatelistcount) = 1;
%     end
% end  
%------------------------

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

%% Run the mercurial backup
% Commenting out because we don't use this server anymore
%{
seq_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'Sequence Files');
func_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'Main Functions');
%winopen(fullfile(fileparts(fileparts(mfilename)),'run_backup.bat'));
dos(['CD ' seq_dir  ' && hg add && hg commit -m "Automatic Update" -u "LatticeSequencer"']);
dos(['CD ' func_dir  ' && hg add && hg commit -m "Automatic Update" -u "LatticeSequencer"']);
%}

%% Done
disp('Sequence calculated.');
end