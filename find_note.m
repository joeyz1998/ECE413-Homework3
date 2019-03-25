function [index] = find_note(song, note_num, chan)
    % function for finding a note that has been turned on, but hasn't been
    % turned off. It loops through the song matrix in reverse order, and
    % looks for a note of matching midi number, for which the 5 element,
    % the end time, is 0, or unset. 
    index = size(song,1);
    for i = size(song,1):-1:1
        if song(i, 1) == note_num
            if (song(i,5) == 0) && (song(i,7) == chan)
                index = i;
                break
            end
        end
    end
end

