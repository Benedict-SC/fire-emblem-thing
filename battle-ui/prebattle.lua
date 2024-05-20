prebattleMenuImage = love.graphics.newImage("assets/img/sliceablemenu.png");
prebattleMenuCursor = love.graphics.newImage("assets/img/unbounded-cursor.png");
prebattleMenuOptionHeight = 23;
prebattleMenuFont = Fonts.getFont("arial-b", 17);
PreBattleMenu = function()
    local pbm = {};
    pbm.box = MenuBox(actionMenuImg,10);
    pbm.box.resize(120,140);
    pbm.bounds = {x=gamewidth/2 - 52,y=gameheight/2 - 83}
    pbm.cursorPosition = 1; --0 is no draw
    pbm.options = Array();
    pbm.canvas = love.graphics.newCanvas(gamewidth,gameheight);

    --populate options
    local unitsOption = {name="pickunits (x)"};
    unitsOption.onPick = function()

    end
    pbm.options.push(unitsOption);

    local viewOption = {name="View Map"};
    viewOption.onPick = function()
        game.battle.state = "OVERVIEW";
    end
    pbm.options.push(viewOption);
    
    local repositionOption = {name="Reposition"};
    repositionOption.onPick = function()
        game.battle.state = "REPOSITION";
    end
    pbm.options.push(repositionOption);

    local inventoryOption = {name="inventory (x)"};
    inventoryOption.onPick = function()

    end
    pbm.options.push(inventoryOption);

    local startOption = {name="Start Battle"};
    startOption.onPick = function()
        game.battle.changePhase();
    end
    pbm.options.push(startOption);
    
    pbm.executeCurrentOption = function()
        if pbm.cursorPosition > 0 then
            local opt = pbm.options[pbm.cursorPosition];
            opt.onPick();
        end
    end

    pbm.render = function()
        love.graphics.pushCanvas(pbm.canvas);
        love.graphics.clear(0,0,0,0.2);
        love.graphics.setColor(1,1,1,1);

        love.graphics.setFont(prebattleMenuFont);
        pbm.box.draw(pbm.bounds.x,pbm.bounds.y);
        if pbm.cursorPosition ~= 0 then
            love.graphics.draw(prebattleMenuCursor,pbm.bounds.x-4,pbm.bounds.y + (prebattleMenuOptionHeight * (pbm.cursorPosition-1)) + pbm.box.bh);
        end
        for i=1,#pbm.options,1 do
            love.graphics.print(pbm.options[i].name,pbm.bounds.x+pbm.box.bw+2,pbm.bounds.y+pbm.box.bh+1 + (prebattleMenuOptionHeight*(i-1)));
        end
        
        --now draw all that to the previous context
        love.graphics.popCanvas();
        love.graphics.setColor(1,1,1,1);
        love.graphics.draw(pbm.canvas,0,0);
    end
    pbm.moveCursor = function(dir)
        pbm.cursorPosition = pbm.cursorPosition + dir;
        if pbm.cursorPosition < 1 then pbm.cursorPosition = #(pbm.options); end
        if pbm.cursorPosition > #(pbm.options) then pbm.cursorPosition = 1; end
    end
    pbm.setCursorWithMouse = function()
        local mx,my = love.mouse.getPosition();
        local x = mx - pbm.bounds.x;
        if x < pbm.box.bw or x > pbm.box.xoffs[3] then --if we're not 
            pbm.cursorPosition = 0;
            return;
        end
        local y = my - pbm.bounds.y;
        local idx = math.ceil((y-pbm.box.bh) / prebattleMenuOptionHeight);
        if idx <= 0 or idx > #(pbm.options) then
            pbm.cursorPosition = 0;
            return;
        end
        pbm.cursorPosition = idx;
    end

    return pbm;
end