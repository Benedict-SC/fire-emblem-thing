require("menubox");
require("fight");
pickWeaponImg = love.graphics.newImage("assets/img/sliceablemenu.png");
pickWeaponCursor = love.graphics.newImage("assets/img/unbounded-cursor.png");
pickWeaponOptionHeight = 23;
pickWeaponFont = Fonts.getFont("arial", 17);
PickWeapon = function(unit)
    local pw = {};
    pw.img = actionMenuImg;
    pw.box = MenuBox(pickWeaponImg,10);
    pw.cursorPosition = 1; --0 is no draw
    pw.unit = unit;
    pw.cellsToCheckForAttackables = Array();--game.battle.map.getCellsInRanges(unit.x,unit.y,attackranges);
    
    pw.executeCurrentOption = function()
        if pw.cursorPosition > 0 then
            local b = game.battle;
            local opt = pw.unit.inventory[pw.cursorPosition];
            if opt.isWeapon then
                pw.selectedWeapon = opt;
                pw.unit.equip(pw.cursorPosition);
                --get the list of units in range of that weapon
                local cellsInRange = b.map.getCellsInRanges(pw.unit.x,pw.unit.y,opt.range);
                cellsInRange = cellsInRange.filter(function(x) 
                    if x.occupant and (x.occupant.faction ~= pw.unit.faction) then
                        return true;
                    end
                    return false;
                end);
                --set only those units' targeting things on
                b.clearOverlays();
                cellsInRange.forEach(function(x) 
                    x.hitOn = true;
                end);
                --create the vertical and horizontal scroll lists
                local vertsort = function(a,b)
                    if a.y < b.y then return true;
                    elseif b.y < a.y then return false;
                    elseif a.x < b.x then return true;
                    else --[[if b.x < a.x]] return false;
                    end
                end
                local horizsort = function(a,b)
                    if a.x > b.x then return false;
                    elseif b.x > a.x then return true;
                    elseif a.y > b.y then return false;
                    else --[[if b.y > a.y]] return true;
                    end
                end
                local units = cellsInRange.map(function(x) return x.occupant; end);
                b.verticalTargetList = units.sorted(vertsort);
                b.horizontalTargetList = units.sorted(horizsort);

                b.verticalTargetIndex = 1;
                b.horizontalTargetIndex = b.horizontalTargetList.indexOf(b.verticalTargetList[1]);
                --pick a random unit to start on and update the cursor
                local randomUnit = b.verticalTargetList[1];
                b.selectorPos.x = randomUnit.x;
                b.selectorPos.y = randomUnit.y;
                b.fight = Fight(pw.unit,randomUnit);
                b.state = "COMBATPREVIEW";
            end
        end
    end

    --[[mapzoom should be an object:
        factor=number
        xoff=number
        yoff=number
        ]]
    pw.getBounds = function(mapzoom)
        if not mapzoom then mapzoom = {factor=1,xoff=0,yoff=0}; end
        local adjustedTileSize = game.tileSize * mapzoom.factor;
        local rightEdge = math.floor((pw.unit.x*adjustedTileSize) + 0.5) - mapzoom.xoff;
        local bottomEdge = math.floor((pw.unit.y*adjustedTileSize) + 0.5) - mapzoom.yoff;
        local leftEdge = rightEdge - math.floor(adjustedTileSize + 0.5);
        local topEdge = bottomEdge - math.floor(adjustedTileSize + 0.5);

        local height = (pw.box.bh*2) + ((pw.unit.inventory.size) * pickWeaponOptionHeight); 

        local x = rightEdge;
        if rightEdge + pw.box.w > gamewidth then
            x = leftEdge - pw.box.w;
        end

        local y = topEdge;
        if topEdge + height > gameheight then
            y = gameheight - height;
        end
        return {x=x,y=y,w=pw.box.w,h=height};
    end
    pw.configureSize = function(mapzoom)
        local bounds = pw.getBounds(mapzoom);
        pw.box.resize(bounds.w,bounds.h);
    end
    pw.box.resize(200,100); --set a fixed width that isn't the base image width
    pw.configureSize(); --call once on init
    
    pw.render = function(mapzoom)
        love.graphics.setFont(actionMenuFont);
        local bounds = pw.getBounds(mapzoom);
        pw.box.draw(bounds.x,bounds.y);
        if pw.cursorPosition ~= 0 then
            love.graphics.draw(pickWeaponCursor,bounds.x,bounds.y + (pickWeaponOptionHeight * (pw.cursorPosition-1)) + pw.box.bh);
        end
        for i=1,#pw.unit.inventory,1 do
            local wep = pw.unit.inventory[i];
            if not wep.isWeapon then
                love.graphics.setColor(1,1,1,0.5);
            end
            love.graphics.print(wep.name .. "(" .. wep.currentUses .. "/" .. wep.maxUses .. ")",bounds.x+pw.box.bw+2,bounds.y+pw.box.bh+1 + (pickWeaponOptionHeight*(i-1)));
            love.graphics.setColor(1,1,1,1);
        end
    end
    pw.moveCursor = function(dir)
        pw.cursorPosition = pw.cursorPosition + dir;
        if pw.cursorPosition < 1 then pw.cursorPosition = pw.unit.inventory.size; end
        if pw.cursorPosition > pw.unit.inventory.size then pw.cursorPosition = 1; end
        pw.toggleAttackRanges();
    end
    pw.setCursorWithMouse = function(mapzoom)
        local bounds = pw.getBounds(mapzoom);
        local mx,my = love.mouse.getPosition();
        local x = mx - bounds.x;
        if x < pw.box.bw or x > pw.box.xoffs[3] then --if we're not 
            pw.cursorPosition = 0;
            pw.toggleAttackRanges();
            return;
        end
        local y = my - bounds.y;
        local idx = math.ceil((y-pw.box.bh) / pickWeaponOptionHeight);
        if idx <= 0 or idx > pw.unit.inventory.size then
            pw.cursorPosition = 0;
            pw.toggleAttackRanges();
            return;
        end
        pw.cursorPosition = idx;
        pw.toggleAttackRanges();
    end
    pw.toggleAttackRanges = function(item)
        game.battle.clearOverlays();
        local show = pw.cursorPosition ~= 0 and pw.unit.inventory[pw.cursorPosition].isWeapon;
        if show then
            pw.cellsToCheckForAttackables = game.battle.map.getCellsInRanges(pw.unit.x,pw.unit.y,pw.unit.inventory[pw.cursorPosition].range);
            pw.cellsToCheckForAttackables.forEach(function(x) x.hitOn = true; end);
        end
    end
    pw.update = function()

    end
    return pw;
end