%------
%Author: David McKay
%Created: July 2009
%Summary: create the output parameters file
%------

function CreateOutputParamFile(outfilename,funcstr)

global seqdata;

%output the parameters to the command prompt
fprintf(1,'--Lattice Sequencer Output Parameters-- \n');
if ~isempty(seqdata.outputparams)
    for i = 1:length(seqdata.outputparams)
        %the first element is a string and the second element is a number
        fprintf(1,'%s: %g \n',seqdata.outputparams{i}{1},seqdata.outputparams{i}{2});
    end
end
fprintf(1,'----------------------------------------\n');

%if no path is specified do not create the file
if isempty(seqdata.outputfilepath) || ~seqdata.createoutfile
    return;
end

filename = fullfile(seqdata.outputfilepath, 'control.txt');

karl_output_style = 0;

if karl_output_style

    %if the file doesn't exist create a new file, if it does append to the
    %existing file
    fid = fopen(filename,'wt');
    
    if fid==-1
        error('Could not write to parameter file');
    end
    
    %print the scan parameter, default as the first variable in the output
    %parameter array
    if isempty(seqdata.outputparams)
        error('Cannot output scan file, no parameters selected');
    end
    
    fprintf(fid,'TimeControl\t%s\tDateControl\t%s\tScanParameter\t%f',datestr(now,13),datestr(now,'mm-dd-yyyy'),seqdata.outputparams{1}{2});
    
    %close
    fclose(fid);    
    
else
    
    %Create the filename. If the filename already exists append a number.
%     i = 0;
%     while (1)
%         if i==0
%             filename = fullfile(seqdata.outputfilepath, [outfilename '.txt']);
%         else
%             filename = fullfile(seqdata.outputfilepath, [outfilename ' (' num2str(i) ').txt']);
%         end
%         if ~exist(filename,'file')
%             break;
%         end
%         i = i+1;
%     end
    
    %create the file, overwrite existing file
    [path,name,ext] = fileparts(filename);
    if exist(path,'dir')
        fid = fopen(filename,'wt');

        if fid==-1
            buildWarning('CreateOutputParamFile','Could not write to parameter file!! Make sure that Z: is connected and logged into. Camera programms will likely receive old parameters!!!',0);
        end
    else
        buildWarning('CreateOutputParamFile','Could not write to parameter file!! Make sure that Z: is connected and logged into. Camera programms will likely receive old parameters!!!',0);
    end

    %output the header (date/time,function handle,cycle)
    fprintf(fid,'Lattice Sequencer Output Parameters \n');
    fprintf(fid,'------------------------------------\n');
    fprintf(fid,'Execution Date: %s \n',datestr(now));
    fprintf(fid,'Function Handle: %s \n',funcstr);
    fprintf(fid,'Cycle: %g \n', seqdata.cycle);
    fprintf(fid,'------------------------------------\n');


    %output the parameters
    if ~isempty(seqdata.outputparams)
        for i = 1:length(seqdata.outputparams)
            %the first element is a string and the second element is a number
            fprintf(fid,'%s: %d \n',seqdata.outputparams{i}{1},seqdata.outputparams{i}{2});
        end
    end

    %close the file
    fclose(fid);
end

end