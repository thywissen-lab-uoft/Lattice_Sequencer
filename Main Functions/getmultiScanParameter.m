function out = getmultiScanParameter(scanlist,cycle,name,repeatnum,scanorder)
%------------------------------------------------------------- 
%   Fudong Wang, Feb-2017
%   multiple scan lists 
%   out = getmultiScanParameter(scanlist,cycle,name,repeatnum, scanorder)
%   scanorder determines  the scan-order of the scanlists
%   based on previous version. see below
%-------------------------------------------------------------  
%   out = getScanParameter(scanlist,cycle,randlist)
%
%   typical usage:
%   par_list = [1:10];
%   par = getScanParameter(par_list, seqdata.scancycle, seqdata.randcyclelist, 'par')
%
%   Picks a parameter from a #scanlist for a given #cycle in a scan. A
%   #randlist may be specified that contains a randomized order of scanlist
%   indices. Will restart iteration when #cycle > length(#scanlist). Set
%   randlist to 0 for non-randomized scans.
%   -- S. Trotzky, March 2014
%-------------------------------------------------------------
    global seqdata;
    
    if (nargin < 5)
        error('error: too few arguments!');
    end
    
    %1st cycle of this run, find out the number of random list
    if(length(scanlist) == 1)
        out = scanlist(1);
    end
    
    if(length(scanlist)*repeatnum > 1) 
        %Creates a cell array containing all parameters to be scanned and
        %their values. Indexes based on scanorder parameter, and adds to
        %the global variable seqdata.multiscanlist.
        if (cycle == 1)
            if isfield(seqdata,'multiscanlist')
                if (length(seqdata.multiscanlist) >= scanorder)
                    if (length(seqdata.multiscanlist{scanorder}) > 0)
                        %if the "scanorder" has been defined before,error
                        error('error: conflicting scanorder-s are defined in getmultiScanParameter(...)')
                    end
                end
            end
            
            seqdata.multiscannum{scanorder} = [length(scanlist)*repeatnum,1];
            final=[];
            for jj=1:repeatnum
                temprandomlist = rand(1,length(scanlist));
                [void, temprandomlist] = sort(temprandomlist);
                final((jj-1)*length(scanlist)+1:jj*length(scanlist)) = scanlist(temprandomlist);
            end 
            seqdata.multiscanlist{scanorder} ={name, final};
            out = seqdata.multiscanlist{scanorder}{2}(1);            
        end
        
       
        if (cycle>1)
            multiscannumtemp = zeros(length(seqdata.multiscannum),2);
            for ii =1:length(seqdata.multiscannum)
                multiscannumtemp(ii,:)=seqdata.multiscannum{ii};
            end
            if (1+ mod(cycle-1, prod(multiscannumtemp(:,1)))==1)
                for ii=1:length(seqdata.multiscannum)
                    seqdata.multiscannum{ii}(2)=1;
                    multiscannumtemp(ii,:)=seqdata.multiscannum{ii};
                end
            end
            
           for jj=1:length(seqdata.multiscannum)
               if (1+mod(cycle-1, prod(multiscannumtemp(1:jj,1)))==1)
                   if (seqdata.multiscanlist{jj}{1}==name) 
                       if (multiscannumtemp(jj,2)==1)
                           seqdata.multiscannum{jj} = [length(scanlist)*repeatnum , 0];
                           multiscannumtemp(jj,:) = [length(scanlist)*repeatnum , 0];
                           final=[];
                           for ii=1:repeatnum
                                temprandomlist = rand(1,length(scanlist));
                                [void, temprandomlist] = sort(temprandomlist);
                                final((ii-1)*length(scanlist)+1:ii*length(scanlist)) = scanlist(temprandomlist);
                           end %for jj=1:repeatnum
                           seqdata.multiscanlist{jj} ={name, final};
                           fprintf('load new list, ------------%s,new list length = %d\n\n\n\n\n\n\n\n',name,seqdata.multiscannum{jj}(1));
                       end%if (multiscannumtemp(jj,2)==1)
                   end%if (seqdata.multiscanlist{jj,1}==name)
               end%if(mod(cycle), prod(seqdata.multiscannum(1:curind-1))==1)
           end%for jj=1:length(seqdata.multiscannum)
        end%(cycle>1)   
        
        if (cycle > 1)
            for jj=1:length(seqdata.multiscannum)
               if(seqdata.multiscanlist{jj}{1} == name) 
                  curind = jj; 
               end
            end

            modnum = seqdata.multiscannum{curind}(1);
            if (curind ==1)
                modnum = seqdata.multiscannum{curind}(1);
                index = 1 + mod(cycle-1,modnum);
            else
                roundnum = prod(multiscannumtemp(1:curind-1,1));
                index = 1+mod(floor((cycle-1)/roundnum)+1-1,modnum);
            end

            out = seqdata.multiscanlist{curind}{2}(index);
        end
    end
    addOutputParam(name,out); % write automatically to output parameters

end