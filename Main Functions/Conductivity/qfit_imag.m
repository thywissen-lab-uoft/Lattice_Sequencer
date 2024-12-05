function sigma = qfit_imag(T,G,w)
    
    global Rvalues;
    global energies; %Joules
    
    hbar = 6.626e-34/(2*pi);
    kb = 1.380649e-23;
    aL = 527e-9;
    beta = 1/(kb*T);

    Z = sum(exp(-beta*energies)); %Partition function

    ss = 0;
    for loop1 = 1:length(Rvalues)
        for loop2 = 1:length(Rvalues)
            ss = ss + (abs(Rvalues(loop1,loop2))^2).*(w - (energies(loop1)-energies(loop2))/hbar).*(exp(-beta*energies(loop1))-exp(-beta*energies(loop2)))./((w - (energies(loop1)-energies(loop2))/hbar).^2 + (G/2).^2);
        end
    end

    sigma = -(1/Z)*(1/(aL^2)).*w.*ss;

end