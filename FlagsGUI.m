%------
%Author: Stefan Trotzky
%Created: July 2009
%Summary: Create the lattice sequencer GUI
%------

function FlagsGUI(flags, strings)

if ~exist('strings','var'); strings = {}; end
if ischar(strings); strings = {strings}; end

%get the screen size
screensize = get(0,'screensize');

% search for sequence flags window among open figures
windowhdls = get(0,'Children');
fh = -1;
for j = 1:length(windowhdls)
    if strcmpi(get(windowhdls(j),'name'),'Lattice Sequencer Flags')
        fh = windowhdls(j);
        break;
    end
end

% get names of flags
flagnames = fieldnames(flags);

% generate / update flag monitor window
a = 20;
b = 13;
c = 0;
height = ((length(flagnames)+1)*a+40);
if ~isempty(strings); c = a*(length(strings)+1); height = height + c;  end
width = 300;
if (fh == -1)
    fh = figure('MenuBar','None','Toolbar','none','name','Lattice Sequencer Flags','Position',[screensize(3)/2-width/2 screensize(4)/2-height/2 width height]);
else
%     figure(fh)
    pos = get(fh,'Position');
    set(fh,'Position',[pos(1)+pos(3)/2-width/2 pos(2)+pos(4)-height width height])
    clf(fh);
end

figcolor = get(fh,'Color');

% header
uicontrol(fh,'Style','text','String','Sequence Flags','Position',[20 height-30 250 a],'FontSize',10,'BackgroundColor',figcolor);

% add flag entries
for j = 1:length(flagnames)
    val = flags.(flagnames{j});
    n = length(val);
    for i = 1:n
          if (val(i) == 0); color = 'r';
          elseif (val(i) == 1); color = 'g';
          else color = 'c';
          end
          uicontrol(fh,'Style','text','String',num2str(val(i)),'Position',[80-(n-i+1)*a (length(flagnames)+1-j)*a+c b b],'BackgroundColor',color)
    end
    uicontrol(fh,'Style','text','String',flagnames{j},'HorizontalAlignment','left','Position',[90 (length(flagnames)+1-j)*a+c 200 b],'BackgroundColor',figcolor)
end

% add text entries
if ~isempty(strings)
    for j = 1:length(strings)
        uicontrol(fh,'Style','text','String',strings{j},'HorizontalAlignment','left','Position',[40 (length(strings)+1-j)*a 200 b],'BackgroundColor',figcolor)
    end
end


end