function rotation_stage_home()
%This function defines the current waveplate position as the new home 
% position for the rotating waveplate

%% Establish Connection
%Define serial port object
g = serial('COM5');

%Need to change the end of line character from the standard 'LF' to 'CR'
g.Terminator = 'CR';

%Open connection to serial port object
fopen(g)

%First command must enable PC control of the waveplate 
%   (analog control default)
fprintf(g,'pc')

%% Send Commands

%Transmit a command asking for the current position
%   (clear input buffer first since some info will be left there by the
%   move command etc...)
flushinput(g)
fprintf(g,'tp')

%Read the command into a string 
%   (use fgetl to discard the end of line character)
pos_strg = fgetl(g);
% 
%The string returned has a bunch of other data, so crop out the position
%and convert to a number
old_position = str2double(pos_strg(6:18))

%Send a command to move
fprintf(g,'dh')
pause(1)
%Transmit a command asking for the current position
%   (clear input buffer first since some info will be left there by the
%   move command etc...)
flushinput(g)
fprintf(g,'tp')

%Read the command into a string 
%   (use fgetl to discard the end of line character)
pos_strg = fgetl(g);
% 
%The string returned has a bunch of other data, so crop out the position
%and convert to a number
new_position = str2double(pos_strg(6:18))

% % %Send a command to sqitch to analog control
% fprintf(g,'am4')
% 
% %Send a command to switch to PC control
% fprintf(g,'pc')

%% Close the connection
fclose(g)
%Need to delete this connection from memory so that it doesn't clog up
%   the instrfind object
delete(g)
clear g

end