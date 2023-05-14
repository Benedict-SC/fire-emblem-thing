actionMenuImg = love.graphics.newImage("assets/img/actionmenu.png");
actionMenuWidth = actionMenuImg:getWidth();
actionMenuOptionHeight = 20;
actionMenuFont = love.graphics.newFont("assets/font/arial.ttf", 18);
ActionMenu = function(unit)
    local am = {};
    am.img = actionMenuImg;
    am.options = Array();
    am.unit = unit;
    --let's populate the options
    --ATTACK
    local attackranges = unit.getWeaponRanges();
    local cellsToCheckForAttackables = game.battle.map.getCellsInRanges(unit.x,unit.y,attackranges);
    local anyHittable = false;
    for i=1,#cellsToCheckForAttackables,1 do
        local c = cellsToCheckForAttackables[i];
        if c.occupant and (c.occupant.friendly ~= unit.friendly) then
            anyHittable = true;
            break;
        end
    end
    if anyHittable then
        local attackOption = {name="Attack"};

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
        --end the unit's turn
        game.battle.state = "MAINPHASE"; --TODO: turn logic stuff
    end
    am.options.push(waitOption);

    --[[mapzoom should be an object:
        factor=number
        xoff=number
        yoff=number
        ]]
    am.getBounds = function(mapzoom)
        if not mapzoom then mapzoom = 1; end
        local adjustedTileSize = tileSize * mapzoom.factor;
        local rightEdge = math.floor((am.unit.x*adjustedTileSize) + 0.5) - mapzoom.xoff;
        local bottomEdge = math.floor((am.unit.y*adjustedTileSize) + 0.5) - mapzoom.yoff;
        local leftEdge = rightEdge - math.floor(adjustedTileSize + 0.5);
        local topEdge = bottomEdge - math.floor(adjustedTileSize + 0.5);

        local height = actionMenuImg:getHeight() + (am.options.size * actionMenuOptionHeight); 

        local x = rightEdge;
        if rightEdge + actionMenuWidth > gamewidth then
            x = leftEdge - actionMenuWidth;
        end

        local y = topEdge;
        if topEdge + height > gameheight then
            y = gameheight - height;
        end
        return {x=x,y=y,w=actionMenuWidth,h=height};
    end
    am.render = function(mapzoom)
        love.graphics.setFont(actionMenuFont);
        local bounds = am.getBounds(mapzoom);
        love.graphics.draw(am.img,bounds.x,bounds.y,0,1,bounds.h/am.img:getHeight());
        for i=1,#am.options,1 do
            love.graphics.print(am.options[i].name,bounds.x+11,bounds.y+8 + (28*(i-1)));
        end
    end
    am.update = function()

    end
    return am;
end