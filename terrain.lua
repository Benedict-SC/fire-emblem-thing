movementTypes = {"FOOT","HORSE","MAGIC","FLYING"};
terrain = Array();
local terrainJson = love.filesystem.read("defaults/terrain.json");
local terrainData = json.decode(terrainJson);
terrainImages = Array();
for i=1,#terrainData,1 do
    local terrainObj = {};
    terrainObj.name = terrainData[i].name;
    terrainObj.costs = terrainData[i].costs;
    terrainObj.costToEnter = function(movtype)
        local cost = terrainObj.costs[movType];
        if not cost then 
            cost = terrainObj.costs["default"];
        end
        return cost;
    end
    terrain.push(terrainObj);
    terrainImages.push(love.graphics.newImage(terrainData[i].imgPath));
end
nativeTerrainLength = #terrain;
local customTerrainJson = love.filesystem.read("custom/terrain.json");
local customTerrainData = json.decode(customTerrainJson);
for i=1,#customTerrainData,1 do
    local terrainObj = {};
    terrainObj.name = customTerrainData[i].name;
    terrainObj.costs = customTerrainData[i].costs;
    terrainObj.costToEnter = function(movtype)
        local cost = terrainObj.costs[movType];
        if not cost then 
            cost = terrainObj.costs["default"];
        end
        return cost;
    end
    terrain.push(terrainObj);
    terrainImages[1000 + i] = love.graphics.newImage(terrainData[i].imgPath);
end
--[[terrain = {
    {name="Grass",costToEnter = function(movtype) 
        return 1;
    end},
    {name="Forest",costToEnter = function(movtype) 
        if (movtype == "FLYING") then return 1; end
        return 2;
    end},
    {name="Hills",costToEnter = function(movtype) 
        if (movtype == "FLYING") then return 1; end
        return 3;
    end},
    {name="Sand",costToEnter = function(movtype) 
        if (movtype == "FLYING") then return 1; end
        if (movtype == "MAGIC") then return 1; end
        if (movtype == "FOOT") then return 2; end
        return 3;
    end},
    {name="Wall",costToEnter = function(movtype) 
        if (movtype == "FLYING") then return 1; end
        return 999; --no way jose
    end},
    {name="HighWall",costToEnter = function(movtype) 
        return 999; --not even flying dudes
    end}
};]]--
