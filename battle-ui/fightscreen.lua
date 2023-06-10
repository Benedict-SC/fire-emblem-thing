fightUiBg = love.graphics.newImage("assets/img/fight-ui-bg.png");
fightUiWeaponBg = love.graphics.newImage("assets/img/fight-ui-weapon-bg.png");
fightUiBorder = love.graphics.newImage("assets/img/fight-ui-border.png");
fightHpTickWidth = 4;
FightScreen = function(fight)
    local fs = {};
    fs.fight = fight;
    fs.canvas = love.graphics.newCanvas(gamewidth,gameheight);
    fs.spinprog = 0;
    fs.aggAnimation = Animation(fight.agg.animFilename);
    fs.defAnimation = Animation(fight.def.animFilename);

    fs.render = function()
        love.graphics.pushCanvas(fs.canvas);
        love.graphics.clear(0,0,0,0.3);
        --right side: defender
        --set background colors
        if fs.fight.def.faction == "ENEMY" then
            love.graphics.setColor(0.64,0,0,1);
        elseif fs.fight.def.faction == "PLAYER" then
            love.graphics.setColor(0,0.24,0.52,1);
        else 
            love.graphics.setColor(0,0.52,0.27,1);
        end
        --draw background ui
        love.graphics.draw(fightUiBg,0,0);
        love.graphics.draw(fightUiWeaponBg,0,0);
        love.graphics.setColor(1,1,1,1);
        love.graphics.draw(fightUiBorder,0,0);
        --print values
        love.graphics.print(fs.fight.def.name,474,48);
        local dwep = fs.fight.def.getEquippedWeapon();
        if dwep then
            love.graphics.draw(dwep.img,325,305);
        end
        love.graphics.print(dwep and dwep.name or "---",350,308);
        love.graphics.print("HIT " .. ((fs.fight.dHit ~= -1) and fs.fight.dHit or "--"),509,250);
        love.graphics.print("DMG " .. ((fs.fight.dDmg ~= -1) and fs.fight.dDmg or "--"),509,270);
        love.graphics.print("CRT " .. ((fs.fight.dCrit ~= -1) and fs.fight.dCrit or "--"),509,290);
        --hp display
        love.graphics.print(fs.fight.def.hp,328,364);
        love.graphics.setColor(0.05,0.22,0,1);
        love.graphics.rectangle("fill",350,366,fightHpTickWidth*fs.fight.def.maxhp,12);
        love.graphics.setColor(0.19,0.9,0,1);
        love.graphics.rectangle("fill",350,366,fightHpTickWidth*fs.fight.def.hp,12);


        --left side: attacker
        --set background colors
        if fs.fight.agg.faction == "ENEMY" then
            love.graphics.setColor(0.64,0,0,1);
        elseif fs.fight.agg.faction == "PLAYER" then
            love.graphics.setColor(0,0.24,0.52,1);
        else 
            love.graphics.setColor(0,0.52,0.27,1);
        end
        --draw background ui
        love.graphics.draw(fightUiBg,gamewidth,0,0,-1,1);
        love.graphics.draw(fightUiWeaponBg,gamewidth,0,0,-1,1);
        love.graphics.setColor(1,1,1,1);
        love.graphics.draw(fightUiBorder,gamewidth,0,0,-1,1);
        --print values
        love.graphics.print(fs.fight.agg.name,15,48);
        local awep = fs.fight.agg.getEquippedWeapon();
        if awep then
            love.graphics.draw(awep.img,115,305);
        end
        love.graphics.print(awep and awep.name or "---",140,308);
        love.graphics.print("HIT " .. fs.fight.aHit,11,250);
        love.graphics.print("DMG " .. fs.fight.aDmg,11,270);
        love.graphics.print("CRT " .. fs.fight.aCrit,11,290);
        --hp display
        love.graphics.print(fs.fight.agg.hp,28,364);
        love.graphics.setColor(0.05,0.22,0,1);
        love.graphics.rectangle("fill",50,366,fightHpTickWidth*fs.fight.agg.maxhp,12);
        love.graphics.setColor(0.19,0.9,0,1);
        love.graphics.rectangle("fill",50,366,fightHpTickWidth*fs.fight.agg.hp,12);


        love.graphics.setColor(1,1,1,1);
        fs.aggAnimation.draw(171,156,0,1,1);
        fs.aggAnimation.setAnimation("wiggle");
        fs.defAnimation.draw(362 + fs.defAnimation.width(),156,0,-1,1);
        love.graphics.popCanvas();
        love.graphics.draw(fs.canvas,gamewidth/2,gameheight/2,-2*math.pi*fs.spinprog,fs.spinprog,fs.spinprog,gamewidth/2,gameheight/2);
    end
    fs.update = function()
    end
    return fs;
end