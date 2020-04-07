%------
%Author: Stefan Trotzky
%Created: November 2013
%Summary: This is a test sequence
%------

function timeout = pixelfly_image(timein)

curtime = timein;

global seqdata;

    seqdata.flags. image_type = 0; %0: absorption image, 1: recapture, 2:fluor, 3: blue_absorption, 4: MOT fluor, 5: load MOT immediately, 6: MOT fluor with MOT off, 7: fluorescence image after do_imaging_molasses
    seqdata.flags. image_loc = 1; %0: MOT cell, 1: science chamber


curtime = calctime(curtime,1000);

curtime = absorption_image(curtime);

curtime = calctime(curtime,1000);

%% End
timeout = curtime;

        
end