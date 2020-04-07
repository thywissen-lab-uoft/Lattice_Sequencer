%------
%Author: David McKay
%Created: July 2009
%Summary: Create all the appropriate structures and add the correct paths. Only needs to be run on
%startup.
%------

function LatticeSequencerInitialize()

%add paths
curpath = fileparts(mfilename('fullpath'));
% 
addpath(curpath);
addpath(fullfile(curpath,'Sequence Files'));
addpath(fullfile(curpath,'Main Functions'));
addpath(fullfile(curpath,'GUI Functions'));


global adwin_booted;
global adwinprocessnum;
global adwin_processor_speed;
global adwin_connected;
global adwin_process_path;

adwinprocessnum = -1;
adwin_booted = 0;
adwin_process_path = fullfile(curpath,'TransferData.TB1'); %path of the TB1 file to be loaded on the ADWIN

%this allows debugging without being connected to the ADWIN
adwin_connected = 1;

%reset seqdata
clear global seqdata;
global seqdata;

%main sequence data
seqdata = struct('analogadwinlist',[],... %adwin list is [time channel value];
    'digadwinlist',[],... %list is [time channel value boardchannel bytevalue]
    'deltat',1*5E-6,... %time step between ADWIN events (must be an integer number of ADWIN clock cycles)
    'cycle',1,... %for cycling runs. This can be used as an array identifier
    'cyclecounter',1,... %this is the number of cycles run
    'randcyclelist',[],... %this is a list of all the cycle numbers randomized
    'analogchannels',struct([]),... %analog channels information
    'timeunit',1E-3,... %how we refer to times (ie. this sets to 1ms)
    'digchannels',struct([]),... %digital channel info
    'digoffset',80,... %offset to add to dig channels to differentiate from analog
    'digcardchannels',[101,102],... %actual dig card channel on adwin
    'diglastvalue',[0 0],... %last value of the digital card sent to the sequencer
    'digcardnum',2,...%number of dig cards
    'updatelist',[],...%update list to send to ADWIN
    'chnum',[],... %channel list to send to ADWIN
    'chval',[],... %channel value list to send to ADWIN
    'seqcalculated',-1,... %has the sequence been calculated?
    'seqloaded',-1,... %has the sequence been loaded to the ADWIN?
    'sequencetime',0,... %time for the sequence to run
    'outputfilepath','Z:\Experiments\Lattice\_communication\',... %path to output sequence parameters to
    'outputparams',[],...%parameters to output
    'createoutfile',1,... 
    'numDDSsweeps',0,... %Add these two lines! 
    'DDSsweeps',[],...
    'atomtype',4); %1 - K-40, 2 - K-41, 3 - Rb-87 , 4 - Rb+K

%ADWIN processor speed
adwin_processor_speed = 300E6;

if isempty(adwin_booted)
    adwin_booted = 0;
end

%run initializers
initialize_channels();

end
