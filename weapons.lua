Weapon = function(rawWeapon)
    rawWeapon.range = arrayify(rawWeapon.range)
    if rawWeapon.wtype == "ITEM" then --TODO: there's non-usable held-items so check for that
        rawWeapon.usable = function() return true; end
    else
        rawWeapon.usable = function() return false; end
    end
    rawWeapon.isWeapon = (rawWeapon.wtype ~= "ITEM" and rawWeapon.wtype ~= "STAFF");
    rawWeapon.hasRange = function(range)
        return rawWeapon.range.has(range);
    end
    return rawWeapon;
end
weaponCache = {};
weaponCache.getInstance = function(wid)
    local instance = deepcopy(weaponCache[wid]);
    instance.currentUses = instance.maxUses;
    return instance;
end
equipDot = love.graphics.newImage("assets/img/equip-dot.png");
local weaponsJson = love.filesystem.read("custom/items.json");
local weaponData = json.decode(weaponsJson);
for i=1,#weaponData,1 do
    local raw = weaponData[i];
    weaponCache[raw.id] = Weapon(raw);
end