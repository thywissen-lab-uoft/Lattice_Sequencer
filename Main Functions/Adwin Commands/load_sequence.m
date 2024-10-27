%------
%Author: David McKay
%Created: July 2009
%Summary: This function loads the current sequence to the ADWIN
%------
function load_sequence()

global seqdata;
global adwin_booted;
global adwinprocessnum;
global adwin_processor_speed;
global adwin_connected;
global adwin_process_path;

%add the ADWIN path
addpath('C:\ADWIN\DEVELOPER\MATLAB\ADWIN\');

%set the loaded to false
seqdata.seqloaded = 0;

if adwin_connected

    %run ADWIN loading processes
    if ~adwin_booted
        disp('booting adwin');
        ADwin_Init();
        Set_DeviceNo(1);
        Boot('C:\ADWIN\ADWIN11.BTL',0);
        adwin_booted = 1;
    end

    %load the ADWIN process
    if adwinprocessnum<0
        adwinprocessnum = Load_Process(adwin_process_path);
    end

    %this is the number of adwin clock cycles per update
    globaldelay = adwin_processor_speed*seqdata.deltat;

    %note: need to put this on a timer or something!

    %send the update list
    disp('Loading the Update List');
%     seqdata.updatelist
    Set_Par(1,length(seqdata.updatelist)-1); %maxcount in Adbasic file
    SetData_Double(1,seqdata.updatelist,1);

    %set the number of clock cycles between updates
    Set_Par(2,globaldelay);

    %send the channel update information
    disp('Loading the Channel Information');
    SetData_Double(2,seqdata.chnum,1);
    SetData_Double(3,seqdata.chval,1);
    
    %load the reset to zero data (default DO NOT reset to zero)
    SetData_Double(4,zeros(1,64+seqdata.digcardnum),1); % length of zeros: number of analog channels plus number of digital cards
    
    %update the last digital value sent to the sequencer (for subsequent
    %processes)
    for i = 1:length(seqdata.digcardchannels)
        ind = logical(seqdata.chnum==seqdata.digcardchannels(i)|seqdata.chnum==(seqdata.digcardchannels(i)+seqdata.digcardnum));
        digupdatelist = seqdata.chval(ind);
        digchannellist = seqdata.chnum(ind);
        if ~isempty(digupdatelist)
            if digchannellist(end)==(seqdata.digcardchannels(i)+seqdata.digcardnum)
                digupdatelist(end) = digupdatelist(end) + 2^(31);
            end
            seqdata.diglastvalue(i) = digupdatelist(end);
        end
    end
    
    %% Save Camera Control Files
    
    if isfield(seqdata,'CameraControl') && isfield(seqdata,'camera_control_file')
        CameraControl = seqdata.CameraControl;
        save(seqdata.camera_control_file,'-struct','CameraControl');       
        disp('Writing Camera Control File');
    end    
end

%the sequence is loaded
seqdata.seqloaded = 1;

end