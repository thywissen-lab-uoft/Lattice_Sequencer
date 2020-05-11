function timeout = lattice_flags(varargin)
global seqdata;
timein = varargin{1};
seqdata.flags.lattice = struct('Raman_transfers',1)
% seqdata.flags.lattice.Raman_transfers = 0
timeout = timein;

end
