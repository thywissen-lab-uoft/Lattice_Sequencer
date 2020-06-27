function hF=plotSequence(fhandle,cycle,channels,times)
% plotSequence.m
% 
% Plots the sequence for a given set of analog and digital channels.
% 
% Authors: C Fujiwara
%
% This code is meant to be update the old sequence visualizer code
% PlotSequenceVersion2.m.  Therefore it has some historical forms which
% should be changed in future versions of this code.
%
%   fhandle - sequence function handle
%   cycle - cycle
%   channels - which channels to analyze
%   times - the time limits on which to plot


global seqdata;
%close all;

%added by DCM - July 2010
%close only existing plot windows

%get the handles to all currently open windows
windowhnds = get(0,'Children');

for i = 1:length(windowhnds)
    if get(windowhnds(i),'UserData')==159 %code for a plot window
        close(windowhnds(i));
    end
end
end

