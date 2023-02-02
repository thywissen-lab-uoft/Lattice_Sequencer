function makeControlFile        
global seqdata

    tExecute=now;
    seqdata.outputfilepath=seqdata.compath;
    filenametxt = fullfile(seqdata.outputfilepath, 'control.txt');
    filenamemat=fullfile(seqdata.outputfilepath, 'control.mat');  
    filenamemat2=fullfile(seqdata.outputfilepath, 'control2.mat');          

    disp(['Saving sequence parameters to ' seqdata.outputfilepath filesep 'control']);
    [path,~,~] = fileparts(filenametxt);

    % If the location of the control file doesnt exist, make it
    if ~exist(path,'dir')
        try
            mkdir(path);
        catch 
            warning('Unable to create output file location');
        end
    end        
    [fid,~]=fopen(filenametxt,'wt+'); % open file, overrite permission, discard old
    %output the header (date/time,function handle,cycle)
    fprintf(fid,'Lattice Sequencer Output Parameters \n');
    fprintf(fid,'------------------------------------\n');
    fprintf(fid,'Execution Date: %s \n',datestr(tExecute));
    fprintf(fid,'Function Handle: %s \n',erase(eSeq.String,'@'));
    fprintf(fid,'Cycle: %g \n', seqdata.cycle);
    fprintf(fid,'------------------------------------\n');    


    %output the parameters
    if ~isempty(seqdata.outputparams)
        for n = 1:length(seqdata.outputparams)
            %the first element is a string and the second element is a number
            fprintf(fid,'%s: %d \n',seqdata.outputparams{n}{1},seqdata.outputparams{n}{2});
        end
    end
    fclose(fid);     % close the file   
    %% Making a mat file with the parameters
    outparams=struct;       
    for kk=1:length(seqdata.outputparams)
        a=seqdata.outputparams{kk};
        outparams.(a{1})=a{2};
    end        
    assignin('base','seqparams',outparams)

    params=seqdata.params;        
    % output both outparams and params
    save(filenamemat,'outparams','params');        
    %% Save new output mat
    try
    vals=seqdata.output_vars_vals;
    units=seqdata.output_vars_units;        
    flags=seqdata.flags;

    vals.ExecutionDateStr=datestr(tExecute);        
    units.ExecutionDateStr='str';

    vals.ExecutionDate=tExecute;        
    units.ExecutionDate='days';

    save(filenamemat2,'vals','units','flags');        
    end
    
end