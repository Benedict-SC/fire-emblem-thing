textboxImg = love.graphics.newImage("assets/img/textbg.png");
TextBox = function()
    local tb = {};
    tb.box = MenuBox(textboxImg,17,19);
    tb.calligrapher = TextDrawer({x=40,y=215,w=500,h=150},nil,120)
    tb.box.resize(gamewidth-50,gameheight-200);

    tb.testString = "some <b>bold</b> <c=#00DD66><i>green italic</i></c> <b><i>bolditalic</i></b> <c=#00AAFF>text</c> that goes on for a little <b>while</b> and would do some wrapping. it's going to get cut off at 120 characters, i think, so add a bunch more characters to the string.";
    tb.calligrapher.fstrings = TextFormatter.getFormattedStrings(tb.testString);
    tb.render = function()
        tb.box.draw(25,200);
        tb.calligrapher.draw();
    end
    return tb;
end