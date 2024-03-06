UnitData = {};
UnitData.loadArmyFromSaveFile = function(saveFileName)
    local jsonstring = love.filesystem.read("saves/" .. saveFileName);
    local data = json.decode(jsonstring);
    UnitData.army = arrayify(data.army);
    UnitData.army.forEach(function(x) 
        UnitData.army[x.id] = x; --key by id
    end);
end
UnitData.loadArmyDataToMapData = function(mapdata) 
    mapdata.forEach(function(x) 
        if x.armyId then
            local aunit = UnitData.army[x.armyId];
            x.faction = "PLAYER";
            x.trueSelf = aunit;
            x.mapSpriteFile = aunit.mapSpriteFile;
            x.portraitFile = aunit.portraitFile;
            x.classPreset = aunit.classPreset;
            x.name = aunit.name;
            x.presetWeapons = aunit.weapons;
            x.presetItems = aunit.items;
            x.maxhp = aunit.maxhp;
            x.hp = aunit.maxhp;
            x.mov = aunit.mov;
            x.str = aunit.str;
            x.skl = aunit.skl;
            x.spd = aunit.spd;
            x.luk = aunit.luk;
            x.def = aunit.def;
            x.res = aunit.res;
            x.con = aunit.con;
            x.level = aunit.level;
        end
    end);
end
