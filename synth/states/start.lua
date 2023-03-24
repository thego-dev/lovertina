local start = {
	load = function()
		jingle = love.audio.newSource("assets/audio/jingle.wav", "static")
		jingle:play()
		
		clips = {
			0x0.4C, 0x0.86, 0x0.BE,
			0x0.F9, 0x1.CC, 0xF.FF
		}
		text = {"lo","ver","ti","na!",""}
		place, time, boxy, boxy2 = 1, 0, 0, 0
	end,
	
	keypressed = function(key)end,
	keyreleased = function(key)end,
	
	update = function(dt)
		time = time + dt
		if time > clips[place] then
			place = place + 1
		end
		
		local target = place == 6 and 0 or 5
		local spd = 1/(16*dt)
		
		boxy  = boxy  + (target-boxy )/spd
		boxy2 = boxy2 + (    63-boxy2)/spd
		
		if not jingle:isPlaying() then
			jingle:release()
			state = states.play
			state.load()
		end
	end,
	
	draw = function()
		local t = ""
		for i = 1, place-1 do
			t = t..text[i]
		end
		
		if boxy>=0.5 then
			love.graphics.rectangle(
				"line",
				43, 64-boxy,
				41, 2*boxy
			)
		end
		love.graphics.rectangle(
			"line",
			0, 63 - boxy2,
			127, 2 * boxy2 + 1
		)
		if place<6 then
			love.graphics.print(t, 64 - 2*#t, 61)
		end
	end,
}

return start
