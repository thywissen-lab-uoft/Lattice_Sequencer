%------
%Author: David McKay
%Created: July 2009
%Summary: Start a new sequence (clear all the old sequence data)
%------

function start_new_sequence()

global seqdata;

%clear all the old lists
seqdata.analogadwinlist = [];
seqdata.digadwinlist = [];
seqdata.updatelist = [];
seqdata.chval = [];
seqdata.chnum = [];
seqdata.seqcalculated = 0;
seqdata.seqloaded = 0;
seqdata.outputparams = [];
seqdata.params.analogch = [];
seqdata.params.digitalch = [];
seqdata.ramptimes = [];
seqdata.compath='Y:\_communication';
seqdata.camera_control_file = 'Y:\_communication\camera_control.mat';
seqdata.analysis_summary_file = 'Y:\_communication\pco_analysis_summary.mat';


% seqdata.multiscannum = [];%Feb-2017
if isfield(seqdata,'times'); seqdata = rmfield(seqdata,'times'); end
if isfield(seqdata,'flags'); seqdata = rmfield(seqdata,'flags'); end
if isfield(seqdata,'scopetriggers'); seqdata = rmfield(seqdata,'scopetriggers'); end
if isfield(seqdata,'gpib'); seqdata = rmfield(seqdata,'gpib'); end
if isfield(seqdata,'visa'); seqdata = rmfield(seqdata,'visa'); end
if isfield(seqdata,'sortedgpibvisadata');seqdata = rmfield(seqdata,'sortedgpibvisadata');end%Feb-2017
if isfield(seqdata,'coil_enable'); seqdata = rmfield(seqdata,'coil_enable'); end


% if ~isfield(seqdata,'doscan'); seqdata.doscan = 0; end
% if ~seqdata.doscan; seqdata.scancycle = 1; end

end