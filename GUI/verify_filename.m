function is_valid = verify_filename(my_string)
% Verify if string can be a filename.
% In windows (for example), some characters are forbiden like ? or /.
%
% Inputs:
%   -my_string (1,1) string     % the string to be verify
%
% Outputs:
%   -is_valid (1,1) boolean     % true if  it can be a filename.
arguments
        my_string (1,1) string
end
temp = tempname;
mkdir(temp);
tp_filename = fullfile(temp, my_string);
try
    fileID = fopen(tp_filename, 'w');
    fclose(fileID);
%     isfile(tp_filename)
    is_valid = true;
    delete(tp_filename)
    rmdir(temp)
catch ME
    if (strcmp(ME.identifier,'MATLAB:FileIO:InvalidFid'))
    is_valid = false;
    rmdir(temp)
    else
        error('opt:verify_filename', 'Bad identification of error.')
    end
end
