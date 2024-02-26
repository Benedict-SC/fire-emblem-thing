xpScreenBg = love.graphics.newImage("assets/img/xpbg.png");
xpScreenFont = Fonts.getFont("arial", 17);
XPScreen = function(unit,amount,callback)
    xs = {};
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
                xs.fadeOut();
            end
        end);
    end
    xs.levelUp = function()
        --TODO: level up ui
        xs.fadeOut();
    end
    xs.fadeOut = function()
        async.wait(0.8,function() 
            async.doOverTime(0.3,function(percent)
                xs.fade = 1-percent;
            end,function() 
                xs.fade = 0;
                xs.callback();
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
        local anchor = {x=gamewidth/2 - 118,y=gameheight/2-47};
        love.graphics.draw(xpScreenBg,anchor.x,anchor.y);
        love.graphics.setColor(1,0.88,0.37,1);
        love.graphics.rectangle("fill",anchor.x+54,anchor.y+41,134 * (xs.displayExp / 100),12);
        --text
        love.graphics.setFont(xpScreenFont);
        love.graphics.setColor(0.83,0.94,1,1);
        love.graphics.print(unit.class.name,anchor.x + 53,anchor.y + 13);
        love.graphics.print("Level " .. (xs.leveled and (unit.level + 1) or unit.level),anchor.x + 132,anchor.y + 13);
        if xs.leveled then
            love.graphics.print("+1",anchor.x + 172,anchor.y + 1);
        end
        --now draw all that to the previous context
        love.graphics.popCanvas();
        love.graphics.setColor(1,1,1,xs.fade);
        love.graphics.draw(xs.canvas,0,0);
        love.graphics.setColor(1,1,1,1);
    end
    return xs;
end