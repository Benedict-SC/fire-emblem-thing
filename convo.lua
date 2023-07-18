Convo = function(convoFile)
    local c = {};
    local jsonstring = love.filesystem.read("assets/json/convo/" .. convoFile .. ".json");
    c.data = json.decode(jsonstring);
    c.idIndices = {};
	c.line = 1;
	for i=1,#c.data.lines,1 do
		local line = c.data.lines[i];
		if line.id then 
			conv.idIndices[line.id] = i;
		end
	end
    c.box = TextBox();
    c.render = function()
        c.box.render();
    end
    return c;
end
