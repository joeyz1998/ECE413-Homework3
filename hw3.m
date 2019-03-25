% MIDI Decoder
% Daniel Zuerbig

close all; clc; clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
constants                              = confConstants;
constants.BufferSize                   = 882;                                                
constants.SamplingRate                 = 44100;                                                  
constants.QueueDuration                = 0.1;                                                    
constants.TimePerBuffer                = constants.BufferSize / constants.SamplingRate;

oscParams                              =confOsc;
oscParams.oscType                      = 'sine';
oscParams.oscAmpEnv.StartPoint         = 0;
oscParams.oscAmpEnv.ReleasePoint       = Inf;   % Time to release the note
oscParams.oscAmpEnv.AttackTime         = .02;  % Attack time in seconds
oscParams.oscAmpEnv.DecayTime          = .01;  % Decay time in seconds
oscParams.oscAmpEnv.SustainLevel       = 0.6;  % Sustain level
oscParams.oscAmpEnv.ReleaseTime        = .05;  % Time to release from sustain to zero
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

choice = menu('Pick a song',...
    'Row your boat',...
    'Mario',...
    'Furelise',...
    'Sugar Plum Fairy',...
    'Russian Dance, Trepak',...
    'Chinese Dance, Tea',...
    'Reed Dance',...
    'Arabian Dance',...
    'Silent Night',...
    'Moonlight Sonata',...
    'Sonata 8',...
    'Chopin Prelude',...
    'Hyrule Field',...
    'Gerudo Valley',...
    'Sarias Song',...
    'Africa',...
    'Super Smash Bros Brawl',...
    'Other, for testing'...
    );

switch choice
    case 1
        file = fopen('midi/ROW.mid');
    case 2
        file = fopen('midi/mario.mid');
    case 3
        file = fopen('midi/furelise.mid');
    case 4
        file = fopen('midi/plum.mid');
    case 5
        file = fopen('midi/trepak.mid');
    case 6
        file = fopen('midi/tea.mid');
    case 7
        file = fopen('midi/reed_flute.mid');
    case 8
        file = fopen('midi/arabian.mid');
    case 9
        file = fopen('midi/silent.mid');
    case 10
        file = fopen('midi/moon.mid');
    case 11
        file = fopen('midi/sonata8.mid');
    case 12
        file = fopen('midi/chopin.mid');
    case 13
        file = fopen('midi/hyrule.mid');
    case 14
        file = fopen('midi/gerudo-valley.mid');
    case 15
        file = fopen('midi/saria.mid');
    case 16
        file = fopen('midi/africa.mid');
    case 17
        file = fopen('midi/brawl.mid');
    case 18
        file = fopen('midi/bach.mid'); % insert any file here and press button
    otherwise
end
mid = fread(file);
fclose(file);
% imports midi file, and turns it into a column vector of decimal values.
% Each decimal value is a single byte of data, or 2 hex digits.

song = []; % storing song data to be passed later into my intrument object
% I wish I could preallocate memory for the song file, but I don't know how
% many notes there will be
sonl = 1; % song length, number of total notes
% MATLAB indexing quircks mean I start sonl at 1

temp = 1; % equal
key = 1; % key of C
amp = .1; % small amplitude to prevent clipping when multiple notes at the same time

i = 1; % global index, counts through each byte of total midi file
mthd = 0; % booleans for header and track location
mtrk = 0;
mpqn = 600000; % microseconds per quarter note, default, changed later

time = zeros(1,30); % stores seperate delta time for each channel 
% Preallocate a large number to prevent out of bounds errors
track_num = 0; % number of tracks
time_const = 1; % default normalization constant to turn delta time into seconds

last_status = '00000000'; % for storing commands for running status

inst = 1;

while i < length(mid) - 3
    % I don't want to accidentally go beyond bounds
     
    
    if isequal(mid(i:i+3), [77;84;104;100]) % checking for header code
        mthd = 1; mtrk = 0;
        i = i + 4; % incrementing counter and moving forward
        continue
    elseif isequal(mid(i:i+3), [77;84;114;107]) % checking for track header code
        mthd = 0; mtrk = 1;
        i = i + 4;
        i = i + 4; % going past some of the midi track info
        track_num = track_num + 1; % a new track is starting
        continue
    end
    
    if mthd % if we're in the header
        header_chunk_len = sum(mid(i:i+3));
        if header_chunk_len ~= 6
            error('header length incorrect')
        end
        format = mid(i+5); % expecting this to be one
        tracks = mid(i+7);
        tempo = (mid(i+8) * 256) + mid(i+9); % tempo is 2 bytes, MS byte is 16^2 larger than LS byte
        i = i + 10;
        mthd = 0;
        %extracting header information, incrementing index, finishing
        %header, and continuing loop
        continue
    end
    time_const = (1/tempo) * (mpqn) * (10^-6); % dimensional analysis yields this to be the correct formula
    % tempo is in [delta t/quarter note] and mpqn has units in name, and
    % 10^-6 is [microseconds/second]
    
    if mtrk % if we're in a track
        [del, inc] = vlb_find(mid(i:end)); % extract delta time and move on
        del = del * time_const; % converting delta time to absolute time
        i = i + inc; % looking after extracted delta time
        if mid(i) == 255 % beginning of meta command
            if isequal(mid(i+1:i+2), [47;00]) % end of track meta command
                mtrk = 0; % ending track
                i = i + 3; % moving index to after meta command
                continue % next loop
            elseif mid(i+1) == 81 % 51 in hex, marks timing information
                inc = mid(i + 2);
                i = i + 3;
                nums = mid(i:i+inc-1);
                mult = 16.^(2*(inc-1:-1:0))'; % again, hex and powers of 16
                mpqn = sum(mult .* nums); % microseconds per quarter note
                continue
            else % meta commands that haven't been programmed in will just be skipped
                i = i + 2;
                [inc1, inc2] = vlb_find(mid(i:end)); % gets length of meta command, and length of VLB length data
                i = i + inc1;
                i = i + inc2; % skipping meta command
                continue
            end
                
            
        else
            bin = dec2bin(mid(i),8); % if not a meta command, a normal command
            if strcmp(bin(1), '1') % beginning of command is always 1
                last_status = mid(i); % storing status just in case for running status
                switch bin(2:4) % next three bits, command code
                    case {'001'} % note on
                        chan = bin2dec(bin(5:8)); % next four bits is chan data
                        l1 = mid(i+1); % l1 is midi number
                        l2 = mid(i+2); % l2 is velocity
                        % we expect MSB to be 0, so don't have to pull
                        % it off
                        if chan == 9
                            inst = 2;
                        else
                            inst = 1;
                        end
                        if l2 ~= 0
                            % adding a note. see bottom for more
                            % formatting info. A end time of 0 is
                            % selected for now
                            % We want the delta t to be for current
                            % track only, so time(track_num)
                            % Amplitude of note is the fraction of velocity
                            % out of 127, times some base constant, .1
                            song(sonl,:) = [l1, temp, key, time(track_num) + del, 0, amp*(l2/127), chan, inst];
                            sonl = sonl + 1;
                        else % velocity == 0 is same as note off
                            ind = find_note(song, l1, chan);
                            if ind ~= 0
                                % setting end time of track_num
                                song(ind,5) = time(track_num) + del;
                            end
                        end
                        time(track_num) = time(track_num) + del;
                        % incrementing total time by delta time
                        i = i + 3;
                        continue
                    case {'000'} % note off, basically same as above
                        chan = bin2dec(bin(5:8));
                        l1 = mid(i+1);
                        l2 = mid(i+2);
                        ind = find_note(song, l1, chan);
                        if ind ~= 0
                            song(ind,5) = time(track_num) + del;
                        end
                        time(track_num) = time(track_num) + del;
                        i = i + 3;
                        continue
                    case {'010'} % below are commands not yet programmed in, 
                        % however still have switch cases so i can be incremented
                        i = i + 3;
                        continue
                    case {'101'}
                        i = i + 2;
                        continue
                    case {'011'}
                        i = i + 3;
                        continue
                    case {'111'}
                        i = i + 3;
                        continue
                    case {'100'}
                        i = i + 2;
                        continue
                    case {'110'}
                        i = i + 3;
                        continue
                    otherwise
                        bin(2:4)
                        disp('not a command')
                end
                
            else
                % When the command after a delta t doesn't begin with 1,
                % it's a running status. In this case, the pointer is
                % already pointed at the data byte, so the incrementing is
                % one less than it would be with a regular command.
                % Otherwise, the rest of this code is the same. 
                bin = dec2bin(last_status,8); % the command byte in this case is from before, not at current i
                switch bin(2:4)
                    case {'001'} % note on
                    chan = bin2dec(bin(5:8));
                    l1 = mid(i); % no need to increment i because we're already in a command
                    l2 = mid(i+1); % l2 is velocity
                    if chan == 9
                        inst = 2;
                    else
                        inst = 1;
                    end
                    if l2 ~= 0
                        song(sonl,:) = [l1, temp, key, time(track_num) + del, 0, amp*(l2/127), chan, inst];
                        sonl = sonl + 1;
                    else
                        ind = find_note(song, l1, chan);
                        if ind ~= 0
                            song(ind,5) = time(track_num) + del;
                        end
                    end
                    time(track_num) = time(track_num) + del;
                    i = i + 2;
                    continue
                    case {'000'}
                        chan = bin2dec(bin(5:8));
                        l1 = mid(i);
                        l2 = mid(i+1);
                        ind = find_note(song, l1, chan);
                        if ind ~= 0
                            song(ind,5) = time(track_num) + del;
                        end
                        time(track_num) = time(track_num) + del;
                        i = i + 2;
                        continue
                    case {'010'}
                        i = i + 2;
                        continue
                    case {'101'}
                        i = i + 1;
                        continue
                    case {'011'}
                        i = i + 2;
                        continue
                    case {'111'}
                        i = i + 2;
                        continue
                    case {'100'}
                        i = i + 1;
                        continue
                    case {'110'}
                        i = i + 2;
                        continue
                    otherwise
                        bin(2:4)
                        disp('not a command')
                end
            end
        end
        continue
    end
    %i = i + 1;
end


mask = song(:,end) == 1;
%song = song(mask,:);
%song(:,end) = 1;

% song(:,[4 5]) = song(:,[4 5]) * (.4/tempo);
% previous hard coded quick fix to normalizing delta T. Now the delta t is
% normalized in the code already

    
% after parsing the whole midi file, we now have a song matrix organized as
% follows: each row is a single note that looks like:

% [ Note number, temperament, key, start time, end time, amp, chan, instrument ]

% Amp is a full amplitude, chan is the channel of the note, and instrument is the selected instrument.
% In this case, instrument is always 1 (trumpet), except for channel 9, in which case
% it is 2 (drum). The note object gets only passed the instrument data,
% chan data is merely for debugging sake.

% I altered the objNote class so the switch cases for temperament and key
% also accept the value 1 and 0. Key of C is 1, equal is 1. 
% This gets stored into a objPlayer object, so that the play audio function
% can reference it. 

% In order to actually play the song, a playAudio object is created below.
% The constructor loops through the rows of the song matrix and creates
% objNotes from them. That way, the playAudio object can play them easily.

song = sortrows(song, 5);
%song = song(1:maxl,:);
% because the objSynth object has to loop through each and every note per
% 800 samples, for long note arrays it can't keep up. Thus, I made some
% changes inside the ObjSynth, and subsequent objects. In particular, by
% looping only through a hundred or so notes at a time, the program can
% keep up. This requires some logic that determines when a note has been
% passed. However, the main challenge, was because the Osc and Env objects
% keep track of their own time, if not all notes are looped through,
% then those object don't keep the correct updated time. To fix this, I had
% only the synth object keep the current time, and passed this value down
% through to the osc and env objects. Thus, the playAudio function can now
% play an instrument with any length notesArray, because it will only loop
% through 100 notes at any moment.

trumpet = objPlayer(song);
fprintf('Song is %.0f seconds long\n',song(end,5))

playAudio(trumpet, oscParams, constants);


    