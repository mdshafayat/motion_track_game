
function serial_send (data_to_send)
global sr
%data_to_send= matrix to be sent

% fwrite(sr,char(data_to_send),'async');
% sr.ValuesSent

fprintf(sr,'%s', data_to_send);
end


