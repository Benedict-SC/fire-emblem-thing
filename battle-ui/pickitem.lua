require("battle-ui.pickweapon");
itemMenuImg = love.graphics.newImage("assets/img/sliceablemenu.png");
itemMenuCursor = love.graphics.newImage("assets/img/actionmenu_cursor.png");
itemMenuOptionHeight = 23;
itemMenuFont = Fonts.getFont("arial", 17);
PickItem = function(unit)
    pi = PickWeapon(unit);
    pi.executeCurrentOption = function()
        if pi.cursorPosition > 0 then
            local opt = pi.unit.inventory[pi.cursorPosition];
            local yoff = (pi.cursorPosition - 1) * itemMenuOptionHeight;
            game.battle.itemOptionsMenu = ItemOptionsMenu(unit,opt,yoff);
            game.battle.state = "ITEMOPTIONS";
        end
    end
    pi.toggleAttackRanges = function(item)
        --do nothing. ranges don't matter in this menu.
    end
    pi.render = function(mapzoom)
        love.graphics.setFont(actionMenuFont);
        local bounds = pi.getBounds(mapzoom);
        pi.box.draw(bounds.x,bounds.y);
        if pi.cursorPosition ~= 0 then
            love.graphics.draw(itemMenuCursor,bounds.x,bounds.y + (itemMenuOptionHeight * (pi.cursorPosition-1)) + pi.box.bh);
        end
        for i=1,#pi.unit.inventory,1 do
            local item = pi.unit.inventory[i];
            love.graphics.print(item.name .. "(" .. item.currentUses .. "/" .. item.maxUses .. ")",bounds.x+pi.box.bw+2,bounds.y+pi.box.bh+1 + (itemMenuOptionHeight*(i-1)));
            love.graphics.setColor(1,1,1,1);
        end
    end
    return pi
end
itemMenuXOffset = 20;
ItemOptionsMenu = function(unit,item,yoff)
    local iom = {}
    iom.box = MenuBox(itemMenuImg,10);
    iom.cursorPosition = 1; --0 is no draw
    iom.unit = unit;
    iom.item = item;
    iom.yoffset = yoff;
    iom.options = Array();
    if iom.item.isWeapon then
        --TODO: weapon proficiency check
        local equipOpt = {name="Equip"};
        equipOpt.onPick = function()
            iom.unit.equipWeapon(iom.item);
        end
        iom.options.push(equipOpt);
    end
    if iom.item.usable() then
        local useOpt = {name="Use"};
        useOpt.onPick = function()
            iom.item:use(function() 
                game.battle.endUnitsTurn(iom.unit);
            end);
        end
        iom.options.push(useOpt);

    end
    local backOpt = {name="Back"};
    backOpt.onPick = function() 
        game.battle.state = "PICKITEM";
    end
    iom.options.push(backOpt);
    iom.executeCurrentOption = function()
        if iom.cursorPosition > 0 then
            local opt = iom.options[iom.cursorPosition]
            opt.onPick();
        end
    end
    iom.getBounds = function(mapzoom)
        if not mapzoom then mapzoom = {factor=1,xoff=0,yoff=0}; end
        local adjustedTileSize = game.tileSize * mapzoom.factor;
        local rightEdge = math.floor((iom.unit.x*adjustedTileSize) + 0.5) - mapzoom.xoff;
        local bottomEdge = math.floor((iom.unit.y*adjustedTileSize) + 0.5) - mapzoom.yoff;
        local leftEdge = rightEdge - math.floor(adjustedTileSize + 0.5);
        local topEdge = bottomEdge - math.floor(adjustedTileSize + 0.5);

        print("iom opts length is " .. #(iom.options));
        local height = (iom.box.bh*2) + (#(iom.options) * itemMenuOptionHeight); 
        print("iom height is " .. height);
        local x = rightEdge;
        if rightEdge + iom.box.w > gamewidth then --base menu doesn't fit on right side
            x = leftEdge - iom.box.w + itemMenuXOffset;
        elseif rightEdge + iom.box.w + itemMenuXOffset > gamewidth then --base menu plus offset doesn't fit on right side, but the base menu is going to fit, so just don't offset it.
            x = rightEdge;
        else --you've got room
            x = rightEdge + itemMenuXOffset
        end

        local y = topEdge + iom.yoffset;
        if topEdge + iom.yoffset + height > gameheight then
            y = gameheight - height;
        end
        return {x=x,y=y,w=iom.box.w,h=height};
    end
    iom.configureSize = function(mapzoom)
        local bounds = iom.getBounds(mapzoom);
        iom.box.resize(bounds.w,bounds.h);
    end
    iom.configureSize(); --call once on init
    iom.moveCursor = function(dir)
        iom.cursorPosition = iom.cursorPosition + dir;
        if iom.cursorPosition < 1 then iom.cursorPosition = #(iom.options); end
        if iom.cursorPosition > #(iom.options) then iom.cursorPosition = 1; end
    end
    iom.setCursorWithMouse = function(mapzoom)
        local bounds = iom.getBounds(mapzoom);
        local mx,my = love.mouse.getPosition();
        local x = mx - bounds.x;
        if x < iom.box.bw or x > iom.box.xoffs[3] then --if we're not 
            iom.cursorPosition = 0;
            return;
        end
        local y = my - bounds.y;
        local idx = math.ceil((y-iom.box.bh) / itemMenuOptionHeight);
        if idx <= 0 or idx > #(iom.options) then
            iom.cursorPosition = 0;
            return;
        end
        iom.cursorPosition = idx;
    end
    iom.render = function(mapzoom)
        love.graphics.setFont(itemMenuFont);
        local bounds = iom.getBounds(mapzoom);
        print("height: " .. bounds.h);
        iom.box.draw(bounds.x,bounds.y);
        if iom.cursorPosition ~= 0 then
            love.graphics.draw(itemMenuCursor,bounds.x,bounds.y + (itemMenuOptionHeight * (iom.cursorPosition-1)) + iom.box.bh);
        end
        for i=1,#iom.options,1 do
            local opt = iom.options[i];
            love.graphics.print(opt.name,bounds.x+iom.box.bw+2,bounds.y+pi.box.bh+1 + (itemMenuOptionHeight*(i-1)));
            love.graphics.setColor(1,1,1,1);
        end
    end
    return iom;
end