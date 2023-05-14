Item = function()
    local item = {};
    item.name = "Generic Item";
    item.iconfile = "assets/img/qmark-tiny.png";
    item.maxUses = 40;
    item.goldValue = 200;
    item.usable = function()
        return true;
    end
    item.use = function()
        --nothing by default
    end
    item.isWeapon = false;
    return item;
end
itemCache = {};
itemCache.getInstance = function(wid)
    local instance = deepcopy(itemCache[wid]);
    instance.currentUses = instance.maxUses;
    return instance;
end
--PRESET ITEM DATA
itemCache["Vulnerary"] = Item();
itemCache["Vulnerary"].name = "Vulnerary";
itemCache["Vulnerary"].iconfile = "assets/img/vulnerary.png";
itemCache["Vulnerary"].maxUses = 8;