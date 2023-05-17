cStack = Array();
love.graphics.pushCanvas = function(canvas)
	cStack.push(canvas);
	love.graphics.setCanvas(cStack.peek());
end
love.graphics.popCanvas = function()
	
	local popped = cStack.pop();
	love.graphics.setCanvas(cStack.peek());
	return popped;
end