function [deltat,increment] = vlb_find(midi)
    % A function to parse out the variable length delta time codes
    % This function is only fed 10 characters of the full midi file because
    % VLB code cannot be longer than 5 bytes.
    
    i = 1; % we start by looking at the first value
    del = ''; % accumulator 
    while 1
        vlb = midi(i); % extracting first byte
        i = i + 1; % incrementing
        binnum = dec2bin(vlb, 8); % 8 bit binary number of byte
        del = strcat(del, binnum(2:end)); % adding binary number sans continuation bit
        if vlb < 128 % checking if continuation bit is 1
            break % ending loop
        end
    end
    deltat = bin2dec(del); % dec value of full vlb
    increment = i-1; % a little bookkeeping, tells main function to incrememnt the pointer by this amount
end

