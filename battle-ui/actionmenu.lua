require("battle-ui.pickweapon");
actionMenuImg = love.graphics.newImage("assets/img/sliceablemenu.png");
actionMenuCursor = love.graphics.newImage("assets/img/actionmenu_cursor.png");
actionMenuOptionHeight = 23;
actionMenuFont = love.graphics.newFont("assets/font/arial.ttf", 17);
ActionMenu = function(unit)
    local am = {};
    am.img = actionMenuImg;
    am.box = MenuBox(actionMenuImg,10);
    am.cursorPosition = 1; --0 is no draw
    am.options = Array();
    am.unit = unit;
    --let's populate the options
    --ATTACK
    local attackranges = unit.getWeaponRanges();
    am.cellsToCheckForAttackables = game.battle.map.getCellsInRanges(unit.x,unit.y,attackranges);
    local anyHittable = false;
    for i=1,#am.cellsToCheckForAttackables,1 do
        local c = am.cellsToCheckForAttackables[i];
        if c.occupant and (c.occupant.friendly ~= unit.friendly) then
            anyHittable = true;
            break;
        end
    end
    if anyHittable then
        local attackOption = {name="Attack"};
        attackOption.onPick = function()
            game.battle.pickWeaponMenu = PickWeapon(am.unit);
            game.battle.state = "PICKWEAPON";
        end
        am.options.push(attackOption);
    end
    --TRADE
    --SHOVE
    --RESCUE
    --STEAL
    --ITEM
    if unit.inventory.filter(function(x) return x.usable(); end).size > 0 then
        local itemOption = {name="Item"};
        itemOption.onPick = function()
            --open up the inventory screen and go to inventory state
            game.battle.state = "MAINPHASE"; --TODO: inventory stuff
        end
        am.options.push(itemOption);
    end
    --WAIT
    local waitOption = {name="Wait"};
    waitOption.onPick = function()
        am.unit.used = true;
        game.battle.state = "MAINPHASE"; --TODO: turn logic stuff
    end
    am.options.push(waitOption);

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

        local height = (am.box.bh*2) + ((am.options.size) * actionMenuOptionHeight); 

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
        love.graphics.setFont(actionMenuFont);
        local bounds = am.getBounds(mapzoom);
        am.box.draw(bounds.x,bounds.y);
        --love.graphics.draw(am.img,bounds.x,bounds.y,0,1,bounds.h/am.img:getHeight());
        if am.cursorPosition ~= 0 then
            love.graphics.draw(actionMenuCursor,bounds.x,bounds.y + (actionMenuOptionHeight * (am.cursorPosition-1)) + am.box.bh);
        end
        for i=1,#am.options,1 do
            love.graphics.print(am.options[i].name,bounds.x+am.box.bw+2,bounds.y+am.box.bh+1 + (actionMenuOptionHeight*(i-1)));
        end
    end
    am.moveCursor = function(dir)
        am.cursorPosition = am.cursorPosition + dir;
        if am.cursorPosition < 1 then am.cursorPosition = am.options.size; end
        if am.cursorPosition > am.options.size then am.cursorPosition = 1; end
        am.toggleAttackRanges();
    end
    am.setCursorWithMouse = function(mapzoom)
        local bounds = am.getBounds(mapzoom);
        local mx,my = love.mouse.getPosition();
        local x = mx - bounds.x;
        if x < am.box.bw or x > am.box.xoffs[3] then --if we're not 
            am.cursorPosition = 0;
            am.toggleAttackRanges();
            return;
        end
        local y = my - bounds.y;
        local idx = math.ceil((y-am.box.bh) / actionMenuOptionHeight);
        if idx <= 0 or idx > am.options.size then
            am.cursorPosition = 0;
            am.toggleAttackRanges();
            return;
        end
        am.cursorPosition = idx;
        am.toggleAttackRanges();
    end
    am.toggleAttackRanges = function()
        local show = am.cursorPosition ~= 0 and am.options[am.cursorPosition].name == "Attack";
        DEBUG_TEXT = "show is " .. (show and "true" or "false");
        --show = show and am.options[am.cursorPosition].name == "Staff"; --or something
        game.battle.clearOverlays();
        if show then
            am.cellsToCheckForAttackables.forEach(function(x) x.hitOn = true; end);
        end
    end
    am.update = function()

    end
    return am;
end