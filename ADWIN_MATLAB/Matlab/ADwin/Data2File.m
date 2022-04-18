%Data2File  saves data of type Long, Float/Float32, or Float64 from a DATA array
%  of the ADwin system into a file (on the hard disk).
%
%  Syntax:  Data2File (Filename, DataNo, Startindex, Count, Mode)
%
%  Parameters:
%    Filename        Path and file name. If no path is indicated, the file is
%                    saved in the project directory.
%    DataNo          Number (1...200) of the source array DATA_1 ... DATA_200.
%    Startindex      Number (>=1) of the first element in the source array to be
%                    transferred.
%    Count           Number (>=1) of the first data to be transferred.
%    Mode            Write mode:
%                    0: File will be overwritten.
%                    1: Data is appended to an existing file.
%    Return value    0: OK
%                    <>0: Error
%
%  Notes:
%    The DATA array must not be defined as FIFO.
%    The data are saved as binary file in the appropriate MATLAB data type (see
%    table). If not existing, the file will be created. 
%    Data type of DATA array                       Saved data type
%    Long                                          int32
%    Float (until processor T11)                   single
%    Float64 (Prozessor T12/T12.1)                 double
%
%  Example:
%    %Save elements 1...1000 from the ADbasic array DATA_1 into the file
%    %<C:\Test.dat>:
%    Data2File('C:\Test.dat', 1, 1, 1000, 0);
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
