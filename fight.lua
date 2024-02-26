require("menubox");
fightUIBG = love.graphics.newImage("assets/img/combat-preview.png");
fightX2Icon = love.graphics.newImage("assets/img/x2.png");
fightX4Icon = love.graphics.newImage("assets/img/x4.png");
fiteHites = {57,88,124,158}; --y
fiteSites = {22,55,92}; --x
Fight = function(aggressor,defender)
    local fight = {};
    fight.agg = aggressor;
    fight.def = defender;

    fight.renderPreview = function()
        love.graphics.setColor(1,1,1,1);
        love.graphics.draw(fightUIBG,10,10);
        love.graphics.print(fight.agg.getEquippedWeapon().name,43,30);
        local dw = fight.def.getEquippedWeapon();
        if dw then
            love.graphics.print(fight.def.getEquippedWeapon().name,18,180);
        end
        love.graphics.setColor(0,0,0,1);
        love.graphics.print(fight.aHP,fiteSites[3],fiteHites[1]);
        love.graphics.print(" HP",fiteSites[2],fiteHites[1]);
        love.graphics.print(fight.dHP == -1 and "--" or fight.dHP,fiteSites[1],fiteHites[1]);
        love.graphics.print(fight.aDmg,fiteSites[3],fiteHites[2]);
        love.graphics.print("Dmg",fiteSites[2],fiteHites[2]);
        love.graphics.print(fight.dDmg == -1 and "--" or fight.dDmg,fiteSites[1],fiteHites[2]);
        love.graphics.print(fight.aHit,fiteSites[3],fiteHites[3]);
        love.graphics.print("Hit",fiteSites[2],fiteHites[3]);
        love.graphics.print(fight.dHit == -1 and "--" or fight.dHit,fiteSites[1],fiteHites[3]);
        love.graphics.print(fight.aCrit,fiteSites[3],fiteHites[4]);
        love.graphics.print("Crit",fiteSites[2],fiteHites[4]);
        love.graphics.print(fight.dCrit == -1 and "--" or fight.dCrit,fiteSites[1],fiteHites[4]);
        love.graphics.setColor(1,1,1,1);
        if fight.doTheyDouble(true) then
            local icon = fightX2Icon;
            if(fight.agg.getEquippedWeapon().brave) then
                icon = fightX4Icon;
            end
            love.graphics.draw(icon,fiteSites[3]+17,fiteHites[2]+9);
        else --if there's a brave weapon it still might double so take that into account
            if(fight.agg.getEquippedWeapon().brave) then
                love.graphics.draw(fightX2Icon,fiteSites[3]+17,fiteHites[2]+9);
            end
        end
        if fight.doTheyDouble(false) and fight.dDmg > -1 then 
            local icon = fightX2Icon;
            if(fight.def.getEquippedWeapon().brave) then
                icon = fightX4Icon;
            end
            love.graphics.draw(icon,fiteSites[1]+17,fiteHites[2]+9);
        else
            if(fight.def.getEquippedWeapon()) then --again, check if a brave weapon is in play
                if(fight.def.getEquippedWeapon().brave) then
                    love.graphics.draw(fightX2Icon,fiteSites[1]+17,fiteHites[2]+9);
                end
            end
        end
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
    fight.calculateXP = function(player,killed,damaged)
        if not damaged then return 1; end

        local enemy = fight.agg; --let's guess the player was attacking and then course correct
        if player == fight.agg then enemy = fight.def; end --good ol' process of elimination
        local levelDifference = (enemy.level + (20*(enemy.class.tier-1))) - (player.level + (20*(player.class.tier-1)));
        local modeBonus = 20; --TODO: hook this up to a difficulty setting somehow
        local baseXP = math.floor((21 + levelDifference)/2 + 0.5);

        if killed then
            return baseXP + levelDifference + modeBonus; --plus extra stuff if they were a boss or whatever, TODO
        else
            return baseXP;
        end
    end
    fight.attackSpeed = function(unit,weapon)
        local aw = unit.getEquippedWeapon();
        if not aw then return unit.spd; end --if no weapon, no weight malus
        local aWeightMalus = aw.weight - unit.str; --unit.con???
        if aWeightMalus < 0 then aWeightMalus = 0; end
        return unit.spd - aWeightMalus;
    end
    fight.defenderCanCounter = function()
        local dist = manhattan(fight.agg,fight.def);
        local dwep = fight.def.getEquippedWeapon();
        if not dwep then return false; end
        return dwep.range.has(dist);
    end
    fight.aHP = fight.agg.hp;
    fight.dHP = fight.def.hp;
    fight.aDmg = fight.calculateDamage(true);
    fight.dDmg = fight.calculateDamage(false);
    fight.aHit = fight.calculateHit(true);
    fight.dHit = fight.calculateHit(false);
    fight.aCrit = fight.calculateCrit(true);
    fight.dCrit = fight.calculateCrit(false);
    fight.hp = function(unit)
        if unit == fight.agg then return fight.aHP; end
        if unit == fight.def then return fight.dHP; end
        return 0;
    end
    fight.hit = function(unit)
        if unit == fight.agg then return fight.aHit; end
        if unit == fight.def then return fight.dHit; end
        return 0;
    end
    fight.crit = function(unit)
        if unit == fight.agg then return fight.aCrit; end
        if unit == fight.def then return fight.dCrit; end
        return 0;
    end
    fight.dmg = function(unit)
        if unit == fight.agg then return fight.aDmg; end
        if unit == fight.def then return fight.dDmg; end
        return 0;
    end
    if not fight.defenderCanCounter() then
        fight.dDmg = -1;
        fight.dHit = -1;
        fight.dCrit = -1;
    end

    fight.turns = Array();
    if true then --TODO: replace true with a check of the defending unit's skills for Vantage
        fight.turns.push(fight.agg);
        if fight.agg.getEquippedWeapon().brave then
            fight.turns.push(fight.agg);
        end
    end
    if fight.defenderCanCounter() then --TODO: put an "and they don't have vantage and so didn't go already" check here
        fight.turns.push(fight.def);
        if fight.def.getEquippedWeapon().brave then
            fight.turns.push(fight.def);
        end
    end
    if fight.doTheyDouble(true) then
        fight.turns.push(fight.agg);
        if fight.agg.getEquippedWeapon().brave then
            fight.turns.push(fight.agg);
        end
    end
    if fight.defenderCanCounter() and fight.doTheyDouble(false) then
        fight.turns.push(fight.def);
        local wep = fight.def.getEquippedWeapon();
        if wep and wep.brave then
            fight.turns.push(fight.def);
        end
    end


    return fight;
end