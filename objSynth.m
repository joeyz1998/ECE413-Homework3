classdef objSynth < matlab.System
    % untitled Add summary here
    %
    % This template includes the minimum set of functions required
    % to define a System object with discrete state.
    
    % Public, tunable properties
    properties
        notes;
        oscConfig                   = confOsc;
        constants                   = confConstants;
    end
    
    % Pre-computed constants
    properties(Access = private)
        currentTime;
%         arrayNotes                  = objNote.empty(8,0);
%         arraySynths                 = objOsc.empty(8,0);
        arrayNotes                  = objNote;
        arraySynths                 = {objOsc};
        i;

    end
    
    methods
        function obj = objSynth(varargin)
            %Constructor
            setProperties(obj,nargin,varargin{:},'notes','oscConfig','constants');
            obj.arrayNotes=obj.notes.arrayNotes;
            
            for cntNote=1:length(obj.arrayNotes)
                obj.arraySynths{cntNote}=objOsc(obj.arrayNotes(cntNote),obj.oscConfig,obj.constants);
            end
        end
    end
    
    
    methods(Access = protected)
        
        
%         function validateInputsImpl(~,notes,oscConfig,constants)
%             keyboard
%             if ~isprop(notes,'arrayNotes')
%                 error('Invalid Notes Function')
%             end
%             if ~isobject(oscConfig)
%                 error('oscConfig must be an object');
%             end
%             if ~isobject(constants)
%                 error('constants must be an object');
%             end
%         end

        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants

            % Reset the time function
            obj.currentTime=0;
            obj.i = 1;
        end
        
        function audioAccumulator = stepImpl(obj)
            % Implement algorithm.
          
            audioAccumulator=[];
            
            ind = obj.i; % current working index, for array of notes
            l = min(200, length(obj.arraySynths) - ind); % how many notes to look in the future 
            % but also not exeeding the end of the array of notes
            time = obj.currentTime; % time counter now lives in objSynth
            % This is the master time that gets passed down to all lower
            % functions
            
            
            %for cntNote = 1:length(obj.arraySynths)
            for cntNote = ind:ind + l
                %length(obj.arrayNotes)
                
                %audio = obj.arraySynths(cntNote).advance;
                audio = step(obj.arraySynths{cntNote},time);
                % current time being passed into the oscillator function
                
                %audio = zeros(0, obj.constants.Bufferize);
                %audio = step(obj.arraySynths(cntNote));
                if ~isempty(audio)
                    if isempty(audioAccumulator)
                        audioAccumulator=audio;
                    else
                        audioAccumulator=audioAccumulator+audio;
                    end
                end
            end
%             if obj.i <= length(obj.arraySynths)
%                 if obj.currentTime > (obj.arraySynths{obj.i}.note.endTime)
%                    obj.i = obj.i + 1; % failed attempt
%                 end 
%             end
            obj.currentTime = obj.currentTime + (obj.constants.BufferSize/obj.constants.SamplingRate);
            while (obj.i < length(obj.arraySynths)) && (obj.currentTime > (obj.arraySynths{obj.i}.note.endTime))
                obj.i = obj.i + 1;
                % if the current time is greater than the lowest most end
                % time, then no need to even look at it, advance the
                % counter. Also, all notes have been presorted in the main
                % function by end time.
            end
            obj.i = max(1, obj.i - 10); % some wiggle room
            
        end
        
        function resetImpl(obj)
            % Reset the time function
            obj.currentTime=0;
        end
    end
end
