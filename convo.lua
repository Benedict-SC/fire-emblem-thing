Convo = function(convoFile)
    local c = {};
    local jsonstring = love.filesystem.read("assets/json/convo/" .. convoFile .. ".json");
    c.data = json.decode(jsonstring);
    c.idIndices = {};
	c.line = 1;
	for i=1,#c.data.lines,1 do
		local line = c.data.lines[i];
		if line.id then 
			c.idIndices[line.id] = i;
		end
	end
    c.box = TextBox();
    c.start = function()
        c.box.rise(function() 
            c.box.setLine(c.data.lines[c.line]);
        end);
    end
    c.advance = function() 
        local line = c.data.lines[c.line];
        if line.jump then
            c.line = c.idIndices[line.to]
        else
            c.line = c.line + 1;
            if c.line > #(c.data.lines) then
                c.conclude();
                return;
            end--else
            DEBUG_TEXT = "attempting to set line: " .. c.data.lines[c.line].text;
            c.box.setLine(c.data.lines[c.line]);
            c.box.state = "WRITE";
        end
    end
    c.conclude = function()
        c.box.state = "TRANSITION";
        c.box.fall(function()
            game.battle.endUnitsTurn(game.battle.actionMenu.unit);
        end);
    end
    c.render = function()
        c.box.render();
    end
    c.update = function()
        if c.box.state == "WRITE" then
            c.box.update();
        elseif c.box.state == "HOLD" then
            local mouseinput = pressedThisFrame.mouse1;
            local otherinput = pressedThisFrame.action;
            if mouseinput or otherinput then
                c.advance();
            end
        end
    end
    return c;
end
