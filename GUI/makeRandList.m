function randcyclelist = makeRandList
    disp('Reseeding random list');
    Nmax = 1e4;
    randcyclelist=uint16(randperm(Nmax))';   
end