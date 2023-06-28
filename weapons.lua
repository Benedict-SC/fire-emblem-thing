Weapon = function()
    local wepon = {};
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
    return wepon;
end
weaponCache = {};
weaponCache.getInstance = function(wid)
    local instance = deepcopy(weaponCache[wid]);
    instance.currentUses = instance.maxUses;
    return instance;
end
equipDot = love.graphics.newImage("assets/img/equip-dot.png");
--PRESET WEAPON DATA
--SWORDS
weaponCache["IronSword"] = Weapon();
weaponCache["IronSword"].name = "Iron Sword";
weaponCache["IronSword"].wtype = "SWORD";
weaponCache["IronSword"].iconfile = "assets/img/sword.png";
weaponCache["IronSword"].might = 5;
weaponCache["IronSword"].hit = 90;
weaponCache["IronSword"].weight = 7;

weaponCache["BraveSword"] = Weapon();
weaponCache["BraveSword"].name = "Brave Sword";
weaponCache["BraveSword"].wtype = "SWORD";
weaponCache["BraveSword"].might = 9;
weaponCache["BraveSword"].hit = 75;
weaponCache["BraveSword"].brave = true;
weaponCache["BraveSword"].rank = "B";
weaponCache["BraveSword"].weight = 16;
weaponCache["BraveSword"].maxUses = 30;

weaponCache["TrashSword"] = Weapon();
weaponCache["TrashSword"].name = "Trash Sword";
weaponCache["TrashSword"].wtype = "SWORD";
weaponCache["TrashSword"].iconfile = "assets/img/sword.png";
weaponCache["TrashSword"].might = 3;
weaponCache["TrashSword"].hit = 30;
weaponCache["TrashSword"].weight = 5;
weaponCache["TrashSword"].maxUses = 2;

--LANCES
weaponCache["IronLance"] = Weapon();
weaponCache["IronLance"].name = "Iron Lance";
weaponCache["IronLance"].wtype = "LANCE";
weaponCache["IronLance"].iconfile = "assets/img/lance.png";
weaponCache["IronLance"].might = 7;

weaponCache["SteelLance"] = Weapon();
weaponCache["SteelLance"].name = "Steel Lance";
weaponCache["SteelLance"].wtype = "LANCE";
weaponCache["SteelLance"].iconfile = "assets/img/lance.png";
weaponCache["SteelLance"].might = 10;
weaponCache["SteelLance"].rank = "D";
weaponCache["SteelLance"].hit = 70;
weaponCache["SteelLance"].weight = 13;
weaponCache["SteelLance"].maxUses = 30;

weaponCache["Javelin"] = Weapon();
weaponCache["Javelin"].name = "Javelin";
weaponCache["Javelin"].wtype = "LANCE";
weaponCache["Javelin"].iconfile = "assets/img/lance.png";
weaponCache["Javelin"].might = 6;
weaponCache["Javelin"].rank = "D";
weaponCache["Javelin"].range = Array(1,2);
weaponCache["Javelin"].hit = 60;
weaponCache["Javelin"].weight = 11;
weaponCache["Javelin"].maxUses = 25;

--BOWS
weaponCache["IronBow"] = Weapon();
weaponCache["IronBow"].name = "Iron Bow";
weaponCache["IronBow"].wtype = "BOW";
weaponCache["IronBow"].iconfile = "assets/img/bow.png";
weaponCache["IronBow"].might = 6;
weaponCache["IronBow"].hit = 85;
weaponCache["IronBow"].range = Array(2);
weaponCache["IronBow"].weight = 5;

--DARK MAGIC
weaponCache["Flux"] = Weapon();
weaponCache["Flux"].name = "Flux";
weaponCache["Flux"].wtype = "DARK";
weaponCache["Flux"].iconfile = "assets/img/book.png";
weaponCache["Flux"].might = 7;
weaponCache["Flux"].hit = 70;
weaponCache["Flux"].crit = 5;
weaponCache["Flux"].range = Array(1,2);
weaponCache["Flux"].weight = 3;