async = {};
async.updates = Array();
async.registerFunction = function(funcobj)
	async.updates.push(funcobj);
end
async.update = function()
	for i=1,#(async.updates),1 do
		if not (async.updates[i].cancel )then	
			async.updates[i].func();
		end
	end
	local i=1;
	while i <= #(async.updates) do
		if async.updates[i].done or async.updates[i].cancel then
			async.updates.remove(i);
		else
			i = i + 1;
		end
	end
end

async.doForever = function(eternalfunc) 
	local updater = {};
	updater.startTime = love.timer.getTime();
	updater.finish = function() end
	updater.func = eternalfunc;
	updater.done = false;
	async.registerFunction(updater);
	return updater;
end
async.doEveryXSecsForever = function(eternalfunc,secs)
	local updater = {};
	updater.startTime = love.timer.getTime();
	updater.lastLoop = updater.startTime;
	updater.finish = function() end
	updater.func = function()
		local elapsed = love.timer.getTime() - updater.lastLoop;
		if elapsed > secs then
			eternalfunc();
			updater.lastLoop = love.timer.getTime() - (elapsed - secs); --offset by how late the actual update was
		end
	end
	updater.done = false;
	async.registerFunction(updater);
	return updater;
end
async.doEveryXSecsFor = function(func,secs,duration,funcwhendone)
	local updater = {};
	updater.startTime = love.timer.getTime();
	updater.lastLoop = updater.startTime;
	if funcwhendone then
		updater.finish = funcwhendone;
	else 
		updater.finish = function() end
	end
	updater.func = function()
		local elapsed = love.timer.getTime() - updater.lastLoop;
		if elapsed > secs then
			eternalfunc();
			updater.lastLoop = love.timer.getTime() - (elapsed - secs); --offset by how late the actual update was
		end
		if (love.timer.getTime() - updater.startTime) > duration then
			updater.finish();
		end
	end
	updater.done = false;
	async.registerFunction(updater);
	return updater;
end
async.moveThingOverTime = function(thing,x,y,secs,funcwhendone)
	local updater = {};
	updater.startTime = love.timer.getTime();
	updater.startPoint = {x=thing.x,y=thing.y};
	if funcwhendone then
		updater.finish = funcwhendone;
	else 
		updater.finish = function() end
	end
	updater.func = function()
		local timeElapsed = love.timer.getTime() - updater.startTime;
		local percentMoved = timeElapsed/secs;
		updater.done = percentMoved >= 1;
		if updater.done then percentMoved = 1; end
		local xDist = math.floor(percentMoved * x);
		local yDist = math.floor(percentMoved * y);
		thing.x = updater.startPoint.x + xDist;
		thing.y = updater.startPoint.y + yDist;
		if updater.done then 
			updater.finish();
		end
	end
	updater.done = false;
	async.registerFunction(updater);
	return updater;
end
async.wait = function(secs,funcwhendone)
	local updater = {};
	updater.startTime = love.timer.getTime();
	if funcwhendone then
		updater.finish = funcwhendone;
	else 
		updater.finish = function() end
	end
	updater.func = function()
		local timeElapsed = love.timer.getTime() - updater.startTime;
		updater.done = timeElapsed >= secs;
		if updater.done then 
			updater.finish();
		end
	end
	updater.done = false;
	async.registerFunction(updater);
	return updater;
end
async.doOverTime = function(secs,everyFrame,funcwhendone)
	local updater = {};
	updater.startTime = love.timer.getTime();
	if funcwhendone then
		updater.finish = funcwhendone;
	else 
		updater.finish = function() end
	end
	updater.everyFrame = everyFrame;
	updater.func = function()
		local timeElapsed = love.timer.getTime() - updater.startTime;
		local percent = timeElapsed/secs;
		updater.done = percent >= 1;
		if updater.done then percent = 1; end
		everyFrame(percent);
		if updater.done then 
			updater.finish();
		end
	end
	updater.done = false;
	async.registerFunction(updater);
	return updater;
end