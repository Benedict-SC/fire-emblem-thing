Convo = function(convoFile)
    local c = {};
    local jsonstring = love.filesystem.read("assets/json/convo/" .. convoFile .. ".json");
    local data = json.decode(jsonstring);
    c.box = TextBox();
    c.render = function()
        c.box.render();
    end
    return c;
end