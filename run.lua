local consts = require("consts")

function love.run()
	if love.load then
		love.load(love.arg.parseGameArguments(arg))
	end
	local lag = consts.tickLength
	local updatesSinceLastDraw, lastLerp = 0, 1
	love.timer.step()
	
	return function()
		love.event.pump()
		for name, a,b,c,d,e,f in love.event.poll() do -- Events
			if name == "quit" then
				if not love.quit or not love.quit() then
					return a or 0
				end
			end
			love.handlers[name](a,b,c,d,e,f)
		end
		
		do -- Update
			local delta = love.timer.step()
			lag = math.min(lag + delta, consts.tickLength * consts.maxTicksPerFrame)
			local frames = math.floor(lag / consts.tickLength)
			lag = lag % consts.tickLength
			if love.frameUpdate then
				love.frameUpdate(dt)
			end
			if not paused then
				local start = love.timer.getTime()
				for _=1, frames do
					updatesSinceLastDraw = updatesSinceLastDraw + 1
					if love.fixedUpdate then
						love.fixedUpdate(consts.tickLength)
					end
				end
			end
		end
		
		if love.graphics.isActive() then -- Rendering
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())
			
			local lerp = lag / consts.tickLength
			deltaDrawTime = ((lerp + updatesSinceLastDraw) - lastLerp) * consts.tickLength
			love.draw(lerp, deltaDrawTime)
			updatesSinceLastDraw, lastLerp = 0, lerp
			
			love.graphics.present()
		end
		
		love.timer.sleep(0.001)
	end
end
