textboxImg = love.graphics.newImage("assets/img/textbg.png");
TextBox = function()
    local tb = {};
    tb.box = MenuBox(textboxImg,17,19);
    tb.box.resize(gamewidth-50,gameheight-200);
    tb.render = function()
        tb.box.draw(25,200);
    end
    return tb;
end