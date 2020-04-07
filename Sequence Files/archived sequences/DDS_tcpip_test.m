% MATLAB example using TCP/IP (matlab_tcpip_example.m)
% This simple code example demonstrates how you can use MATLAB to exchange data 
% with a remote application not developed in MATLAB. This code example is taken
% from a MATLAB Digest technical article written by Edward J. Mayhew from 
% George Mason University.  While HTTP was used as the higher-level protocol in 
% this example, you can use other protocols, as was the case in the project. 
% MATLAB supports TCP/IP using Instrument Control Toolbox.  Requires MATLAB and 
% Instrument Control Toolbox.  
%
% On line 14, substitute "www.EXAMPLE_WEBSITE.com" with an actual website with
% which you wish to communicate.

%% Create TCP/IP object 't'. Specify server machine and port number. 
t = tcpip('192.168.1.153', 37829); 

%% Set size of receiving buffer, if needed. 
set(t, 'InputBufferSize', 30000); 

%% Open connection to the server. 
fopen(t); 

%% Pause for the communication delay, if needed. 
pause(1) 


%% Transmit data to the server (or a request for data from the server). 

%clear command sequence
fwrite(t,native2unicode(hex2dec('C0')));

%set frequency after adwin trigger
fwrite(t,[native2unicode(hex2dec('C1')) native2unicode(hex2dec('A4'))] );
fwrite(t,[native2unicode(hex2dec('C1')),set_DDS_freq(8E6)]);

%do a frequency ramp after adwin trigger
fwrite(t,[native2unicode(hex2dec('C1')) native2unicode(hex2dec('A4'))] );
fwrite(t,[native2unicode(hex2dec('C1')) ramp_DDS_freq(3000,8E6,3E6)]);

%do a frequency ramp after adwin trigger
fwrite(t,[native2unicode(hex2dec('C1')) native2unicode(hex2dec('A4'))] );
fwrite(t,[native2unicode(hex2dec('C1')) ramp_DDS_freq(7E6,4E6,2000)]);

%execute command sequence
fwrite(t,[native2unicode(hex2dec('C4'))]);

%% Pause for the communication delay, if needed. 
pause(1) 

%% Receive lines of data from server 
% while (get(t, 'BytesAvailable') > 0) 
% t.BytesAvailable 
% DataReceived = fscanf(t) 
% end 

%% Disconnect and clean up the server connection. 
fclose(t); 
delete(t); 
clear t 