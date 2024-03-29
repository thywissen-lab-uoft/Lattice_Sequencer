fid1 = fopen('C:\Users\User\Desktop\Rhys\Lab Related\Programs\Lattice_Sequencer\Sequence Files\Load Magtrap Sequence Files\Sequence Parameters\Absorption_Imaging_Flags.txt');
fid2 = fopen('C:\Users\User\Desktop\Rhys\Lab Related\Programs\Lattice_Sequencer\Sequence Files\Load Magtrap Sequence Files\Sequence Parameters\Absorption_Imaging_Parameters.txt');
%%Using textscan function to read all the lines in the file to a cell array
Absorption_Flags_Array = textscan(fid1, '%30s %u', 'delimiter', ':');
Absorption_Parameters_Array = textscan(fid2, '%30s %d', 'delimiter', ':');
%%Closing the files
fclose(fid1);
fclose(fid2);
%%Add to a seqdata structure
seqdata.flags.absorption_imaging_flags = cell2struct(num2cell(Absorption_Flags_Array{2}), Absorption_Flags_Array{1}, 1);
seqdata.parameters.absorption_imaging_parameters = cell2struct(num2cell(Absorption_Parameters_Array{2}), Absorption_Parameters_Array{1}, 1);