b=Num;        % make column

% Q15 scaling
q15 = round(b * 2^15);

% Saturate to int16 range
q15(q15 >  32767) =  32767;
q15(q15 < -32768) = -32768;

% Convert to uint16 for proper two’s-complement hex
q15_u = uint16(typecast(int16(q15),'uint16'));

% Convert to hex strings
hexStr = upper(dec2hex(q15_u,4));

% Save to text file
fid = fopen('coeff_q15_hex.txt','w');
for k = 1:length(hexStr)
    fprintf(fid,'16''h%s\n',hexStr(k,:));
end
fclose(fid);
