%------
%Author: David McKay
%Created: July 2009
%Summary: Directory button callback for specifying the location of the
%output file for parameters
%------

function dirbutton_callback(hobject,eventdata)

newpath = uigetdir(get(hobject,'string'));

if (newpath~=0)
    ui_dirtext = findobj(gcbf,'tag','outfilepath');
    set(ui_dirtext,'string',newpath);
end

end