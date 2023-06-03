require("menubox");
fightDefBoxImg = love.graphics.newImage("assets/img/sliceablemenu.png");
fightAggBoxImg = love.graphics.newImage("assets/img/sliceablemenu.png");
fightUIBG = love.
Fight = function(aggressor,defender)
    local fight = {};
    fight.agg = aggressor;
    fight.def = defender;

    fight.renderPreview = function()

    end
    fight.calculateDamage = function(attacker)
        local a = attacker and fight.agg or fight.def;
        local d = attacker and fight.def or fight.agg;
        local aw = a.getEquippedWeapon();
        if not aw then return -1; end --if you don't have a weapon equipped, you don't even hit
        local dw = d.getEquippedWeapon();
        local output = aw.might + a.str;
        local mitigation = d.def;
        --TODO: local triangleBonus =  calculate that somehow;
        local dmg = output - mitigation;
        if dmg < 0 then dmg = 0; end
        return dmg;
    end
    fight.doTheyDouble = function(attacker)
        local a = attacker and fight.agg or fight.def;
        local d = attacker and fight.def or fight.agg;
        local aw = a.getEquippedWeapon();
        if not aw then return -1; end --if you don't have a weapon equipped, you don't even hit
        local dw = d.getEquippedWeapon();
        local aAS = fight.attackSpeed(a,aw);
        local dAS = fight.attackSpeed(d,dw);
        return aAS > dAS + 3;
    end
    fight.calculateHit = function(attacker)
        local a = attacker and fight.agg or fight.def;
        local d = attacker and fight.def or fight.agg;
        local aw = a.getEquippedWeapon();
        if not aw then return -1; end --if you don't have a weapon equipped, you don't even hit
        local dw = d.getEquippedWeapon();
        local accuracy = aw.hit + (a.skl*2) + a.luk; --TODO: weapon triangle, supports, etc
        local avoid = fight.attackSpeed(d,dw)*2 + d.luk; --TODO: terrain, weapon triangle, supports, etc
        local chance = accuracy - avoid;
        if chance < 0 then chance = 0; end
        if chance > 100 then chance = 100; end
        return chance;
    end
    fight.calculateCrit = function(attacker)
        local a = attacker and fight.agg or fight.def;
        local d = attacker and fight.def or fight.agg;
        local aw = a.getEquippedWeapon();
        if not aw then return -1; end --if you don't have a weapon equipped, you don't even hit
        local crit = aw.crit + math.ceil(a.skl / 2); --TODO: supports
        crit = crit - d.luk; --TODO: supports
        if crit < 0 then crit = 0; end
        if crit > 100 then crit = 100; end
        return crit;

    end
    fight.attackSpeed = function(unit,weapon)
        local a = attacker and fight.agg or fight.def;
        local aw = a.getEquippedWeapon();
        if not aw then return a.spd; end --if no weapon, no weight malus
        local aWeightMalus = aw.weight - a.str; --a.con???
        if aWeightMalus < 0 then aWeightMalus = 0; end
        return a.spd - aWeightMalus;
    end
    fight.aHP = fight.agg.hp;
    fight.dHP = fight.def.hp;
    fight.aDmg = fight.calculateDamage(true);
    fight.dDmg = fight.calculateDamage(false);
    fight.aHit = fight.calculateHit(true);
    fight.dHit = fight.calculateHit(false);
    fight.aCrit = fight.calculateCrit(true);
    fight.dCrit = fight.calculateCrit(false);
    return fight;
end