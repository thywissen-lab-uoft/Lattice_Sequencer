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
addpath(fullfile(curpath,'Sequence Files','Load Magtrap Sequence Files'));
addpath(fullfile(curpath,'Sequence Files','Load Magtrap Sequence Files','absorption_imaging'));
addpath(fullfile(curpath,'Sequence Files','Load Magtrap Sequence Files','debugging'));
addpath(fullfile(curpath,'Sequence Files','Load Magtrap Sequence Files','magnetic_trap'));
addpath(fullfile(curpath,'Sequence Files','Load Magtrap Sequence Files','magneto_optical_trap'));
addpath(fullfile(curpath,'Sequence Files','Load Magtrap Sequence Files','optical_dipole_trap'));
addpath(fullfile(curpath,'Sequence Files','Load Magtrap Sequence Files','optical_lattice'));
addpath(fullfile(curpath,'Sequence Files','Load Magtrap Sequence Files','miscellaneous'));
addpath(fullfile(curpath,'Sequence Files','Load Magtrap Sequence Files','spectroscopy'));

addpath(fullfile(curpath,'Sequence Files','Core Sequences'));
addpath(fullfile(curpath,'Sequence Files','Action Files'));
addpath(fullfile(curpath,'Main Functions'));
addpath(fullfile(curpath,'Main Functions','Adwin Commands'));
addpath(fullfile(curpath,'Main Functions','Device Functions'));
addpath(fullfile(curpath,'Main Functions','Math Functions'));
addpath(fullfile(curpath,'Main Functions','AMO Functions'));
addpath(fullfile(curpath,'Main Functions','User Interfacing'));
addpath(fullfile(curpath,'Main Functions','Calibrations'));

addpath(fullfile(curpath,'GUI'));
addpath(fullfile(curpath,'GUI','images'));

addpath(fullfile(curpath,'Parameter Functions'));


global adwin_booted;
global adwinprocessnum;
global adwin_processor_speed;
global adwin_connected;
global adwin_process_path;

adwinprocessnum = -1;
% adwin_booted = 0;
adwin_process_path = fullfile(curpath,'TransferData.TB1'); 
%path of the TB1 file to be loaded on the ADWIN

%this allows debugging without being connected to the ADWIN
adwin_connected = 1;

%reset seqdata
clear global seqdata;
global seqdata;

%main sequence data
seqdata = struct('analogadwinlist',[],...   % adwin list is [time channel value];
    'digadwinlist',[],...                   % list is [time channel value boardchannel bytevalue]
    'deltat',1*5E-6,...                     % time step between ADWIN events (must be an integer number of ADWIN clock cycles)
    'cycle',1,...                           % for cycling runs. This can be used as an array identifier (CF: unused?)
    'randcyclelist',[],...                  % this is a list of all the cycle numbers randomized
    'analogchannels',struct([]),...         % analog channels information
    'timeunit',1E-3,...                     % how we refer to times (ie. this sets to 1ms)
    'digchannels',struct([]),...            % digital channel info
    'digcardchannels',[101,102,103],...     % 101 corresponds to Module 2 on ADwin, 102 corresponds to Module 1, 103 corresponds to Module 3
    'diglastvalue',[0 0 0],...              % last value of the digital card sent to the sequencer
    'digcardnum',3,...                      % number of dig cards
    'updatelist',[],...                     % update list to send to ADWIN
    'chnum',[],...                          % channel list to send to ADWIN
    'chval',[],...                          % channel value list to send to ADWIN
    'seqcalculated',-1,...                  % has the sequence been calculated?
    'seqloaded',-1,...                      % has the sequence been loaded to the ADWIN?
    'sequencetime',0,...                    % time for the sequence to run
    'outputparams',[],...                   % parameters to output
    'numDDSsweeps',0,...                    % Add these two lines! 
    'DDSsweeps',[],...
    'atomtype',4,...                        % 1 - K-40, 2 - K-41, 3 - Rb-87 , 4 - Rb+K % seems bad to me
    'params', [],...                        % various parameters, recently defined here by FC 07/23/2020
    'flags',[],...
    'sequence_functions',{}); 

seqdata.scancycle=1;
seqdata.randcyclelist=makeRandList;

%ADWIN processor speed (300 MHz)
adwin_processor_speed = 300E6;

if isempty(adwin_booted)
    adwin_booted = 0;
end

% Check the computer hostname for debug mode
[~, name] = system('hostname');
name = strrep(name,newline,'');     % remove new line character
name = strrep(name,char(13),'');    % remove carriage return
if isequal(name,'kitty')
    seqdata.debugMode = 1;
else
    seqdata.debugMode = 0;
end


%run initializers
initialize_channels();

end
