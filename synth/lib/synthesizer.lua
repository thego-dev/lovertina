--Thego124's Synth engine
--partially stolen- i mean inspired by Nicolas Allemand's Denver.lua

--[[
USE:

put "[lib_name] = require(/path/to/this/library/) " wherever you put your dependencies in the main file

create a instrument using [lib_name].new, giving it a name, shape, volume and effect(s)

shape is a table of "samples", making up one cycle of your instrument's waveform
ex. {1, -1} = a square wave, {1, -1 , -1, -1} = 1/4 pulse wave
more complicated waveforms should be made with loops; 64 "samples" is enough for a sine, triangle or saw wave

effect_name can either be a singular audio effect's name (made using love.audio.setEffect, check the wiki) or a whole table of 'em

the created instrument can then be used with [lib_name].play(instrument, note [written as letter - space/# - octave, ex: "C 4", "F#3"])
and stopped with [lib_name].stop(...)

adsr is an "array" of positive floats, measured in seconds (or, for sustain, % of main volume)
]]

local love = love

local notevals={"C ", "C#", "D ", "D#", "E ", "F ", "F#", "G ", "G#", "A ", "A#", "B "}

local s = {
	new = function(name, shape, volume, effect_name, loop)
		local instrument = {}
		instrument.name = name
		instrument.notes = {} --table of audio data
		instrument.shape = shape --shape table retained for visualization
		
		if type(shape) == "table" then
			instrument.loop = true
			local sample_rate = 44160
			
			for j=0,6 do
				for i=1,12 do
					local note = {}
					note.sound = custom_oscillator(notevals[i]..j, shape, volume)
					note.sound:setLooping(true)
					note.sound:setVolume(0)
					if effect_name then
						if type(effect_name) == "table" then
							for _,v in pairs(effect_name) do
								note.sound:setEffect(v)
							end
						else
							note.sound:setEffect(effect_name)
						end
					end
					
					note.state = "idle"
					instrument.notes[notevals[i]..j] = note
				end
			end
		elseif type(shape) == "string" then
			instrument.loop = loop or false
			
			for j = 0, 6 do
				for i = 1, 12 do
					local note = {}
					local note_path = "instr/"..shape.."/"..notevals[i]..j..".wav"
					
					note.sound = love.audio.newSource(love.sound.newSoundData(11040, 44160, 16, 1))
					if love.filesystem.getInfo(note_path) then
						note.sound = love.audio.newSource(note_path, "static")
					end
					
					note.sound:setLooping(false)
					note.sound:setVolume(0)
					
					note.state = "idle"
					instrument.notes[notevals[i]..j] = note
				end
			end
		else
			error("instrument shape must be table or name in \"instr\" folder!")
		end
		
		return instrument
	end,
	
	play_note = function(instrument, note)
		instrument.notes[note].state = "attack"
		instrument.notes[note].sound:stop()
		instrument.notes[note].sound:play()
		last_note = instrument.notes[note].sound
	end,
	
	stop_note = function(instrument, note)
		instrument.notes[note].state = "release"
	end
	
 }


 
function note_to_frequency(note_str) --takes in a note name ("C 4", "D#3") and outputs the corresponding frequency in Hz
	assert(type(note_str) == 'string', "note_to_frequency was given "..note_str..", which is not a string!")
	local note_semitones = {C=-9, D=-7, E=-5, F=-4, G=-2, A=0, B=2}
	
	local semitones = note_semitones[note_str:sub(1,1)]
	local octave = note_str:sub(3,3) or 4
	local alteration = 0
	
	if note_str:sub(2,2) == '#' then
		semitones = semitones + 1
	end
	
	semitones = semitones + 12 * (octave-4)
	
	return 440 * math.pow(math.pow(2, 1/12), semitones) -- 1/12 ~= 0.083333
	-- frequency = root * (2^(1/12))^steps (steps(=semitones) can be negative)
end



function custom_oscillator(frequency, shape, volume)
	--shape is a variable-length table of numbers from -1 to 1 inclusive, segmentally describing the shape of the waveform.
	
	local sample_rate = 44160
	
	--making the note name into the actual Hz frequency (A4= 440Hz)
	local frequency = note_to_frequency(frequency)
	
	--one cycle
	local length = 1/frequency
	
	--creating an empty sample 
	local sound_data = love.sound.newSoundData(length * sample_rate, sample_rate, 16, 1)
	
	
	--filling the sample with values 
	local sample_count = math.floor(length *sample_rate)
	
	for i = 0, sample_count -1 do
		local pos = 1 + math.floor(#shape*(i/sample_count))
		local sample = shape[pos] * .2 * volume
		
		sound_data:setSample(i, sample)
	end
	
	return love.audio.newSource(sound_data)
end



function s.update_adsr(dt)
	modes = {
		attack = function(note,vol)
			if not note.sound:isPlaying() then note.sound:play() end
			note.sound:setVolume(math.min(vol + dt/adsr[1],1))
			
			if vol >= 1 then note.state = "decay" end
		end,
		decay = function(note,vol)
			note.sound:setVolume(math.max(vol - dt/adsr[2],adsr[3]))
			
			if vol <= adsr[3] then
				note.sound:setVolume(adsr[3])
				note.state = "sustain"
			end
			
			if vol <= 0 then note.state = "idle" end
		end,
		release = function(note,vol)
			if adsr[4] == 0 then
				note.sound:setVolume(0)
				note.sound:stop()
				note.state = "idle"
			else
				note.sound:setVolume(math.max(vol - dt/adsr[4],0))
				
				if vol <= 0 then
					note.state="idle"
					note.sound:stop()
				end
			end
		end,
	}
	
	for i = 0, 37 do
		local note = current_instrument.notes[pitch[position+i]]
		local vol = note.sound:getVolume()
		
		if modes[note.state] then
			modes[note.state](note,vol)
		end
	end
end



return s