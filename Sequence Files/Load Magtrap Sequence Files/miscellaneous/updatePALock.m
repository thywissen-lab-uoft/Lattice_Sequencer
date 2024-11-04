function updatePALock(curtime)

    logNewSection('Updating PA Request',curtime);

    % K D2 line
    PA_resonance = 391016.821;

    % Scan randomly
%     PA_detuning = getScanParameter(PA_detuning_list, ...
%         seqdata.scancycle, seqdata.randcyclelist, 'PA_detuning','GHz');
    
    

    % Convert detuning into laser frequency
    PA_freq = PA_resonance + getVar('PA_detuning');
    PA_freq = round(PA_freq,6); % round to nearest kHz

    addOutputParam('PA_freq',PA_freq,'GHz');

    lockSetFileName ='Y:\wavemeter_amar\lock_freq.txt';

    isFreqUpdated = 0;

    updateTime=0;
    if exist(lockSetFileName)    
        disp(['writing PA freq to file ' num2str(PA_freq,12)]);
        tic;
        while ~isFreqUpdated && updateTime<2    
            try
                [fileID,errmsg] = fopen(lockSetFileName,'w');
                if ~isequal(fileID,-1)
                   fprintf(fileID,'%s',num2str(PA_freq,12)); 
                end
                fclose(fileID);
                text = fileread(lockSetFileName);
                textNum = str2num(text);
                disp(textNum);
                if isequal(textNum,PA_freq)
                    isFreqUpdated = 1;
                    disp('Written frequency is the same as the text file');
                end
                disp(updateTime)
                updateTime = toc;
            end
        end
        if updateTime>=2
           warning('may have not updated the frequency'); 
        end
        disp('--------------------');
    end
end

