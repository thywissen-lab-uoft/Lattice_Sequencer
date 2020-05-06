function test4()
global seqdata;
global sortedlist;
if isfield(seqdata,'multiscannum'); seqdata = rmfield(seqdata,'multiscannum'); end
if isfield(seqdata,'multiscanlist'); seqdata = rmfield(seqdata,'multiscanlist'); end

start_new_sequence()
for jj=1:15
    
cycle = jj;
repeatnum = 1;
randlist = [3 2 1];
lista = [1 2 3];
listb = [4 5 6];
listc = [7 8 9];

a =getmultiScanParameter(lista,cycle,'a',1,3);
b =getmultiScanParameter(listb,cycle,'b',1,2);
c =getmultiScanParameter(listc,cycle,'c',1,1);
fprintf('a = %g,b=%g,c=%g, lenthg   =======%g\n',a,b,c,length(seqdata.multiscannum))
end
% seqdata.multiscanlist{1}
% seqdata.multiscanlist{2}
% seqdata.multiscanlist{3}
% seqdata.multiscanlist{4}


end