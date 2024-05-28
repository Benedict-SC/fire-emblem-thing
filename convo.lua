Convo = function(convoFile,whendone,small)
    local c = {};
    local jsonstring = love.filesystem.read("assets/json/convo/" .. convoFile .. ".json");
    c.data = json.decode(jsonstring);
    c.idIndices = {};
	c.line = 1;
    c.whendone = whendone;
	for i=1,#c.data.lines,1 do
		local line = c.data.lines[i];
		if line.id then 
			c.idIndices[line.id] = i;
		end
	end
    if not small then
        c.box = TextBox();
    else
        c.box = MidbattleTextBox();
    end
    for id,port in pairs(c.data.portraits) do
        c.box.registerPortrait(id,port.versions,port.x,port.active,port.reversed);
    end
    c.start = function()
        c.box.rise(function()
            c.executeLine(c.data.lines[c.line]);
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
            local newline = c.data.lines[c.line];
            c.executeLine(newline);
        end
    end
    c.executeLine = function(line)
        if true then --later there might be lines that don't involve setting a line and writing, like script commands that auto-advance
            c.box.setLine(line);
            c.box.state = "WRITE";
        end
        if line.light then 
            c.box.highlightOne(line.light);
        end
    end
    c.conclude = function()
        c.box.state = "TRANSITION";
        c.box.highlightOne(nil);
        c.box.fall(function()
            if c.whendone then
                c.whendone();
            else
                game.battle.endUnitsTurn(game.battle.actionMenu.unit);
            end
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
