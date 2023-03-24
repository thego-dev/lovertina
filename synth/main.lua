local gs = require("lib/pixel")
require("lib/std_thego") --my commonly used helper functions


--[[
LOVERTINA
a programmable synth using the Wicki-Hayden note layout
made by Thego124

thank you to:
Nicolas Allemand
	from denver.lua [http://github.com/superzazu/denver.lua]:
		the method to make oscillators(
				making an empty soundfile,
				filling it sample by sample and then treating it just like a sound effect
			)
		the note_to_frequency function
	[also, Nick, it's a sine wave or a sinusoidal wave, not a "sinus wave".
	...and snake_case > camelCase. <3]

Kass from LoZ:BotW
	for taking my respect and slight interest in accordions into a fascination and
	extreme need for a concertina, leading to me learning about wicki-hayden and
	stuff
	"Kass my beloved" - some person on twitter probably
]]

function love.load()
	version = 0.8
	
	--pixel perfection
	max_x, max_y = love.graphics.getDimensions()
	mid_x, mid_y = max_x/2, max_y/2
	gs.load()
	local font = love.graphics.newImageFont(
		"assets/art/picofont.png",
		" ABCDEFGHIJKLMNOPQRSTUVWXYZ"..
		"abcdefghijklmnopqrstuvwxyz"..
		"0123456789"..
		".,!?-+/\\():;%&`'*#=_[]\"$@{}|~")
	love.graphics.setFont(font)
	
	states = {
		start = require("states/start"),
		play = require("states/play"),
	}
	
	state = states.start
	state.load()
end


function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	else
		state.keypressed(key)
	end
end

function love.keyreleased(key)
	state.keyreleased(key)
end


function love.update(dt)
	gs.update(dt)
	
	state.update(dt)
end

function love.draw()
	gs.start()
	
	state.draw()
	
	gs.stop()
end
