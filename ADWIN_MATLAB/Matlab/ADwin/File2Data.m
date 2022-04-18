%File2Data  copies data from a file (on the hard disk) into a DATA array of the
%  ADwin system.
%
%  Syntax:   File2Data (Filename, DataType, DataNo, Startindex)
%
%  Parameters:
%    Filename        Pointer to path and source file name. If no path is
%                    indicated, the file is searched for in the project
%                    directory.
%    DataType        Data type of the values saved in the file. Select one of
%                    the following contants:
%                    'type_integer' : Values of type int32 (32 bit).
%                    'type_single' : Values of type single (32 bit).
%                    'type_double' : Values of type double (64 bit).
%    DataNo          Number (1...200) of the destination array DATA_1 ...
%                    DATA_200.
%    Startindex      Index (>=1) of the first element in the destination array
%                    to be written.
%    Return value    0: OK
%                    <>0: Error
%
%  Notes:
%    The file values are expected to be saved as binary in one of the formats
%    int32, single or double.
%    The DATA array must not be defined as FIFO. The array must be dimensioned
%    great enough to hold all values of the file.
%    If required, the values of the source file are automatically converted into
%    the data type of the destination DATA array. There are the destination data
%    types Long, Float/Float32, and Float64 (see table).
%    Saved data type             Data type of DATA array
%    int32                       Long
%    single                      Float (until processor T11)
%                                Float32 (processor T12/T12.1) 
%    double                      Float64 (processor T12/T12.1)
%
%  Example:
%    %In ADbasic, DATA_1 is dimensioned as:
%    DIM DATA_1[1000] AS LONG
%    
%    %In Matlab:Copy values of type integer from file <Test.dat> in the project
%    %direcory into the ADbasic array DATA_1, starting from element DATA_1[20].
%    %The file may contain up to 980 values as to not exceed the DATA_1 array
%    %size.
%    ret_val = File2Data('Test.dat', 'type_integer', 1, 20);
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
