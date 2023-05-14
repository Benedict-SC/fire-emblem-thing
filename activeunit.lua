ActiveUnit = function(unitdata)
    local unit = {};
    unit.img = nil;
    unit.port = nil;
    unit.mapSpriteFile = unitdata.mapSpriteFile;
    unit.portraitFile = unitdata.portraitFile;
    unit.class = UnitClass();
    unit.name = unitdata.name or "Combatant";
    unit.faction = "ENEMY";
    unit.friendly = false;
    unit.hp = unitdata.hp or 1;
    unit.maxhp = unitdata.maxhp or 1;
    unit.str = unitdata.str or 0;
    unit.skl = unitdata.skl or 0;
    unit.luk = unitdata.luk or 0;
    unit.def = unitdata.def or 0;
    unit.res = unitdata.res or 0;
    unit.mov = unitdata.mov or 1;
    unit.con = unitdata.con or 10;
    unit.level = 1;
    unit.exp = 0;
    unit.inventory = Array();
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
makeActiveFromTemplate = function(tunit)
    local unit = ActiveUnit({});
    unit.class = tunit.class;
    unit.name = tunit.name;
    unit.faction = tunit.faction;
    unit.hp = tunit.maxhp;
    unit.maxhp = tunit.maxhp;
    unit.str = tunit.str;
    unit.skl = tunit.skl;
    unit.luk = tunit.luk;
    unit.def = tunit.def;
    unit.res = tunit.res;
    unit.mov = tunit.mov;
    unit.con = tunit.con;
    unit.level = tunit.level;
    unit.exp = tunit.exp;
    return unit;
end