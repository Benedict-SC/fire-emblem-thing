textboxImg = love.graphics.newImage("assets/img/textbg.png");
TextBox = function()
    local tb = {};
    tb.box = MenuBox(textboxImg,17,19);
    tb.calligrapher = TextDrawer({x=40,y=215,w=500,h=150},nil,120)
    tb.box.resize(gamewidth-50,gameheight-200);
    tb.portraits = Array();
    tb.registerPortrait = function(id,filepath)
        local tbp = TextBoxPortrait(filepath);
        tb.portraits[id] = tbp;
        tb.portraits.push(tbp);
    end
    tb.registerPortrait("default","assets/img/herotall.png");

    -- v TODO: remove after testing:
    tb.portraits["default"].active = true;
    tb.portraits["default"].lit = true;
    tb.registerPortrait("archer","assets/img/archtall.png");
    tb.portraits["archer"].active = true;
    tb.portraits["archer"].x = 300;
    -- ^ TODO: remove after testing:

    tb.testString = "some <b>bold</b> <c=#00DD66><i>green italic</i></c> <b><i>bolditalic</i></b> <c=#00AAFF>text</c> that goes on for a little <b>while</b> and would do some wrapping. it's going to get cut off at 120 characters, i think, so add a bunch more characters to the string.";
    tb.calligrapher.fstrings = TextFormatter.getFormattedStrings(tb.testString);


    tb.render = function()
        for i=1,#(tb.portraits),1 do
            tb.portraits[i].render();
        end
        tb.box.draw(25,200);
        tb.calligrapher.draw();
    end
    return tb;
end
TextBoxPortrait = function(filepath)
    local tbp = {};
    tbp.x = 0;
    tbp.y = 0;
    tbp.active = false;
    tbp.lit = false;
    tbp.img = love.graphics.newImage(filepath);
    tbp.render = function()
        if not tbp.active then
            return;
        end
        if tbp.lit then
            love.graphics.setColor(1,1,1);
        else
            love.graphics.setColor(0.6,0.6,0.6);
        end
        love.graphics.draw(tbp.img,tbp.x,tbp.y);
    end
    return tbp;
end