StatsPage = function()
    local sp = {};
    sp.bg = love.graphics.newImage("assets/img/menubg.png");
    sp.badBg = love.graphics.newImage("assets/img/menubg-enemy.png");
    sp.alignment = 1; -- 1=ally, 2=enemy, 3=other
    sp.unit = ActiveUnit({type="soldier"});
    sp.unitList = {sp.unit};
    sp.statfont = Fonts.getFont("arial", 20);
    sp.render = function()
        if sp.alignment == 1 then
            love.graphics.draw(sp.bg,0,0);
        elseif sp.alignment == 2 then
            love.graphics.draw(sp.badBg,0,0);
        else
            love.graphics.draw(sp.bg,0,0);
        end

        love.graphics.setColor(1,1,1);
        love.graphics.setFont(sp.statfont);
        love.graphics.print("HP: " .. sp.unit.maxhp,60,145);
        love.graphics.print("STR: " .. sp.unit.str,60,170);
        love.graphics.print("SKL: " .. sp.unit.skl,60,195);
        love.graphics.print("CON: " .. sp.unit.con,60,220);
        love.graphics.print("SPD: " .. sp.unit.spd,185,145);
        love.graphics.print("LUK: " .. sp.unit.luk,185,170);
        love.graphics.print("DEF: " .. sp.unit.def,185,195);
        love.graphics.print("RES: " .. sp.unit.res,185,220);
        love.graphics.draw(sp.unit.port,36,22);

        for i=1,#sp.unit.inventory,1 do
            local item = sp.unit.inventory[i];
            local height = 145 + (25*(i-1));
            love.graphics.draw(item.img,340,height);
            love.graphics.print(item.name,370,height);
            love.graphics.setColor(1,1,1,0.5);
            love.graphics.print("(" .. item.currentUses .. "/" .. item.maxUses .. ")",490,height);
            love.graphics.setColor(1,1,1,1);
            if sp.unit.equipIdx == i then
                love.graphics.draw(equipDot,352,height+12);
            end
        end

        love.graphics.setColor(0,0,0);
        love.graphics.print(sp.unit.name,39,110);
        love.graphics.print(sp.unit.class.name,169,25);
        love.graphics.print(sp.unit.hp .. "/" .. sp.unit.maxhp,293,35);
        love.graphics.print(sp.unit.level,290,65);
        love.graphics.print(sp.unit.exp,365,65);
        love.graphics.setColor(0.4,0.3,0.1,0.7);
        love.graphics.print("HP",260,35);
        love.graphics.print("LV",260,65);
        love.graphics.print("EXP",320,65);
        love.graphics.setColor(1,1,1);
        love.graphics.draw(sp.unit.img,172,50);
    end
    sp.update = function()
        if pressedThisFrame.mouse2 or pressedThisFrame.cancel then
            game.state = "BATTLE";
        end
    end
    sp.setAlignment = function(alignmentname)
        if alignmentname == "ENEMY" then
            sp.alignment = 2;
        else
            sp.alignment = 1;
        end
    end
    return sp;
end