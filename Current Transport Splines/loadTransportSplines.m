function [splines,data] = loadTransportSplines
% loadTransportSplines.m
%
% Author  : CJ Fujiwara
% Date    : 2020/07/16
% This functions loads the calibration text files which define how the
% currents relate to a desired position during the magnetic transport.
%
% splines - 1x20 structure array which is a spline fit, evalulate with ppval
% data    - 539x20 vector of calibration current

% Plot the curves, this logical is for debugging purposes
doPlot=1;

% position vector for horizontal transport
xH=0:1:365; 

% position vector for vertical transport
xV=366:539; 

% position vector for entirety of transport
x0=[xH xV]; 

% data for all the channels
data=zeros(length(xH)+length(xV),20);


%% Load the calirations

% Get the full directory of this file, it is assumed that the calibrations
% are in the local folder of this file
str=mfilename('fullpath');
[str,~,~]=fileparts(str);
str=[str filesep];


% Read the horizontal calibrations 
% (',' delimeter, row offset 0, column 1)
MPush = dlmread([str 'Hextra1coilPush.txt'],',',0,1);
MMOT = dlmread([str 'Hextra1coilMOT.txt'],',',0,1);
M3 = dlmread([str 'Hextra1coil3.txt'],',',0,1);
M4 = dlmread([str 'Hextra1coil4.txt'],',',0,1);
M5 = dlmread([str 'Hextra1coil5.txt'],',',0,1);
M6 = dlmread([str 'Hextra1coil6.txt'],',',0,1);
M7 = dlmread([str 'Hextra1coil7.txt'],',',0,1);
M8 = dlmread([str 'Hextra1coil8.txt'],',',0,1); 
M9 = dlmread([str 'Hextra1coil9.txt'],',',0,1);
M10 = dlmread([str 'Hextra1coil10.txt'],',',0,1);
M11 = dlmread([str 'Hextra1coil11.txt'],',',0,1);
M12 = dlmread([str 'Hextra1coil12.txt'],',',0,1);
MExtra = dlmread([str 'Hextra1coilextra.txt'],',',0,1);

%vertical points to spline
M12A = dlmread([str 'rev45coil1.txt'],',',0,1);
M12B = dlmread([str 'rev45coil2.txt'],',',0,1);
M13 = dlmread([str  'rev45coil3.txt'],',',0,1);
M14 = dlmread([str  'rev45coil4.txt'],',',0,1);
M15 = dlmread([str  'rev45coil5.txt'],',',0,1);
M16 = dlmread([str  'rev45coil6.txt'],',',0,1);

%vertical fill
M17 = dlmread([str 'rev45coilpushfill.txt'],',',0,2);
M18 = dlmread([str 'rev45coilMOTfill.txt'],',',0,2);

%% Stitch the data together and make splines
% A loop is not used to leave it open to customize the spline and
% calibration for each channel.

% Coil 1 : PUSH COIL
Y=[MPush xV*0];
data(:,1)=Y;
splines(1)=spline(x0,Y);
strs{1}='Push Coil';

% Coil 2 : MOT COIL
Y=[MMOT xV*0];
data(:,2)=Y;
splines(2)=splinefit(x0,Y,250);
strs{2}='MOT Coil';

% Coil 3
Y=[M3 xV*0];
data(:,3)=Y;
splines(3)=spline(x0,Y);
strs{3}='Coil 3';

% Coil 4
Y=[M4 xV*0];
data(:,4)=Y;
splines(4)=spline(x0,Y);
strs{4}='Coil 4';

% Coil 5
Y=[M5 xV*0];
data(:,5)=Y;
splines(5)=spline(x0,Y);
strs{5}='Coil 5';

% Coil 6
Y=[M6 xV*0];
data(:,6)=Y;
splines(6)=spline(x0,Y);
strs{6}='Coil 6';

% Coil 7
Y=[M7 xV*0];
data(:,7)=Y;
splines(7)=spline(x0,Y);
strs{7}='Coil 7';

% Coil 8
Y=[M8 xV*0];
data(:,8)=Y;
splines(8)=spline(x0,Y);
strs{8}='Coil 8';

% Coil 9
Y=[M9 xV*0];
data(:,9)=Y;
splines(9)=spline(x0,Y);
strs{9}='Coil 9';

% Coil 10
Y=[M10 xV*0];
data(:,10)=Y;
splines(10)=spline(x0,Y);
strs{10}='Coil 10';

% Coil 11
Y=[M11 xV*0];
data(:,11)=Y;
splines(11)=spline(x0,Y);
strs{11}='Coil 11';

% Coil Extra
Y=[MExtra xV*0];
data(:,12)=Y;
splines(12)=spline(x0,Y);
strs{12}='Coil Extra';

% Vertical now

% Coil 12A
Y=[M12 -M12A];
data(:,13)=Y;
splines(13)=spline(x0,Y);
strs{13}='Coil 12A';

% Coil 12B
Y=[M12 M12B];
data(:,14)=Y;
splines(14)=spline(x0,Y);
strs{14}='Coil 12B';

% Coil 13
Y=[xH*0 M13];
data(:,15)=Y;
splines(15)=spline(x0,Y);
strs{15}='Coil 13';

% Coil 14
Y=[xH*0 M14];
data(:,16)=Y;
splines(16)=spline(x0,Y);
strs{16}='Coil 14';

% Coil 15
Y=[xH*0 M15];
data(:,17)=Y;
splines(17)=spline(x0,Y);
strs{17}='Coil 15';

% Coil 16
Y=[xH*0 M16];
data(:,18)=Y;
splines(18)=spline(x0,Y);
strs{18}='Coil 16';

% I don't believe the experiment uses these (CF 2020/07);

% Push fill current
Y=[xH*0 26 1.2*M17];
data(:,19)=Y;
splines(19)=spline(x0,Y);
strs{19}='Push Fill';

% MOT fill current
Y=[xH*0 18.5 1.2*M18];
data(:,20)=Y;
splines(20)=spline(x0,Y);
strs{20}='MOT Fill';

%% Debug options
if doPlot
    % Don't plot channels 19 and 20 because I dont think we use those
    % Make a color map
    cmap=hsv(18);
    cmap = distinguishable_colors(18);

    % Close the old calibration figure if you plotted it
    fname='TransportCalibrationRaw';    
    fh = findobj( 'Type', 'Figure', 'Name', fname);
    close(fh)

    hF=figure;
    hF.Color='w';
    hF.Position(3:4)=[800 400];
    hF.Name=fname;
    ax=axes;
    set(ax,'box','on','linewidth',1,'fontsize',14,'fontname','times');
    xlabel('position (mm)');
    ylabel('current (A)');
    hold on
    xlim([min(x0) max(x0)]);
    
    % Plot the data
    for kk=1:18
%        plot(x0,data(:,kk),'linewidth',2,'color',cmap(kk,:));      
      scatter(x0,data(:,kk),3,'o','markerfacecolor',cmap(kk,:),'linewidth',1,...
        'markeredgecolor',cmap(kk,:));
    end    
    
    % Make a legend
    legend(strs(1:18),'location','eastoutside','fontsize',10)
    title('raw calibrations');
end

end


function colors = distinguishable_colors(n_colors,bg,func)
% DISTINGUISHABLE_COLORS: pick colors that are maximally perceptually distinct
%
% When plotting a set of lines, you may want to distinguish them by color.
% By default, Matlab chooses a small set of colors and cycles among them,
% and so if you have more than a few lines there will be confusion about
% which line is which. To fix this problem, one would want to be able to
% pick a much larger set of distinct colors, where the number of colors
% equals or exceeds the number of lines you want to plot. Because our
% ability to distinguish among colors has limits, one should choose these
% colors to be "maximally perceptually distinguishable."
%
% This function generates a set of colors which are distinguishable
% by reference to the "Lab" color space, which more closely matches
% human color perception than RGB. Given an initial large list of possible
% colors, it iteratively chooses the entry in the list that is farthest (in
% Lab space) from all previously-chosen entries. While this "greedy"
% algorithm does not yield a global maximum, it is simple and efficient.
% Moreover, the sequence of colors is consistent no matter how many you
% request, which facilitates the users' ability to learn the color order
% and avoids major changes in the appearance of plots when adding or
% removing lines.
%
% Syntax:
%   colors = distinguishable_colors(n_colors)
% Specify the number of colors you want as a scalar, n_colors. This will
% generate an n_colors-by-3 matrix, each row representing an RGB
% color triple. If you don't precisely know how many you will need in
% advance, there is no harm (other than execution time) in specifying
% slightly more than you think you will need.
%
%   colors = distinguishable_colors(n_colors,bg)
% This syntax allows you to specify the background color, to make sure that
% your colors are also distinguishable from the background. Default value
% is white. bg may be specified as an RGB triple or as one of the standard
% "ColorSpec" strings. You can even specify multiple colors:
%     bg = {'w','k'}
% or
%     bg = [1 1 1; 0 0 0]
% will only produce colors that are distinguishable from both white and
% black.
%
%   colors = distinguishable_colors(n_colors,bg,rgb2labfunc)
% By default, distinguishable_colors uses the image processing toolbox's
% color conversion functions makecform and applycform. Alternatively, you
% can supply your own color conversion function.
%
% Example:
%   c = distinguishable_colors(25);
%   figure
%   image(reshape(c,[1 size(c)]))
%
% Example using the file exchange's 'colorspace':
%   func = @(x) colorspace('RGB->Lab',x);
%   c = distinguishable_colors(25,'w',func);
% Copyright 2010-2011 by Timothy E. Holy
  % Parse the inputs
  if (nargin < 2)
    bg = [1 1 1];  % default white background
  else
    if iscell(bg)
      % User specified a list of colors as a cell aray
      bgc = bg;
      for i = 1:length(bgc)
	bgc{i} = parsecolor(bgc{i});
      end
      bg = cat(1,bgc{:});
    else
      % User specified a numeric array of colors (n-by-3)
      bg = parsecolor(bg);
    end
  end
  
  % Generate a sizable number of RGB triples. This represents our space of
  % possible choices. By starting in RGB space, we ensure that all of the
  % colors can be generated by the monitor.
  n_grid = 30;  % number of grid divisions along each axis in RGB space
  x = linspace(0,1,n_grid);
  [R,G,B] = ndgrid(x,x,x);
  rgb = [R(:) G(:) B(:)];
  if (n_colors > size(rgb,1)/3)
    error('You can''t readily distinguish that many colors');
  end
  
  % Convert to Lab color space, which more closely represents human
  % perception
  if (nargin > 2)
    lab = func(rgb);
    bglab = func(bg);
  else
    C = makecform('srgb2lab');
    lab = applycform(rgb,C);
    bglab = applycform(bg,C);
  end
  % If the user specified multiple background colors, compute distances
  % from the candidate colors to the background colors
  mindist2 = inf(size(rgb,1),1);
  for i = 1:size(bglab,1)-1
    dX = bsxfun(@minus,lab,bglab(i,:)); % displacement all colors from bg
    dist2 = sum(dX.^2,2);  % square distance
    mindist2 = min(dist2,mindist2);  % dist2 to closest previously-chosen color
  end
  
  % Iteratively pick the color that maximizes the distance to the nearest
  % already-picked color
  colors = zeros(n_colors,3);
  lastlab = bglab(end,:);   % initialize by making the "previous" color equal to background
  for i = 1:n_colors
    dX = bsxfun(@minus,lab,lastlab); % displacement of last from all colors on list
    dist2 = sum(dX.^2,2);  % square distance
    mindist2 = min(dist2,mindist2);  % dist2 to closest previously-chosen color
    [~,index] = max(mindist2);  % find the entry farthest from all previously-chosen colors
    colors(i,:) = rgb(index,:);  % save for output
    lastlab = lab(index,:);  % prepare for next iteration
  end
end
function c = parsecolor(s)
  if ischar(s)
    c = colorstr2rgb(s);
  elseif isnumeric(s) && size(s,2) == 3
    c = s;
  else
    error('MATLAB:InvalidColorSpec','Color specification cannot be parsed.');
  end
end
function c = colorstr2rgb(c)
  % Convert a color string to an RGB value.
  % This is cribbed from Matlab's whitebg function.
  % Why don't they make this a stand-alone function?
  rgbspec = [1 0 0;0 1 0;0 0 1;1 1 1;0 1 1;1 0 1;1 1 0;0 0 0];
  cspec = 'rgbwcmyk';
  k = find(cspec==c(1));
  if isempty(k)
    error('MATLAB:InvalidColorString','Unknown color string.');
  end
  if k~=3 || length(c)==1,
    c = rgbspec(k,:);
  elseif length(c)>2,
    if strcmpi(c(1:3),'bla')
      c = [0 0 0];
    elseif strcmpi(c(1:3),'blu')
      c = [0 0 1];
    else
      error('MATLAB:UnknownColorString', 'Unknown color string.');
    end
  end
end



