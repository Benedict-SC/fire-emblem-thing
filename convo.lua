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
    c.start = function()
        c.box.rise();
    end
    c.render = function()
        c.box.render();
    end
    c.update = function()
        if c.box.state == "WRITE" then
            local mouseinput = pressedThisFrame.mouse1;
            local otherinput = pressedThisFrame.action;
            if mouseinput or otherinput then
                c.box.state = "TRANSITION";
                c.box.fall(function()
                    game.battle.endUnitsTurn(game.battle.actionMenu.unit);
                end);
            end
        end
    end
    return c;
end
