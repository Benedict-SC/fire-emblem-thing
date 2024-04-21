Weapon = function(rawWeapon)
    --[[local wepon = {};
    wepon.name = "Generic Weapon";
    wepon.iconfile = "assets/img/qmark-tiny.png";
    wepon.wtype = "NONE";
    wepon.might = 0;
    wepon.rank = "E";
    wepon.hit = 80;
    wepon.crit = 0;
    wepon.weight = 8;
    wepon.range = arrayify({1});
    wepon.maxUses = 40;
    wepon.goldValue = 200;
    wepon.usable = function()
        return false;
    end
    wepon.isWeapon = true;
    wepon.brave = false;
    return wepon;--]]
    rawWeapon.range = arrayify(rawWeapon.range)
    if rawWeapon.wtype == "ITEM" then --TODO: there's non-usable held-items so check for that
        rawWeapon.usable = function() return true; end
    else
        rawWeapon.usable = function() return false; end
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