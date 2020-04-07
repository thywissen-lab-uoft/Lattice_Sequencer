function rotation_stage_move(move_steps)
%This function moves the rotation stage by a set number of steps
% 178000 steps is one full revolution
% This can be used to find the position for maximum transmission/reflection
% from a PBS, and then that position can be set as the new home position
% using the rotation_stage_home command, before switching back to analog
% control using the rotation_stage_analog command.

%BE SURE TO SET THE WAVEPLATE INPUT TO 0 VOLTS BEFORE RESETTING THE HOME
%POSITION!!!

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

%Move the specified number of steps
fprintf(g,['MR',num2str(move_steps)])

pause(1+abs(move_steps)/120000)

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
steps = str2double(pos_strg(6:18))

% %Send a command to move
% fprintf(g,'MR-40000')

% %Send a command to sqitch to analog control
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