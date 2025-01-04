xpScreenBg = love.graphics.newImage("assets/img/xpbg.png");
xpScreenHeaderFont = Fonts.getFont("arial-b", 18);
xpScreenFont = Fonts.getFont("arial", 17);
levelScreenBg = love.graphics.newImage("assets/img/levelupbg.png");
XPScreen = function(unit,amount,callback)
    local xs = {};
    xs.unit = unit;
    xs.gain = amount;
    xs.callback = callback;

    xs.fade = 0;
    xs.canvas = love.graphics.newCanvas(gamewidth,gameheight);
    xs.startExp = unit.exp;
    xs.displayExp = unit.exp;
    xs.leveled = false;
    --cap xp at gaining at most one level
    local xptolevel = 100 - xs.startExp;
    local xpcap = xptolevel + 99;
    if xs.gain > xpcap then xs.gain = xpcap; end

    --animation control functions
    xs.fadeIn = function()
        async.doOverTime(0.3,function(percent)
            xs.fade = percent;
        end,function() 
            xs.fade = 1;
            xs.increase();
        end);
    end
    xs.increase = function()
        async.doOverTime(1.2,function(percent)
            xs.displayExp = xs.startExp + math.floor(percent*xs.gain + 0.5);
            if xs.displayExp >= 100 then
                xs.displayExp = xs.displayExp - 100;
                xs.leveled = true; --yeah this'll get set a bunch of times redundantly but idk if it matters. makes the timing logic a lot simpler and i think it's cheaper than a conditional.
            end
        end,function()
            xs.unit.exp = xs.displayExp;
            if xs.leveled then
                xs.levelUp();
            else
                xs.fadeOut(xs.callback);
            end
        end);
    end
    xs.levelUp = function()
        xs.levelScreen = LevelUpScreen(xs.unit,xs.callback,xs.canvas);
        xs.fadeOut(xs.levelScreen.fadeIn);
    end
    xs.fadeOut = function(callback)
        async.wait(0.8,function() 
            async.doOverTime(0.3,function(percent)
                xs.fade = 1-percent;
            end,function() 
                xs.fade = 0;
                callback();
            end);
        end);
    end

    --rendering time!
    xs.render = function()
        love.graphics.pushCanvas(xs.canvas);
        love.graphics.clear(0,0,0,0.2);
        love.graphics.setColor(1,1,1,1);

        --begin the render
        --bg and fill
        if xs.fade ~= 0 then
            local anchor = {x=gamewidth/2 - 118,y=gameheight/2-47};
            love.graphics.draw(xpScreenBg,anchor.x,anchor.y);
            love.graphics.setColor(1,0.88,0.37,1);
            love.graphics.rectangle("fill",anchor.x+54,anchor.y+41,134 * (xs.displayExp / 100),12);
            --text
            love.graphics.setFont(xpScreenFont);
            love.graphics.setColor(0.83,0.94,1,1);
            love.graphics.print(xs.unit.class.name,anchor.x + 53,anchor.y + 13);
            love.graphics.print("Level " .. (xs.leveled and (xs.unit.level + 1) or xs.unit.level),anchor.x + 132,anchor.y + 13);
            if xs.leveled then
                love.graphics.print("+1",anchor.x + 172,anchor.y + 1);
            end

            --now draw all that to the previous context
            love.graphics.popCanvas();
            love.graphics.setColor(1,1,1,xs.fade);
            love.graphics.draw(xs.canvas,0,0);
            love.graphics.setColor(1,1,1,1);
        elseif xs.levelScreen then
            xs.levelScreen.render();
            love.graphics.popCanvas();
            love.graphics.setColor(1,1,1,xs.levelScreen.fade);
            love.graphics.draw(xs.canvas,0,0);
            love.graphics.setColor(1,1,1,1);
        else
            love.graphics.popCanvas();
            love.graphics.setColor(1,1,1,1);
        end

    end
    return xs;
end
LevelUpScreen = function(unit,callback, canvas)
    local lus = {};
    lus.canvas = canvas;
    lus.callback = callback;
    lus.unit = unit;
    lus.fade = 0;
    lus.is = { --is == initialStats
        maxhp = {val=unit.maxhp,changed=false,amt=0,showProg=0},
        str = {val=unit.str,changed=false,amt=0,showProg=0},
        skl = {val=unit.skl,changed=false,amt=0,showProg=0},
        spd = {val=unit.spd,changed=false,amt=0,showProg=0},
        luk = {val=unit.luk,changed=false,amt=0,showProg=0},
        def = {val=unit.def,changed=false,amt=0,showProg=0},
        res = {val=unit.res,changed=false,amt=0,showProg=0},
        mov = {val=unit.mov,changed=false,amt=0,showProg=0}
    };
    --animation control functions
    lus.fadeIn = function()
        async.doOverTime(0.3,function(percent)
            lus.fade = percent;
        end,function() 
            lus.fade = 1;
            lus.levelUp();
        end);
    end
    lus.levelUp = function()
        --TODO: level up ui
        async.wait(0.5,function() 
            local results = lus.unit.levelUp();
            if results then
                local ups = Array();
                if results.maxhp > 0 then
                    ups.push({stat="maxhp",amt=results.maxhp});
                end
                if results.str > 0 then
                    ups.push({stat="str",amt=results.str});
                end
                if results.skl > 0 then
                    ups.push({stat="skl",amt=results.skl});
                end
                if results.spd > 0 then
                    ups.push({stat="spd",amt=results.spd});
                end
                if results.luk > 0 then
                    ups.push({stat="luk",amt=results.luk});
                end
                if results.def > 0 then
                    ups.push({stat="def",amt=results.def});
                end
                if results.res > 0 then
                    ups.push({stat="res",amt=results.res});
                end
                if results.mov > 0 then
                    ups.push({stat="mov",amt=results.mov});
                end
                local lastFunction = nil;
                local i = #ups;
                while i > 0 do 
                    local statRef = lus.is[ups[i].stat];
                    statRef.amt = ups[i].amt;
                    local lastOne = lastFunction;
                    local thisone;
                    if not lastFunction then
                        thisone = function()
                            statRef.changed = true;
                            async.doOverTime(0.2,function(percent) 
                                statRef.showProg = percent;
                            end,function() 
                                statRef.showProg = 1;
                            end);
                            sound.play("ding");
                            async.wait(0.8,function()
                                lus.fadeOut(lus.callback);
                            end)
                        end
                    else
                        thisone = function()
                            statRef.changed = true;
                            async.doOverTime(0.2,function(percent) 
                                statRef.showProg = percent;
                            end,function()
                                statRef.showProg = 1;
                            end);
                            sound.play("ding");
                            async.wait(0.2,lastOne);
                        end
                    end
                    lastFunction = thisone;
                    i = i - 1;
                end
                lastFunction();
            else
                lus.fadeOut(lus.callback);
            end
        end);
    end
    lus.fadeOut = function(callback)
        async.wait(0.8,function() 
            async.doOverTime(0.3,function(percent)
                lus.fade = 1-percent;
            end,function() 
                lus.fade = 0;
                callback();
            end);
        end);
    end
    --draw
    lus.render = function()
        local off2 = 120; --column 2 x offset
        local slxo = 42; --stat label x offset
        local svxo = 112; --stat value x offset
        local suxo = 132; --stat-up value x offset
        local sbyo = 39; --stat body y offset
        local voff = 25; --vertical spacing on stats

        local anchor = {x=gamewidth/2 - 158,y=gameheight/2-57};
        love.graphics.draw(levelScreenBg,anchor.x,anchor.y);
        love.graphics.setFont(xpScreenHeaderFont);
        love.graphics.setColor(0.83,0.94,1,1);
        love.graphics.print(lus.unit.name,anchor.x + 10,anchor.y + 9);
        love.graphics.print("HP",anchor.x + slxo,anchor.y + sbyo + (voff*0));
        love.graphics.print("Str",anchor.x + slxo,anchor.y + sbyo + (voff*1));
        love.graphics.print("Skl",anchor.x + slxo,anchor.y + sbyo + (voff*2));
        love.graphics.print("Spd",anchor.x + slxo,anchor.y + sbyo + (voff*3));
        love.graphics.print("Luk",anchor.x + slxo + off2,anchor.y + sbyo + (voff*0));
        love.graphics.print("Def",anchor.x + slxo + off2,anchor.y + sbyo + (voff*1));
        love.graphics.print("Res",anchor.x + slxo + off2,anchor.y + sbyo + (voff*2));
        love.graphics.print("Mov",anchor.x + slxo + off2,anchor.y + sbyo + (voff*3));
        love.graphics.setFont(xpScreenFont);
        love.graphics.print(not lus.is.maxhp.changed and lus.is.maxhp.val or lus.unit.maxhp,anchor.x+svxo,anchor.y +sbyo+(voff*0));
        love.graphics.print(not lus.is.str.changed and lus.is.str.val or lus.unit.str,anchor.x+svxo,anchor.y +sbyo+(voff*1));
        love.graphics.print(not lus.is.skl.changed and lus.is.skl.val or lus.unit.skl,anchor.x+svxo,anchor.y +sbyo+(voff*2));
        love.graphics.print(not lus.is.spd.changed and lus.is.spd.val or lus.unit.spd,anchor.x+svxo,anchor.y +sbyo+(voff*3));
        love.graphics.print(not lus.is.luk.changed and lus.is.luk.val or lus.unit.luk,anchor.x+svxo+off2,anchor.y +sbyo+(voff*0));
        love.graphics.print(not lus.is.def.changed and lus.is.def.val or lus.unit.def,anchor.x+svxo+off2,anchor.y +sbyo+(voff*1));
        love.graphics.print(not lus.is.res.changed and lus.is.res.val or lus.unit.res,anchor.x+svxo+off2,anchor.y +sbyo+(voff*2));
        love.graphics.print(not lus.is.mov.changed and lus.is.mov.val or lus.unit.mov,anchor.x+svxo+off2,anchor.y +sbyo+(voff*3));
        love.graphics.print(lus.unit.class.name,anchor.x + 143,anchor.y + 10);
        love.graphics.print("Lv",anchor.x + 220,anchor.y + 10);
        love.graphics.print(lus.unit.level,anchor.x + 236,anchor.y + 10);
        local statkeys = {"maxhp","str","skl","spd","luk","def","res","mov"};
        for i=1,#statkeys,1 do
            local col2 = i > 4;
            local yorder = math.fmod(i-1,4);
            local prog = lus.is[statkeys[i]].showProg;
            local bounce = ((-4*(prog-0.5)*(prog-0.5))+1) * 10;
            love.graphics.setColor(1,0.83,0,prog);
            love.graphics.print("+" .. lus.is[statkeys[i]].amt,anchor.x + suxo + (col2 and off2 or 0),anchor.y + sbyo + (yorder * voff) - bounce);
        end
        
    end
    return lus;
end