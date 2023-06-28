fightUiBg = love.graphics.newImage("assets/img/fight-ui-bg.png");
fightUiWeaponBg = love.graphics.newImage("assets/img/fight-ui-weapon-bg.png");
fightUiBorder = love.graphics.newImage("assets/img/fight-ui-border.png");
fightHpTickWidth = 4;
fightUiSpinDuration = 0.25;
FightScreen = function(fight)
    local fs = {};
    fs.state = "SPININ"; --WINDUP, POSTIMPACT, EXP, SPINOUT, DONE
    fs.fight = fight;
    fs.canvas = love.graphics.newCanvas(gamewidth,gameheight);
    fs.spinprog = 0;
    fs.hitflash = 0;
    if not fight.agg.anim then 
        fight.agg.anim = Animation(fight.agg.animFilename);
    end
    if not fight.def.anim then
        fight.def.anim = Animation(fight.def.animFilename);
    end

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

        if (fs.goer ~= fs.fight.agg) and not fs.someoneDying then
            love.graphics.setShader(flashShader);
            love.graphics.setColor(fs.hitflash,fs.hitflash,fs.hitflash,1);
        end
        if (fs.someoneDying == fs.fight.agg) then
            love.graphics.setShader(flashShader);
            love.graphics.setColor(fs.hitflash,fs.hitflash,fs.hitflash,fs.deathAlpha);
        end
        fs.fight.agg.anim.draw(171,156,0,1,1);
        love.graphics.setShader();
        love.graphics.setColor(1,1,1,1);
        if (fs.goer == fs.fight.agg) and not fs.someoneDying then
            love.graphics.setShader(flashShader);
            love.graphics.setColor(fs.hitflash,fs.hitflash,fs.hitflash,1);
        end
        if (fs.someoneDying == fs.fight.def) then
            love.graphics.setShader(flashShader);
            love.graphics.setColor(fs.hitflash,fs.hitflash,fs.hitflash,fs.deathAlpha);
        end
        fs.fight.def.anim.draw(362 + fs.fight.def.anim.width(),156,0,-1,1);
        love.graphics.setShader();
        love.graphics.setColor(1,1,1,1);
        love.graphics.popCanvas();
        love.graphics.draw(fs.canvas,gamewidth/2,gameheight/2,-2*math.pi*fs.spinprog,fs.spinprog,fs.spinprog,gamewidth/2,gameheight/2);
    end
    fs.update = function() --do we even use this state machine?
        --[[if fs.state == "SPININ" then 

        elseif fs.state == "WINDUP" then

        elseif fs.state == "POSTIMPACT" then

        elseif fs.state == "EXP" then

        elseif fs.state == "SPINOUT"

        end]]--
    end
    fs.begin = function()
        async.doOverTime(fightUiSpinDuration,
            function(percent) 
                fs.spinprog = percent;
            end,
            function() 
                fs.spinprog = 1;
                fs.state = "WINDUP";
                fs.turnIndex = 1;
                fs.initializeAttack();
            end
        );
    end
    fs.initializeAttack = function()
        fs.goer = fs.fight.turns[fs.turnIndex];
        local wep = fs.goer.getEquippedWeapon();
        if wep and wep.currentUses <= 0 then --TODO: check if goer is immobilized somehow, too
            fs.startNextTurn();
        end
        if fs.goer == fs.fight.agg then
            fs.notGoer = fs.fight.def;
            fs.goDmg = fs.fight.aDmg;
        else
            fs.notGoer = fs.fight.agg;
            fs.goDmg = fs.fight.dDmg;
        end
        local anim = fs.goer.anim;
        anim.playXTimesAndThen("attack",10,function() --TODO: longer dummy anims, just play once
            fs.impact();
        end);
    end
    fs.impact = function()
        fs.state = "POSTIMPACT";
        local hitter = fs.goer; --make sure the reference to the animation is right even if who's going changes
        hitter.anim.playOnceAndThen("recoil",function()
            hitter.anim.setAnimation("done");
        end);
        local hits = fs.fight.hit(fs.goer);
        local rand = random099();
        if rand < hits then 
            local gotHit = fs.notGoer;
            gotHit.anim.playOnceAndThen("ouch", function()
                gotHit.anim.setAnimation("idle");
            end);
            local startHP = fs.notGoer.hp; --TODO: calculate this properly
            local endHP = fs.notGoer.hp - fs.goDmg;
            if endHP < 0 then 
                endHP = 0; 
            end
            local totalDealt = startHP - endHP;
            async.doOverTime(0.5,function(percent) 
                fs.hitflash = 1- math.abs(percent * 2 - 1);
            end,function()
                fs.hitflash = 0;
            end);
            async.doOverTime(1,function(percent) 
                fs.notGoer.hp = math.floor(endHP + ((1-percent)*totalDealt) + 0.5);
            end,function() 
                fs.notGoer.hp = endHP;
                fs.startNextTurn();
            end);
        else
            local dodged = fs.notGoer;
            dodged.anim.playOnceAndThen("dodge", function()
                dodged.anim.setAnimation("idle");
            end);
            async.wait(1,fs.startNextTurn);
        end
    end
    fs.startNextTurn = function()
        fs.turnIndex = fs.turnIndex + 1;
        if fs.turnIndex > #(fs.fight.turns) 
            or fs.fight.agg.hp <= 0 or fs.fight.def.hp <= 0 then       
            fs.endCombat();
        else
            fs.initializeAttack();
        end
    end
    fs.endCombat = function()
        if fs.fight.agg.hp <= 0 or fs.fight.def.hp <= 0 then
            if fs.fight.agg.hp <= 0 then
                fs.someoneDying = fs.fight.agg;
            else
                fs.someoneDying = fs.fight.def;
            end
            fs.deathAlpha = 1;
            --if fs.someoneDying.deathquote then --TODO: combat dialogue trigger
            async.doOverTime(0.5,function(percent) 
                fs.hitflash = 1- math.abs(percent * 2 - 1);
                if percent > 0.5 then
                    fs.deathAlpha = 1 - ((percent-0.5) * 2);
                else
                    fs.deathAlpha = 1;
                end
            end,function()
                fs.hitflash = 0;
                fs.deathAlpha = 0;
                async.wait(0.4,fs.transitionOut);
            end);
        else
            fs.transitionOut();
        end
    end
    fs.transitionOut = function()
        fs.state = "SPINOUT";
        async.doOverTime(fightUiSpinDuration,
            function(percent) 
                fs.spinprog = 1 - percent;
            end,
            function() 
                fs.spinprog = 0;
                fs.state = "DONE";
                game.battle.resolveFight();
            end
        );
    end
    return fs;
end