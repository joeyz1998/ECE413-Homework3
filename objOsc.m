classdef objOsc < matlab.System
    % untitled2 Add summary here
    %
    % This template includes the minimum set of functions required
    % to define a System object with discrete state.

    % Public, tunable properties
    properties
        % Defaults
        note                        = objNote;
        oscConfig                   = confOsc;
        constants                   = confConstants;
    end

    % Pre-computed constants
    properties(Access = private)
        % Private members
        currentTime;
        EnvGen                = objEnv;
        EnvGenMod = objEnv;
        EnvGenDrum = objEnv;
    end
    
    methods
        function obj = objOsc(varargin)
            %Constructor
            if nargin > 0
                setProperties(obj,nargin,varargin{:},'note','oscConfig','constants');
                
                tmpEnv=confEnv(obj.note.startTime,obj.note.endTime,...
                    obj.oscConfig.oscAmpEnv.AttackTime,...
                    obj.oscConfig.oscAmpEnv.DecayTime,...
                    obj.oscConfig.oscAmpEnv.SustainLevel,...
                    obj.oscConfig.oscAmpEnv.ReleaseTime);
                obj.EnvGen=objEnv(tmpEnv, obj.constants);
                
                modEnv=confEnv(obj.note.startTime,obj.note.endTime,...
                    0,... % attack Time
                    .06,... % decay time
                    0,... % sustain level
                    .1,... % realease time
                    1); % initial level
                obj.EnvGenMod=objEnv(modEnv, obj.constants);
                
                EnvDrum=confEnv(obj.note.startTime,obj.note.endTime,...
                    .02,...
                    .03,...
                    0,...
                    .05,...
                    0);
                obj.EnvGenDrum=objEnv(EnvDrum, obj.constants);
                
            end
        end
    end

    methods(Access = protected)
        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
            
            % Reset the time function
            obj.currentTime=0;
        end

        function audio = stepImpl(obj, time)
            % now oscillator function gets current time from Synth object,
            % instead of keeping track of its own
            
%             obj.EnvGen.StartPoint=obj.note.startTime;   % set the end point again in case it has changed
%             obj.EnvGen.ReleasePoint=obj.note.endTime;   % set the end point again in case it has changed
            
            %timeVec=(obj.currentTime+(0:(1/obj.constants.SamplingRate):((obj.constants.BufferSize-1)/obj.constants.SamplingRate))).';
            timeVec=(time+(0:(1/obj.constants.SamplingRate):((obj.constants.BufferSize-1)/obj.constants.SamplingRate))).';
            noteTime=timeVec-obj.note.startTime;
            
            
            
            %mask = obj.EnvGen.advance;
            mask = step(obj.EnvGen, timeVec, time);
            
            % the envelope generator now gets the current time, and the
            % time vector from the Osc object, instead of keeping track of
            % its own
            if isempty(mask)
                audio=[];
            else
                if all(mask == 0)
                    audio = zeros(1,obj.constants.BufferSize).';
                else
                    freq = obj.note.frequency;
                    switch obj.note.instrument
                        case 1
                            fmod1 = .4 .* sin( 2 * pi * 10 * timeVec);
                            fmod = 12 * mask(:) .* sin( 2 * pi * (5/5) * freq * timeVec + fmod1);
                            audio = obj.note.amplitude * mask(:) .* sin( (2 * pi * freq * timeVec) + fmod);
                            % A simple FMM model. Fun, sounds pretty cool I think,
                            % and the parameters are easy to change for more fun.
                        case 2
                            mask_mod = step(obj.EnvGenMod, timeVec, time);
                            mask_drum = step(obj.EnvGenDrum, timeVec, time);
                            % attempting a drum track here, with FM
                            fmod = 55;
                            mod = 25 * mask_mod(:) .* sin( 2 * pi * fmod * timeVec );
                            audio = obj.note.amplitude .* mask_drum(:) .* sin( (2 * pi * freq * timeVec) + mod);
                            
                            %audio = zeros(1,obj.constants.BufferSize).';
                        otherwise
                            audio = zeros(1,obj.constants.BufferSize).';
                            % no instrument selected
                    end
                end
            end
            %obj.currentTime=obj.currentTime+(obj.constants.BufferSize/obj.constants.SamplingRate);      % Advance the internal time

        end

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            % Reset the time function
            obj.currentTime=0;
        end
    end
end
