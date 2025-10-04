require("battle-ui.pickweapon");
require("battle-ui.pickitem");
actionMenuImg = love.graphics.newImage("assets/img/sliceablemenu.png");
actionMenuCursor = love.graphics.newImage("assets/img/actionmenu_cursor.png");
actionMenuOptionHeight = 23;
actionMenuFont = Fonts.getFont("arial", 17);
ActionMenu = function(unit)
    local am = {};
    am.box = MenuBox(actionMenuImg,10);
    am.cursorPosition = 1; --0 is no draw
    am.options = Array();
    am.unit = unit;
    --let's populate the options
    --GENERAL USE
    local adjCells = game.battle.map.getAdjacentCells(am.unit.x,am.unit.y);
    local adjUnits = adjCells.filter(function(x) 
        return x.occupant;
    end);
    adjUnits = adjUnits.map(function(x) 
        return x.occupant;
    end);
    --ATTACK
    local attackranges = unit.getWeaponRanges();
    am.cellsToCheckForAttackables = game.battle.map.getCellsInRanges(unit.x,unit.y,attackranges);
    local anyHittable = false;
    for i=1,#am.cellsToCheckForAttackables,1 do
        local c = am.cellsToCheckForAttackables[i];
        if c.occupant and (c.occupant.faction ~= unit.faction) then
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
    --DEBUG-AI-TEST
    if unit.faction == "ENEMY" then
        local dbgai = {name="DEBUG AI"};
        dbgai.onPick = function()
            local ai = AIManager();
            ai.takeTurn({unit=unit},game.battle);
        end
        am.options.push(dbgai);
    end
    --TALK
    am.talkTargets = adjUnits.filter(function(x) 
        if (not am.unit.talks) and (not x.talks) then
            return false;
        end
        local selfHasConvo = false;
        local otherHasConvo = false;
        --check self for convos
        if am.unit.talks then
            local justNames = am.unit.talks.map(function(y) 
                return y.name;
            end);
            selfHasConvo = justNames.has(x.name);
        end
        --check target for convos
        if x.talks then
            local justNames = x.talks.map(function(y) 
                return y.name;
            end);
            otherHasConvo = justNames.has(am.unit.name);
        end
        return selfHasConvo or otherHasConvo;
    end);
    if #am.talkTargets >= 1 then
        local talkOption = {name="Talk"};
        talkOption.onPick = function()
            local b = game.battle;
            b.clearOverlays();
            am.talkTargets.forEach(function(x) 
                local cell = b.map.cellContainingUnit(x);
                cell.interactOn = true;
            end);
            b.verticalTargetList = am.talkTargets.sorted(vertsort);
            b.horizontalTargetList = am.talkTargets.sorted(horizsort);
            b.verticalTargetIndex = 1;
            b.horizontalTargetIndex = b.horizontalTargetList.indexOf(b.verticalTargetList[1]);
            --pick a random unit to start on and update the cursor
            local randomUnit = b.verticalTargetList[1];
            b.selectorPos.x = randomUnit.x;
            b.selectorPos.y = randomUnit.y;
            
            game.battle.state = "PICKTALK";
        end
        am.options.push(talkOption);
    end
    --TRADE
    am.tradeTargets = adjUnits.filter(function(x) 
        return x.faction == am.unit.faction;
    end);
    if #am.tradeTargets >= 1 then
        local tradeOption = {name="Trade"};
        tradeOption.onPick = function()
        local b = game.battle;
            b.clearOverlays();
            am.tradeTargets.forEach(function(x) 
                local cell = b.map.cellContainingUnit(x);
                cell.interactOn = true;
            end);
            b.verticalTargetList = am.tradeTargets.sorted(vertsort);
            b.horizontalTargetList = am.tradeTargets.sorted(horizsort);
            b.verticalTargetIndex = 1;
            b.horizontalTargetIndex = b.horizontalTargetList.indexOf(b.verticalTargetList[1]);
            --pick a random unit to start on and update the cursor
            local randomUnit = b.verticalTargetList[1];
            b.selectorPos.x = randomUnit.x;
            b.selectorPos.y = randomUnit.y;
            
            game.battle.state = "PICKTRADE"; 
        end
        am.options.push(tradeOption);
    end
    --SHOVE
    --RESCUE
    --STEAL
    --ITEM
    if #(unit.inventory.filter(function(x) return x.usable(); end)) > 0 then
        local itemOption = {name="Item"};
        itemOption.onPick = function()
            --open up the inventory screen and go to inventory state
            game.battle.pickItemMenu = PickItem(am.unit);
            game.battle.state = "PICKITEM"; --TODO: inventory stuff
        end
        am.options.push(itemOption);
    end
    --WAIT
    local waitOption = {name="Wait"};
    waitOption.onPick = function()
        game.battle.endUnitsTurn(am.unit);
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

        local height = (am.box.bh*2) + (#(am.options) * actionMenuOptionHeight); 

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
        if am.cursorPosition ~= 0 then
            love.graphics.draw(actionMenuCursor,bounds.x,bounds.y + (actionMenuOptionHeight * (am.cursorPosition-1)) + am.box.bh);
        end
        for i=1,#am.options,1 do
            love.graphics.print(am.options[i].name,bounds.x+am.box.bw+2,bounds.y+am.box.bh+1 + (actionMenuOptionHeight*(i-1)));
        end
    end
    am.moveCursor = function(dir)
        am.cursorPosition = am.cursorPosition + dir;
        if am.cursorPosition < 1 then am.cursorPosition = #(am.options); end
        if am.cursorPosition > #(am.options) then am.cursorPosition = 1; end
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
        if idx <= 0 or idx > #(am.options) then
            am.cursorPosition = 0;
            am.toggleAttackRanges();
            return;
        end
        am.cursorPosition = idx;
        am.toggleAttackRanges();
    end
    am.addOption = function(option,index)
        if index then            
            if index > #(am.options) + 1 then 
                index = am.options + 1; 
            end
            am.options.insert(index,option);
        else
            am.options.push(option);
        end
        am.configureSize();
    end
    am.toggleAttackRanges = function()
        local show = am.cursorPosition ~= 0 and am.options[am.cursorPosition].name == "Attack";
        --DEBUG_TEXT = "show is " .. (show and "true" or "false");
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