local tiny = require "tinyecs.tiny"

local RenderSystem = tiny.processingSystem()
RenderSystem.filter = tiny.requireAll("position", "sprite_id")

function RenderSystem:process(e, dt)
	-- TYLKO pozycja i scale – bez tint!
	local pos = vmath.vector3(e.position.x, e.position.y, 0)
	go.set_position(pos, e.sprite_id)  -- hash OK
	go.set_scale(vmath.vector3(e.scale or 1, e.scale or 1, 1), e.sprite_id)
end

return RenderSystem