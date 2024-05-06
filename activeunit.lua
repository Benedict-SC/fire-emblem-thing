ActiveUnit = function(unitdata)
    local unit = {};
    unit.img = nil;
    unit.port = nil;
    unit.mapSpriteFile = unitdata.mapSpriteFile;
    unit.portraitFile = unitdata.portraitFile;

    unit.faction = unitdata.faction or "ENEMY";
    unit.used = false;

    unit.class = UnitClass();
    unit.name = unitdata.name or "Combatant";
    unit.animFilename = unitdata.animFilename or "dummy";
    unit.hp = unitdata.hp or 1;
    unit.maxhp = unitdata.maxhp or unitdata.hp or 1;
    unit.str = unitdata.str or 0;
    unit.skl = unitdata.skl or 0;
    unit.luk = unitdata.luk or 0;
    unit.spd = unitdata.spd or 0;
    unit.def = unitdata.def or 0;
    unit.res = unitdata.res or 0;
    unit.mov = unitdata.mov or 1;
    unit.con = unitdata.con or 10;
    unit.level = unitdata.level or 1;
    unit.exp = 0;

    unit.talks = arrayify(unitdata.talks);

    unit.doesCanto = function()
        return unit.class.mounted; --TODO: check if they have a canto skill or item or something
    end

    unit.inventory = Array();
    unit.getWeapons = function()
        return unit.inventory.filter(function(x) return x.isWeapon; end);
    end
    unit.equipIdx = 0;
    unit.friendly = function(otherUnit)
        local same = unit.faction == otherUnit.faction;
        local hardCodedOtherPlayerExemption = ((unit.faction == "PLAYER") and (otherUnit.faction == "OTHER"));
        return same or hardCodedOtherPlayerExemption;
    end
    unit.getRangeSpan = function(discriminatorFunction)
        if not discriminatorFunction then 
            discriminatorFunction = function() 
                return true; 
            end
        end
        local span = Array();
        for i=1,#unit.inventory,1 do
            if discriminatorFunction(unit.inventory[i]) then
                local r = unit.inventory[i].range;
                if r then
                    for j=1,#r,1 do
                        if not span.has(r[j]) then span.push(r[j]); end
                    end 
                end
            end
        end
        return span;
    end
    unit.getWeaponRanges = function()
        return unit.getRangeSpan(function(x) return x.isWeapon end);
    end
    unit.equip = function(idx)
        local item = unit.inventory[idx];
        if (item.isWeapon) then
            --TODO: check if they can actually use that weapon
            unit.equipIdx = idx;
        end
    end
    unit.equipWeapon = function(weapon)
        local itemIdx = unit.inventory.indexOf(weapon);
        if itemIdx > 0 then
            unit.equipIdx = itemIdx;
        end;
    end
    unit.getEquippedWeapon = function()
        if unit.equipIdx == 0 then return nil; end
        return unit.inventory[unit.equipIdx];
    end
    unit.equipFirstWeapon = function()
        local found = false;
        local i = 1;
        while (not found) and i <= #unit.inventory do
            if unit.inventory[i].isWeapon then
                --TODO: check if they can actually equip that weapon
                found = true;
                unit.equipIdx = 1;
            end
            i = i+1;
        end
    end
    unit.loadSprites = function()
        if unit.mapSpriteFile then
            unit.img = love.graphics.newImage(unit.mapSpriteFile);
        else
            unit.img = love.graphics.newImage("assets/img/qmark.png");
        end

        if unit.portraitFile then
            unit.port = love.graphics.newImage(unit.portraitFile);
        else
            unit.port = love.graphics.newImage("assets/img/defaultportrait.png");
        end
    end
    unit.x = unitdata.x or 1;
    unit.y = unitdata.y or 1;
    --units will be drawn on their appropriate grid cell by the map render, plus an offset for continuous movement animations
    unit.xoff = 0; 
    unit.yoff = 0;

    return unit;
end