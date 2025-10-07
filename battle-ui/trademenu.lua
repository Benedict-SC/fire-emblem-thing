require("menubox");
tradeMenuImg = love.graphics.newImage("assets/img/sliceablemenu.png");
tradeMenuCursor = love.graphics.newImage("assets/img/unbounded-cursor.png");
tradeMenuOptionHeight = 23;
tradeMenuWidth = gamewidth/3;
tradeMenuFont = Fonts.getFont("arial", 17);
tradeMenuMarginX = 20;
tradeMenuMarginY = 80;
TradeMenu = function(activeUnit,targetUnit)
    local tm = {};
    tm.aBox = MenuBox(tradeMenuImg,10);
    tm.tBox = MenuBox(tradeMenuImg,10);
    tm.cursorPosition = 1; --0 is no draw
    tm.menuSelected = 1; --2 is the right-hand target menu
    tm.activeUnit = activeUnit;
    tm.targetUnit = targetUnit;
    tm.selectedIdx = 0;
    tm.selectedItem = nil;
    tm.selectedUnit = nil;
    tm.anySwapHappened = false;
    
    tm.backOut = function()
        if tm.selectedIdx ~= 0 then
            tm.selectedIdx = 0;
            tm.selectedItem = nil;
            tm.selectedUnit = nil;
        else
            if tm.anySwapHappened then
                game.battle.irreversibleActionCommitted = true;
                game.battle.actionMenu.reloadOptions();
                game.battle.actionMenu.configureSize();
            end
            game.battle.state = "PICKTRADE";
        end
    end
    tm.executeCurrentOption = function()
        if tm.cursorPosition > 0 then
            local unit = (tm.menuSelected == 1) and tm.activeUnit or tm.targetUnit;
            if not tm.selectedItem then
                if tm.cursorPosition <= #unit.inventory then
                    tm.selectedItem = unit.inventory[tm.cursorPosition];
                    tm.selectedIdx = tm.cursorPosition;
                    tm.selectedUnit = unit;
                    tm.switchSides();
                end --else you're trying to select blank as your first item. nope.
            else
                if unit == tm.selectedUnit then 
                    if tm.cursorPosition > #unit.inventory then
                        --you can't swap with your own blank- that's meaningless. return without resetting the selection.
                        --TODO: play a nuh-uh sound effect
                        return;
                    elseif tm.selectedIdx ~= tm.cursorPosition then
                        --swap the items in the one inventory
                        local temp = unit.inventory[tm.selectedIdx];
                        unit.inventory[tm.selectedIdx] = unit.inventory[tm.cursorPosition];
                        unit.inventory[tm.cursorPosition] = temp;
                        --do the trade-equip trick
                        unit.equipFirstWeapon();
                        tm.anySwapHappened = true;
                        --TODO: play a sound effect
                    end --otherwise you're selecting the same thing, aka deselecting, so just move on to resetting the selection
                else --unit and selectedunit are different, so do a trade
                    if tm.cursorPosition > #unit.inventory then
                        --you're swapping with the target's blank, aka giving something away.
                        unit.inventory.push(tm.selectedItem);
                        tm.selectedUnit.inventory.removeItem(tm.selectedItem);
                        --do the trade-equip trick
                        unit.equipFirstWeapon();
                        tm.selectedUnit.equipFirstWeapon();
                        tm.anySwapHappened = true;
                        --TODO: play a sound effect
                    else
                        --you're doing a real trade
                        local temp = unit.inventory[tm.cursorPosition];
                        unit.inventory[tm.cursorPosition] = tm.selectedUnit.inventory[tm.selectedIdx];
                        tm.selectedUnit.inventory[tm.selectedIdx] = temp;
                        tm.anySwapHappened = true;
                        --TODO: play a sound effect
                    end
                end
                --then reset the selection
                tm.selectedIdx = 0;
                tm.selectedItem = nil;
                tm.selectedUnit = nil;
            end
        end
    end
    tm.getBounds = function(boxIdx)
        local box = (boxIdx == 1) and tm.aBox or tm.tBox;
        local unit = (boxIdx == 1) and tm.activeUnit or tm.targetUnit;
        local w = tradeMenuWidth;
        local h = (box.bh*2) + ((SETTINGS.inventoryMax) * tradeMenuOptionHeight); 
        local x = (boxIdx == 1) and tradeMenuMarginX or (gamewidth - box.w - tradeMenuMarginX);
        local y = tradeMenuMarginY;
        return {x=x,y=y,w=w,h=h};
    end
    tm.configureSize = function()
        local aBounds = tm.getBounds(1);
        local tBounds = tm.getBounds(2);
        tm.aBox.resize(aBounds.w,aBounds.h);
        tm.tBox.resize(tBounds.w,tBounds.h);
    end
    tm.configureSize(); --call once on init
    
    tm.render = function()
        love.graphics.setFont(tradeMenuFont);
        local aBounds = tm.getBounds(1);
        local tBounds = tm.getBounds(2);
        tm.aBox.draw(aBounds.x,aBounds.y);
        tm.tBox.draw(tBounds.x,tBounds.y);
        local selectedBox = (tm.menuSelected == 1) and tm.aBox or tm.tBox;
        local selectedBounds = (tm.menuSelected == 1) and aBounds or tBounds;
        love.graphics.draw(tm.activeUnit.port,tradeMenuMarginX + tm.targetUnit.port:getWidth(),tradeMenuMarginY - tm.activeUnit.port:getHeight(),0,-1,1);
        love.graphics.draw(tm.targetUnit.port,gamewidth - tradeMenuMarginX - tm.targetUnit.port:getWidth(),tradeMenuMarginY - tm.targetUnit.port:getHeight());
        love.graphics.setColor(0,0,0,1);
        love.graphics.print(tm.activeUnit.name,tradeMenuMarginX + tm.targetUnit.port:getWidth() + 5, tradeMenuMarginY - tradeMenuOptionHeight);
        love.graphics.print(tm.targetUnit.name,gamewidth - tradeMenuMarginX - tm.tBox.w, tradeMenuMarginY - tradeMenuOptionHeight);
        love.graphics.setColor(1,1,1,1);
        if tm.cursorPosition ~= 0 then
            love.graphics.draw(tradeMenuCursor,selectedBounds.x,selectedBounds.y + (tradeMenuOptionHeight * (tm.cursorPosition-1)) + selectedBox.bh);
        end
        for i=1,#tm.activeUnit.inventory,1 do
            local wep = tm.activeUnit.inventory[i];
            love.graphics.print(wep.name .. "(" .. wep.currentUses .. "/" .. wep.maxUses .. ")",aBounds.x+tm.aBox.bw+2,aBounds.y+tm.aBox.bh+1 + (tradeMenuOptionHeight*(i-1)));
            love.graphics.setColor(1,1,1,1);
        end
        if #tm.activeUnit.inventory < SETTINGS.inventoryMax then
            love.graphics.print("--",aBounds.x+tm.aBox.bw+2,aBounds.y+tm.aBox.bh+1 + (tradeMenuOptionHeight * #tm.activeUnit.inventory));
        end
        for i=1,#tm.targetUnit.inventory,1 do
            local wep = tm.targetUnit.inventory[i];
            love.graphics.print(wep.name .. "(" .. wep.currentUses .. "/" .. wep.maxUses .. ")",tBounds.x+tm.tBox.bw+2,tBounds.y+tm.tBox.bh+1 + (tradeMenuOptionHeight*(i-1)));
            love.graphics.setColor(1,1,1,1);
        end
        if #tm.targetUnit.inventory < SETTINGS.inventoryMax then
            love.graphics.print("--",tBounds.x+tm.tBox.bw+2,tBounds.y+tm.tBox.bh+1 + (tradeMenuOptionHeight * #tm.targetUnit.inventory));
        end
    end
    tm.moveCursor = function(dir)
        local unit = (tm.menuSelected == 1) and tm.activeUnit or tm.targetUnit;
        tm.cursorPosition = tm.cursorPosition + dir;
        if tm.cursorPosition < 1 then 
            tm.cursorPosition = #(unit.inventory) + 1;
            if tm.cursorPosition > SETTINGS.inventoryMax then tm.cursorPosition = SETTINGS.inventoryMax; end
        elseif (tm.cursorPosition > (#(unit.inventory) + 1)) or (tm.cursorPosition > SETTINGS.inventoryMax) then 
            tm.cursorPosition = 1; 
        end
    end
    tm.switchSides = function()
        if tm.menuSelected == 1 then 
            tm.menuSelected = 2;
            if tm.cursorPosition > (#tm.targetUnit.inventory + 1) then
                tm.cursorPosition = (#tm.targetUnit.inventory + 1);
            end
        else
            tm.menuSelected = 1;
            if tm.cursorPosition > (#tm.activeUnit.inventory + 1) then
                tm.cursorPosition = (#tm.activeUnit.inventory + 1);
            end
        end
    end
    tm.setCursorWithMouse = function(mapzoom)
        local aBounds = tm.getBounds(1);
        local tBounds = tm.getBounds(2);
        local mx,my = love.mouse.getPosition();
        
        local ax = mx - aBounds.x;
        local tx = mx - tBounds.x;
        if ax >= tm.aBox.bw and ax <= tm.aBox.xoffs[3] then --if we're not 
            tm.menuSelected = 1;
        elseif tx >= tm.tBox.bw and tx <= tm.tBox.xoffs[3] then
            tm.menuSelected = 2;
        else
            tm.cursorPosition = 0;
            --TODO: update display saying what's being traded for what
            return;
        end

        local maxIndex = ((tm.menuSelected == 1) and #(tm.activeUnit.inventory) or #(tm.targetUnit.inventory));
        if maxIndex ~= SETTINGS.inventoryMax then
            maxIndex = maxIndex + 1; --make room for the blank space at the end
        end
        local y = my - aBounds.y;
        local idx = math.ceil((y-tm.aBox.bh) / tradeMenuOptionHeight);
        if idx <= 0 or idx > maxIndex then
            tm.cursorPosition = 0;
            --TODO: update display saying what's being traded for what
            return;
        end
        tm.cursorPosition = idx;
        --TODO: update display saying what's being traded for what
    end
    return tm;
end