function flags = check_HF_Image()
%Check if the sequence is currently at high field to determine whether or
%not to perform high field imaging.

global seqdata;

FB_value = getChannelValue(seqdata,'FB current',1,0);

if FB_value > 100 && FB_value < 202.15
    seqdata.flags.HF_Imaging = 1;
    seqdata.flags.HF_absorption_image.Attractive = 0;
elseif FB_value >= 202.15
    seqdata.flags.HF_Imaging = 1;
    seqdata.flags.HF_absorption_image.Attractive = 1;
elseif FB_value <= 100
    seqdata.flags.HF_Imaging = 0;
end


end

