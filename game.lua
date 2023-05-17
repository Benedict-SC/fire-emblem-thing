--states = {"TITLE,STATS,BATTLE"}
Game = function()
    local game = {};
    game.tileSize = 50;
    game.battle = Battle("assets/json/testmap.json");
    game.statspage = StatsPage();
    game.state = "BATTLE"
    game.render = function()
        if game.state == "BATTLE" then
            game.battle.render();
        elseif game.state == "STATS" then
            game.statspage.render();
        end
    end
    game.update = function()
        if game.state == "STATS" then
            game.statspage.update();
        elseif game.state == "BATTLE" then
            game.battle.update();
        end
    end
    return game;
end