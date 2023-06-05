local synth = require("lib/synthesizer")
local l  = love --making it local speeds up access
local lg = l.graphics --shortforms
local la = l.audio

local make_synths = function()
	--first of all, audio effects.
	la.setEffect("reverb", {type = "reverb", volume = 1,})
	la.setEffect("phaser", {type = "flanger", volume = 1, rate = 1})
	
	synths = {}
	
	--pulsewaves
	local pulseforms= {2,4,8,64}
	for _,p in pairs(pulseforms) do
		local pulse = {1}
		
		for i = 2, p do
			pulse[i]=-1
		end
		
		table.insert(synths, synth.new("1/"..p.." pulse", pulse, .6))
	end
	
	--triangular synths - name, rise lengh, fall length, volume %
	local triagforms= {
		["triangle"]={32,32,2},
		["sawtooth"]={64,0,1},
		["tilted sawtooth"]={56,8,2},
		["double saw"]={56,0,.5,8}
	}
	
	for k,v in pairs(triagforms) do
		local triag = {}
		for i= 0,(v[1]-1) do
			table.insert(triag, i/(v[1]/2) -1)
		end
		for i= 0,(v[2]-1) do
			table.insert(triag, 1- i/(v[2]/2))
		end
		local f = nil
		if v[4] then
			for i= 0,(v[4]-1) do
			table.insert(triag, i/(v[4]/2) -1)
			end
			f = "phaser"
		end
		table.insert(synths, synth.new(k,triag,v[3],f,"reverb"))
	end
	
	--accordion, sawtooth + 2x square
	local accord = {}
	for i = 0, 63 do
		table.insert(accord, (i/64 + (i%32<16 and 1 or -1))*.5)
	end
	table.insert(synths, synth.new("accordion", accord, .8, "phaser"))
	
	--sine-based sounds
	local sine = {}
	local double_sine = {}
	local prod_sine = {}
	for i= 0, 63 do
		table.insert(sine, math.sin(math.pi * i/32))
		table.insert(double_sine, (math.sin(math.pi * i/32) + math.sin(math.pi* i/16))/1.8)
		
		local sumval = 1
		for j = 1, 5 do
			sumval = sumval * math.sin(math.pi * i/32 * j)
		end
		sumval = sumval * 2
		table.insert(prod_sine, sumval)
	end
	table.insert(synths, synth.new("sine",sine,2))
	table.insert(synths, synth.new("sine^2",double_sine,2))
	table.insert(synths, synth.new("fake_bell",prod_sine,2,"reverb"))
	
	--here comes the big ones
	--stolen from roboctopus's nintendo labo waveform cards
	table.insert(
		synths,
		synth.new(
			"sawtooth, super",
			{
				0.125, 0.625, 0.25, -0.125, -0.375, -0.5, -0.625, -0.625,
				-0.5, -0.5, -0.375, -0.25, -0.125, -0.125, -0.125, 0.0,
				0.0, 0.125, 0.125, 0.25, 0.25, 0.25, 0.25, 0.375,
				0.375, 0.25, 0.125, 0.125, 0.0, 0.625, 0.25, 0.0
			},
			2
		)
	)
	
	table.insert(
		synths,
		synth.new(
			"Mario rpg reed",
			{
				1,0.6562,0,-0.7188,-0.7812,-0.5,-0.375,-0.5,-0.5625,-0.1875,0.375,0.4375,-0.0938,
				-0.625,-0.625,-0.1562,0.0938,-0.25,-0.75,-0.9688,-0.5625,0,0,-0.4062,-0.8125,-0.625,
				-0.3125,-0.1875,-0.3125,-0.5938,-0.6562,-0.5,-0.2188,-0.1875,-0.3438,-0.4062,-0.2812,
				-0.1875,-0.25,-0.4062,-0.4375,-0.3125,-0.1562,-0.125,-0.125,-0.1562,-0.0938,0.125,
				0.5625,0.6875,0.4062,0.0625,-0.125,-0.2188,-0.4062,-0.4688,-0.1875,0.2812,0.8125,
				0.9688,0.9062,0.875,0.8438,0.9688,0.9688,
			},
			1,
			"reverb"
		)
	)
	
	table.insert(
		synths,
		synth.new("piano","piano0",1,"reverb")
	)
end
	
local play_state = {
	load = function()
		make_synths()
		
		love.audio.newSource("assets/audio/open.wav", "static"):play()
		
		current_synth = 1
		current_instrument = synths[current_synth]
		
		position = 26 --index ranging B0 - C4 (1 - 38); 26 = C3
		
		pitch = {}
		notes = {
			"C ", "C#", "D ", "D#", "E ", "F ", "F#", "G ", "G#", "A ", "A#", "B ",
		}
		for j=0,6 do
			for i=1,12 do
				pitch[#pitch+1] = notes[i]..j
			end
		end
		for i = 1,9 do
			table.remove(pitch,1)
		end
		
		--adsr
		adsr = {.5,0,1,.5}
		adsr_modes = {"pad  /\"\\", "pluck \\_"}
		adsr_mode = 0
		
		--key to semitone converter
		keyboard = {
			["1"] = 15, ["2"] = 17, ["3"] = 19, ["4"] = 21, ["5"] = 23, ["6"] = 25, ["7"] = 27, ["8"] = 29, ["9"] = 31, ["0"] = 33, ["-"] = 35, ["="] = 37,
			["q"] = 10, ["w"] = 12, ["e"] = 14, ["r"] = 16, ["t"] = 18, ["y"] = 20, ["u"] = 22, ["i"] = 24, ["o"] = 26, ["p"] = 28, ["["] = 30, ["]"] = 32,
			["a"] = 5, ["s"] = 7, ["d"] = 9, ["f"] = 11, ["g"] = 13, ["h"] = 15, ["j"] = 17, ["k"] = 19, ["l"] = 21, [";"] = 23, ["'"] = 25, ["\\"] = 27,
			["z"] = 0, ["x"] = 2, ["c"] = 4, ["v"] = 6, ["b"] = 8, ["n"] = 10, ["m"] = 12, [","] = 14, ["."] = 16, ["/"] = 18,
		}
		
		cmd_key = false
		
		--turn on/off all current instrument's notes in current range
		toggle_notes = function(b)
			for i = 0, 37 do
				local note = current_instrument.notes[pitch[position+i]]
				note.state = "idle"
				note.sound:setVolume(0)
				if b then la.stop(note.sound) end
			end
		end
		
		toggle_notes() --initialization of first instrument
		
		
		
		local change_instrument = function(i)
			--stopping old notes
			toggle_notes(true)
			--changing synth
			current_synth = current_synth +i
			if current_synth < 1 then current_synth = #synths end
			if current_synth > #synths then current_synth = 1 end
			current_instrument = synths[current_synth]
			--initializing new notes
			toggle_notes()
		end
		
		local change_envelope = function(i)
			adsr_mode = (adsr_mode +i) % #adsr_modes
			local resets = {
				{.5, 0, 1, .5},        --pad
				{.05, .5, 0, .5},    --pluck
			}
			adsr = resets[adsr_mode +1]
		end
		
		local change_range = function(i)
			toggle_notes(true)
			position = clamp(1, position + i, 38)
			toggle_notes()
		end
		
		--"resolution" of change in variables, 1/2^4
		dres = 0.0625
		local change_length = {
			function(i)
				adsr[1]= math.max(0, adsr[1] + i*dres)
				adsr[4]= math.max(0, adsr[4] + i*dres)
			end,
			function(i)
				adsr[2]= math.max(0, adsr[2] + i*dres)
				adsr[4]= math.max(0, adsr[4] + i*dres)
			end,
		}
		
		key_commands = {
			["1"]      = function() change_instrument(-1)           end,
			["q"]      = function() change_instrument(1)            end,
			["2"]      = function() change_range(-1)                end,
			["w"]      = function() change_range(1)                 end,
			["3"]      = function() change_envelope(-1)             end,
			["e"]      = function() change_envelope(1)              end,
			["4"]      = function() change_length[adsr_mode +1](-1) end,
			["r"]      = function() change_length[adsr_mode +1](1)  end,
		}
	end,
	
	keypressed = function(key)
		if key == "lctrl" then
			cmd_key = true
		elseif cmd_key and key_commands[key] then
			key_commands[key]()
		--play note
		elseif keyboard[key] then
			synth.play_note(
				current_instrument,
				pitch[keyboard[key]+position]
			)
		end
	end,
	
	keyreleased = function(key)
		if key == "lctrl" then
			cmd_key = false
		--stop note
		elseif keyboard[key] then
			synth.stop_note(
				current_instrument,
				pitch[keyboard[key]+position]
			)
		end
	end,
	
	update = function(dt)
		synth.update_adsr(dt)
		
		--scaling volume so playing multiple notes have the same volume as 1 note
		la.setVolume(
			(1/(la.getActiveSourceCount()^(1/3)))
		)
	end,
	
	draw = function()
		--borders
		--instrument and range
		lg.rectangle("line", 1, 1, max_x -1, 18)
		--ADSR
		lg.rectangle("line", 1, 22, 58, 34)
		--waveform visualization
		lg.rectangle("line", 62, 22, 66, 34)
		--outline
		lg.rectangle("line", 1, 59, max_x -1, 69)
		
		--write info
		--instrument and range
		lg.print(
			   "Position: "..pitch[position +2].."; "
			  ..string.format("%02d",position).."/38   |cmd: "..(cmd_key and "Y" or "N")
			.."\nInstrument: "..current_instrument.name,
			2,
			2
		)
		--adsr
		lg.print(
			{
				{1.00,0.00,0.30},   "mode: "..adsr_modes[adsr_mode +1],
				{0.16,0.68,1.00}, "\nlength: "..(adsr[4]==0 and adsr[2] or adsr[4])/dres
			},
			2,
			23
		)
		--version
		lg.print(
			{{1,1,1,.2},"V"..version},
			2,
			121
		)
		
		--draw waveform
		if type(current_instrument.shape)=="table" then
			for i = 1, 63 do
				local volume = 0
				if last_note then
					volume = last_note:getVolume()
				end
				
				local pos= 1 + math.floor(#current_instrument.shape*(i/64))
				local prev_pos= 1 + math.floor(#current_instrument.shape*((i-1)/64))
				local h = current_instrument.shape[pos]*15
				local prev_h = current_instrument.shape[prev_pos]*15
				
				lg.setColor(.1, .1, .1)
				lg.line(62+i, 39-prev_h, 63+i, 39-h)
				lg.setColor(1, 1, 1)
				lg.line(62+i, 39-prev_h*volume, 63+i, 39-h*volume)
			end
		else
		end
		
		local draw_key = function(x,y,i,index)
			local note = current_instrument.notes[pitch[position+i]]
			local light = note and note.sound:getVolume() or 0
			
			local c = (i == 2 or index > 4) and .5 or 1
			lg.setColor(c,c,c)
			
			lg.rectangle("line", x + math.floor(i/2)*9, y, 7, 7)
			
			if light > 0 then
				lg.setColor(c*light,c*light,c*light)
				lg.rectangle("fill", x + math.floor(i/2)*9, y, 6, 6)
			end
		end
		
		--draw key visualization
		for j = 0, 2 do
			local x, y = 2, 101
			for i = -1, 10 do
				draw_key(
					x - j*54,
					y - j*18,
					1 + (i +2)*2 + j*12,
					i
				)
			end
			for i = -1, 10 do
				draw_key(
					x + 23 - j*54,
					y + 9 - j*18,
					i*2 + j*12,
					i)
			end
			lg.setColor(1,1,1)
		end
	end,
}

return play_state
