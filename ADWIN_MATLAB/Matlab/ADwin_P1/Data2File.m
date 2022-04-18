function y = Data2File(Filename, DataNo, Startindex, Count, Mode)
%Data2File  saves data from a DATA array of the ADwin system into a file (on
%  the hard disk).
%
%  Syntax:  Data2File (Filename, DataNo, Startindex, Count, Mode)
%
%  Parameters:
%    Filename        Path and file name. If no path is indicated, the file is
%                    saved in the project directory.
%    DataNo          Number (1...200) of the source array DATA_1 ... DATA_200.
%    Startindex      Number (>=1) of the first element in the source array to
%                    be transferred.
%    Count           Number (>=1) of the first data to be transferred.
%    Mode            Write mode:
%                    0: File will be overwritten.
%                    1: Data is appended to an existing file.
%    Return value    0: OK
%                    <>0: Error
%
%  Notes:
%    The DATA array must not be defined as FIFO.
%    The data are saved as binary file. If not existing, the file will be
%    created. 
%
%  Example:
%    %Save elements 1...1000 from the ADbasic array DATA_1 into the file
%    %<C:\Test.dat>:
%    Data2File('C:\Test.dat', 1, 1, 1000, 0)
%
%  See also  GETDATA_DOUBLE, SETDATA_DOUBLE, GETFIFO_DOUBLE, SETFIFO_DOUBLE, FIFO_FULL, FIFO_EMPTY, FIFO_CLEAR.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

if (Mode == 0)
   y=ADlab(120, Filename, DataNo, Count, Startindex);
else
	y=ADlab(121, Filename, DataNo, Count, Startindex);
end


