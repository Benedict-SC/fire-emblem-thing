Animation = function(filename)
	local base = {};
    base.canvas = love.graphics.newCanvas(10,10);
	base.jsonstring = love.filesystem.read("assets/json/anim/" .. filename .. ".json");
	base.data = json.decode(base.jsonstring);
	base.anims = {};
	base.currentAnim = base.data.default;
	--create individual animation frame canvases for each animation
	for k,v in pairs(base.data.animations) do
		local animdata = base.data.animations[k];
		local sheet = love.graphics.newImage(animdata.filepath);
		base.anims[k] = {};
		base.anims[k].fps = animdata.fps;
		base.anims[k].frames = Array();
		base.anims[k].framecount = animdata.frames;
		base.anims[k].playOnce = animdata.playOnce;
		for i = 1, base.anims[k].framecount, 1 do
			local canv = love.graphics.newCanvas(animdata.width,animdata.height);
			--draw frame to canvas
			love.graphics.pushCanvas(canv);
			local code = i - 1;
			local cx = math.floor(code%base.anims[k].framecount);
			local cy = math.floor(code/base.anims[k].framecount);
			local quad = love.graphics.newQuad(cx*animdata.width,cy*animdata.height,animdata.width,animdata.height,sheet:getWidth(),sheet:getHeight());
			love.graphics.draw(sheet,quad,0,0);
			love.graphics.popCanvas();
			--save canvas in frames
			base.anims[k].frames.push(canv);
			if k == base.data.default then 
				base.canvas = canv;
			end
		end
	end
	
	base.startTime = love.timer.getTime();
	base.startAnimation = function()
		base.startTime = love.timer.getTime();
	end
	base.setAnimation = function(animname)
		base.currentAnim = animname;
		if not (base.anims[animname]) then
			base.currentAnim = base.data.default;
		end
	end
	base.playAnimation = function(animname)
		base.setAnimation(animname);
		base.startAnimation();
	end
	base.whenDone = nil;
	base.playOnceAndThen = function(animonce,endfunc)
		base.playAnimation(animonce);
		base.whenDone = endfunc;
	end
	base.getFrame = function()
		local anim = base.anims[base.currentAnim];
		local framesElapsed = (love.timer.getTime() - base.startTime) * anim.fps;
		local framecount = anim.framecount;
		local frame = math.floor(framesElapsed % framecount) + 1; --+1 because ridiculous lua array indexing
		if anim.playOnce and framesElapsed > framecount then 
			frame = framecount; 
			if base.whenDone then
				base.whenDone();
				base.whenDone = nil;
			end
		end --if the animation should only play once
		return anim.frames[frame];
	end
	base.draw = function(x,y,rotation,sx,sy)
        if not rotation then rotation = 0; end
        if not sx then sx = 1; end
        if not sy then sy = 1; end
		base.canvas = base.getFrame();
		if not (base.dynamicTransparency) then
			love.graphics.setBlendMode("alpha","premultiplied");
		end
		love.graphics.draw(base.canvas,x,y,rotation,sx,sy);
		love.graphics.setBlendMode("alpha","alphamultiply");
	end
	
	base.width = function()
		return base.anims[base.currentAnim].frames[1]:getWidth();
	end
	base.height = function()
		return base.anims[base.currentAnim].frames[1]:getHeight();
	end
	return base;
end