function tExecute=makeControlFile        
    global seqdata

    if ~isfield(seqdata,'flags')
       seqdata.flags = struct; 
    end
    
%% Make directory of communication if it doesn't eixt
    % If the location of the control file doesnt exist, make it
    if ~exist(seqdata.compath,'dir')
        try
            mkdir(seqdata.compath);
        catch 
            warning('Unable to create output file location');
        end
    end      
    
    %% Save new output mat
    tExecute=now;
    filenamemat2=fullfile(seqdata.compath, 'control2.mat');         
    
    vals=seqdata.output_vars_vals;
    units=seqdata.output_vars_units;        
    flags=seqdata.flags;

    vals.ExecutionDateStr=datestr(tExecute);        
    units.ExecutionDateStr='str';

    vals.ExecutionDate=tExecute;        
    units.ExecutionDate='days';

    save(filenamemat2,'vals','units','flags');            
    
    %% Save Camera Control Files
    
    if isfield(seqdata,'CameraControl') && isfield(seqdata,'camera_control_file')
        CameraControl = seqdata.CameraControl;
        save(seqdata.camera_control_file,'-struct','CameraControl');            
    end
    
end