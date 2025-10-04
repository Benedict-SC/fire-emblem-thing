Item = function()
    local item = {};
    item.name = "Generic Item";
    item.iconfile = "assets/img/qmark-tiny.png";
    item.maxUses = 40;
    item.currentUses = item.maxUses;
    item.goldValue = 200;
    item.usable = function()
        return false;
    end
    function item:use(callback)
        --nothing by default
        callback();
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
itemCache["Vulnerary"].currentUses = 8;
itemCache["Vulnerary"].usable = function() return true; end
itemCache["Vulnerary"].use = function(self,callback)
    self.currentUses = self.currentUses - 1;
    if self.currentUses == 0 then
        --TODO: item breakage display. wrap the callback.
    end
    game.battle.itemOptionsMenu.unit.itemHeal(10,callback);
end