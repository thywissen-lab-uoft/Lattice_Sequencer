function batchStop
global batch_listener

disp('Stopping batch run');
delete(batch_listener);

end

