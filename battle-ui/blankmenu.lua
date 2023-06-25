blankMenuImg = love.graphics.newImage("assets/img/blankmenu.png");
blankMenuCursor = love.graphics.newImage("assets/img/actionmenu_cursor.png");
blankMenuOptionHeight = 23;
blankMenuFont = love.graphics.newFont("assets/font/arial.ttf", 17);
BlankMenu = function(x,y)
    local am = {};
    am.unit = {x=x,y=y};
    am.box = MenuBox(blankMenuImg,8);
    am.cursorPosition = 1; --0 is no draw
    am.options = Array();
    --let's populate the options
    --UNITS
        local unitsOption = {name="Units"};
        unitsOption.onPick = function()
            --TODO: summon options menu
        end
        am.options.push(unitsOption);

    --OPTIONS
    local optionOption = {name="Options"};
    optionOption.onPick = function()
        --TODO: summon options menu
    end
    am.options.push(optionOption);

    --END
    local endOption = {name="End Turn"};
    endOption.onPick = function()
        game.battle.changePhase();
    end
    am.options.push(endOption);

    am.executeCurrentOption = function()
        if am.cursorPosition > 0 then
            local opt = am.options[am.cursorPosition];
            opt.onPick();
        end
    end

    --[[mapzoom should be an object:
        factor=number
        xoff=number
        yoff=number
        ]]
    am.getBounds = function(mapzoom)
        if not mapzoom then mapzoom = {factor=1,xoff=0,yoff=0}; end
        local adjustedTileSize = game.tileSize * mapzoom.factor;
        local rightEdge = math.floor((am.unit.x*adjustedTileSize) + 0.5) - mapzoom.xoff;
        local bottomEdge = math.floor((am.unit.y*adjustedTileSize) + 0.5) - mapzoom.yoff;
        local leftEdge = rightEdge - math.floor(adjustedTileSize + 0.5);
        local topEdge = bottomEdge - math.floor(adjustedTileSize + 0.5);

        local height = (am.box.bh*2) + ((am.options.size) * blankMenuOptionHeight); 

        local x = rightEdge;
        if rightEdge + am.box.w > gamewidth then
            x = leftEdge - am.box.w;
        end

        local y = topEdge;
        if topEdge + height > gameheight then
            y = gameheight - height;
        end
        return {x=x,y=y,w=am.box.w,h=height};
    end
    am.configureSize = function(mapzoom)
        local bounds = am.getBounds(mapzoom);
        am.box.resize(bounds.w,bounds.h);
    end
    am.configureSize(); --call once on init
    
    am.render = function(mapzoom)
        love.graphics.setFont(blankMenuFont);
        local bounds = am.getBounds(mapzoom);
        am.box.draw(bounds.x,bounds.y);
        --love.graphics.draw(am.img,bounds.x,bounds.y,0,1,bounds.h/am.img:getHeight());
        if am.cursorPosition ~= 0 then
            love.graphics.draw(blankMenuCursor,bounds.x-5,bounds.y + (blankMenuOptionHeight * (am.cursorPosition-1)) + am.box.bh);
        end
        for i=1,#am.options,1 do
            love.graphics.print(am.options[i].name,bounds.x+am.box.bw+2,bounds.y+am.box.bh+1 + (blankMenuOptionHeight*(i-1)));
        end
    end
    am.moveCursor = function(dir)
        am.cursorPosition = am.cursorPosition + dir;
        if am.cursorPosition < 1 then am.cursorPosition = am.options.size; end
        if am.cursorPosition > am.options.size then am.cursorPosition = 1; end
    end
    am.setCursorWithMouse = function(mapzoom)
        local bounds = am.getBounds(mapzoom);
        local mx,my = love.mouse.getPosition();
        local x = mx - bounds.x;
        if x < am.box.bw or x > am.box.xoffs[3] then --if we're not 
            am.cursorPosition = 0;
            return;
        end
        local y = my - bounds.y;
        local idx = math.ceil((y-am.box.bh) / blankMenuOptionHeight);
        if idx <= 0 or idx > am.options.size then
            am.cursorPosition = 0;
            return;
        end
        am.cursorPosition = idx;
    end
    am.update = function()

    end
    return am;
end