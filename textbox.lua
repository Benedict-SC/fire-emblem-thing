textboxImg = love.graphics.newImage("assets/img/textbg.png");
TEXT_MIN_CHARS_TO_SPEED = 6;
TEXT_SPEED = 0.5;
TEXT_FASTSPEED = 2.5;
TextBox = function()
    local tb = {};
    tb.state = "TRANSITION"; --WRITE, HOLD, SELECT
    tb.calligrapher = TextDrawer({x=42,y=215,w=500,h=150})
    tb.box = MenuBox(textboxImg,17,19);
    tb.box.resize(gamewidth-50,gameheight-200);
    tb.box.y = gameheight + 1;
    tb.portraits = Array();
    tb.registerPortrait = function(id,versions,x,active,reversed)
        local tbp = TextBoxPortrait(versions);
        tbp.x = x or 0;
        tbp.active = active or false;
        tbp.reversed = reversed or false;
        tb.portraits[id] = tbp;
        tb.portraits.push(tbp);
    end

    tb.charMax = 0;

    tb.testString = "some <b>bold</b> <c=#00DD66><i>green italic</i></c> <b><i>bolditalic</i></b> <c=#00AAFF>text</c> that goes on for a little <b>while</b> and would do some wrapping. it's going to get cut off at 120 characters, i think, so add a bunch more characters to the string.";
    --tb.calligrapher.fstrings = TextFormatter.getFormattedStrings(tb.testString);
    tb.setLine = function(lineObj)
        tb.calligrapher.fstrings = TextFormatter.getFormattedStrings(lineObj.text);
        tb.charMax = TextFormatter.formattedStringLength(tb.calligrapher.fstrings);
        tb.calligrapher.charsDrawn = 0;
    end
    --tb.setLine({text = tb.testString});

    tb.render = function()
        for i=1,#(tb.portraits),1 do
            tb.portraits[i].render();
        end
        love.graphics.setColor(1,1,1);
        tb.box.draw(25,tb.box.y);
        if tb.state ~= "TRANSITION" then
            if tb.calligrapher.fstrings then
                tb.calligrapher.draw();
            end
        end
    end
    tb.rise = function(whendone)
        async.doOverTime(0.2,function(percent) 
            tb.box.y = gameheight - math.floor(percent * tb.box.h);
            for k,v in ipairs(tb.portraits) do
                v.y = gameheight - (percent * v.img:getHeight());
            end
        end,function() 
            whendone();
            tb.box.y = gameheight - tb.box.h;
            for k,v in ipairs(tb.portraits) do
                v.y = gameheight - v.img:getHeight();
            end
            tb.state = "WRITE"; 
        end);
    end
    tb.fall = function(whendone)
        async.doOverTime(0.2,function(percent) 
            tb.box.y = (gameheight - tb.box.h) + math.floor(percent * tb.box.h);
            for k,v in ipairs(tb.portraits) do
                v.y = gameheight - v.img:getHeight() + (percent * gameheight); --this is technically incorrect but unnoticeable and more efficient than polling getHeight() twice probably.
            end
        end,function() 
            tb.box.y = gameheight + 1;
            for k,v in ipairs(tb.portraits) do
                v.y = gameheight + 1
            end
            if whendone then whendone(); end
        end);
    end
	tb.speed_60fps = 10;
    tb.update = function()
        if tb.state == "WRITE" then
            if tb.calligrapher.charsDrawn < tb.charMax then
                local dt = love.timer.getDelta();
                local charspeed = ((input.action or input.cancel) and tb.calligrapher.charsDrawn > TEXT_MIN_CHARS_TO_SPEED) and TEXT_FASTSPEED or TEXT_SPEED;
                charspeed = charspeed * dt * gameFPS;
                tb.calligrapher.charsDrawn = tb.calligrapher.charsDrawn + charspeed;
                if pressedThisFrame["menu"] then
                    box.td.charsDrawn = box.charMax;
                end
            else
                tb.state = "HOLD";
            end
        end
    end
    tb.highlightOne = function(portId) 
        for id,port in pairs(tb.portraits) do
            if not tonumber(id) and type(port) == "table" then --skip the numeric keys
                port.lit = false;
                if id == portId then
                    port.lit = true;
                end
            end
        end
    end
    return tb;
end

MidbattleTextBox = function()
    local tb = TextBox();
    tb.boxheight = 130;
    tb.calligrapher = TextDrawer({x=125,y=13,w=466,h=93});
    tb.box = MenuBox(textboxImg,17,19);
    tb.box.resize(gamewidth-10,tb.boxheight);
    tb.box.y = -tb.boxheight;

    tb.litPortrait = nil;
    tb.render = function()
        love.graphics.setColor(1,1,1);
        tb.box.draw(10,tb.box.y);
        if tb.state ~= "TRANSITION" then
            if tb.calligrapher.fstrings then
                tb.calligrapher.draw();
            end
        end
        if tb.litPortrait then
            local clipQuad = love.graphics.newQuad(0,0,100,100,tb.litPortrait.img:getWidth(),tb.litPortrait.img:getHeight());
            tb.litPortrait.render(20,20,clipQuad);
        end
    end
    tb.rise = function(whendone)
        async.doOverTime(0.2,function(percent) 
            tb.box.y = -tb.boxheight + math.floor(percent * tb.boxheight);
        end,function() 
            whendone();
            tb.box.y = 0;
            tb.state = "WRITE"; 
        end);
    end
    tb.fall = function(whendone)
        tb.litPortrait = nil;
        async.doOverTime(0.2,function(percent) 
            tb.box.y = -math.floor(percent * tb.boxheight);
        end,function() 
            tb.box.y = -tb.boxheight
            if whendone then whendone(); end
        end);
    end
    tb.highlightOne = function(portId) 
        for id,port in pairs(tb.portraits) do
            if not tonumber(id) and type(port) == "table" then --skip the numeric keys
                port.lit = false;
                if id == portId then
                    port.lit = true;
                    tb.litPortrait = port;
                end
            end
        end
    end
    return tb;
end
TextBoxPortrait = function(versions)
    local tbp = {};
    tbp.x = 0;
    tbp.y = gameheight;
    tbp.reversed = false;
    tbp.active = false;
    tbp.lit = false;
    tbp.versions = {};
    for id,filepath in pairs(versions) do
        tbp.versions[id] = love.graphics.newImage(filepath .. ".png");
    end
    tbp.portCode = "default";
    tbp.img = tbp.versions[tbp.portCode];
    tbp.render = function(x,y,quad)
        if not tbp.active then
            return;
        end
        --DEBUG_TEXT = "let's try to render image with width" .. tbp.img:getWidth();
        if tbp.lit then
            love.graphics.setColor(1,1,1);
        else
            love.graphics.setColor(0.6,0.6,0.6);
        end
        if quad then
            love.graphics.draw(tbp.img,quad,x and x or tbp.x,y and y or tbp.y);
        else
            love.graphics.draw(tbp.img,x and x or tbp.x,y and y or tbp.y);
        end
    end
    return tbp;
end