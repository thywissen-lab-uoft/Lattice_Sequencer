%------
%Author: Stefan Trotzky
%Created: November 2013
%Summary: This function saves the sequence data in a communications folder
%------
function ThrowSequenceData(s)

    ComPath = 'Z:\Experiments\Lattice\_communication';
        
    if exist(ComPath,'dir')
        
        % if file currseq.mat exists in path, move content over to
        % lastseq.mat
        if exist([ComPath '\currseq.mat'],'file')
            p = load([ComPath '\currseq.mat']);
            if isfield(p,'seqdata');
                seqdata = p.seqdata;
                save([ComPath '\lastseq.mat'],'seqdata')
            end
        end
        
        % save current sequence data in currseq.mat
        seqdata=s;
        save([ComPath '\currseq.mat'],'seqdata')
        
    else
        
        disp(['Warning: Could not access communication directory ' ComPath '.'])
        
    end
end