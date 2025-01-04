Unit = function(unitdata)
    local unit = {};
    unit.img = nil;
    unit.port = nil;
    unit.mapSpriteFile = unitdata.mapSpriteFile;
    unit.portraitFile = unitdata.portraitFile;

    unit.faction = unitdata.faction or "ENEMY";
    unit.aiStrategy = unitdata.aiStrategy or "AGGRO";
    unit.aiTactics = unitdata.aiTactics or "NORMAL";
    unit.aiObjectiveId = unitdata.aiObjectiveId;
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
    unit.maxhpGrowth = unitdata.mhpg or 50;
    unit.strGrowth = unitdata.strg or 30;
    unit.sklGrowth = unitdata.sklg or 40;
    unit.lukGrowth = unitdata.lukg or 20;
    unit.spdGrowth = unitdata.spdg or 30;
    unit.defGrowth = unitdata.defg or 30;
    unit.resGrowth = unitdata.resg or 20;
    unit.exp = 0;

    unit.talks = unitdata.talks and arrayify(unitdata.talks) or nil;
    unit.battleTalks = unitdata.battleTalks and arrayify(unitdata.battleTalks) or nil;

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
    unit.levelUp = function()
        local maxHpUp = unit.randomGrowthAmount("maxhpGrowth");
        unit.maxhp = unit.maxhp + maxHpUp;
        local strUp = unit.randomGrowthAmount("strGrowth");
        unit.str = unit.str + strUp;
        local sklUp = unit.randomGrowthAmount("sklGrowth");
        unit.skl = unit.skl + sklUp;
        local spdUp = unit.randomGrowthAmount("spdGrowth");
        unit.spd = unit.spd + spdUp;
        local lukUp = unit.randomGrowthAmount("lukGrowth");
        unit.luk = unit.luk + lukUp;
        local defUp = unit.randomGrowthAmount("defGrowth");
        unit.def = unit.def + defUp;
        local resUp = unit.randomGrowthAmount("resGrowth");
        unit.res = unit.res + resUp;
        return {maxhp=maxHpUp,str=strUp,skl=sklUp,spd=spdUp,luk=lukUp,def=defUp,res=resUp,mov=--[[movUp--]]0}; --if this is received, the handler should handle what happens if a unit with no template levels up
    end
    unit.randomGrowthAmount = function(growthname)
        local rand = random099();
        rand = rand + unit[growthname];
        DEBUG_TEXT = DEBUG_TEXT .. math.floor(rand) .. "/";
        return math.floor(rand / 100);
    end

    return unit;
end