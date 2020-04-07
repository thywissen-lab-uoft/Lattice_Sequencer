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

%% Reformat Digital Channel Update Array
%Change the digital update array into an array of update words

if (~isempty(seqdata.digadwinlist))

    %pre-allocate, can be no bigger than the current update list
    new_digarray = zeros(length(seqdata.digadwinlist(:,1)),3);

    %first sort the digital array by time
    [tempdigarray sortindices] = sort(seqdata.digadwinlist(:,1));
    sorteddiglist = seqdata.digadwinlist(sortindices(:,1),:);

    curindex=0;

    for i = 1:length(seqdata.digcardchannels)

        %get the elements associated with this card
        ind = logical(sorteddiglist(:,4)==seqdata.digcardchannels(i));
        curdigarray = sorteddiglist(ind,:);

        for j = 1:length(curdigarray(:,1))
            if ((curindex>0)&&(curdigarray(j,1)==new_digarray(curindex,1))) 
                new_digarray(curindex,3) = bitset(new_digarray(curindex,3),curdigarray(j,5),curdigarray(j,3));
            else
                %new update, start with the current output word, then change
                %only the relevant channel
                if (curindex==0)
                    curindex = 1;
                    new_digarray(curindex,:) = [curdigarray(j,1) curdigarray(j,4) seqdata.diglastvalue(i)];
                else
                    curindex = curindex + 1;
                    new_digarray(curindex,:) = [curdigarray(j,1) curdigarray(j,4) new_digarray(curindex-1,3)];
                end
                new_digarray(curindex,3) = bitset(new_digarray(curindex,3),curdigarray(j,5),curdigarray(j,3));
            end
        end
        
    end

    %append the digital array to the current analog array
    adwinlist = [seqdata.analogadwinlist; new_digarray(1:curindex,:)];
else
    adwinlist = [seqdata.analogadwinlist];
end

%% Process Main Array

%sort the adwin list by times
[templist sortindices] = sort(adwinlist);

adwinlist = adwinlist(sortindices(:,1),:);

%for some reason the ADWIN starts at the second element in these arrays
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

%add a thousand cycles onto the time
seqdata.sequencetime = seqdata.sequencetime + 1E3*seqdata.deltat;

%the sequence has been calculated
seqdata.seqcalculated = 1;

end