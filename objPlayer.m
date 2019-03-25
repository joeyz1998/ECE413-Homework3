% this is an object whose only parameter is an array of notes. This is used
% because the objSynth expects to recieve an object, like ObjChord or
% ObjScale that contains an array of notes. This is merely a formality to
% be compatable with existing code

classdef objPlayer
    properties
        arrayNotes = objNote.empty;
    end
    
    methods
        function obj = objPlayer(song)
            
            for i = 1:size(song,1)
                obj.arrayNotes(i) = objNote(song(i,1),song(i,2),song(i,3),song(i,4),song(i,5),song(i,6),song(i,8));
                % again, the song matrix is organized as follows,
                % [ Note number, temperament, key, start time, end time, amp, track_num ]
                % track_num isn't used for the note object, it's merely a
                % debugging tool for the main midi_decoder object
            end
        end
    end
end
