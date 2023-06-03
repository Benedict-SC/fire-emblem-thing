--battleZoomLevels = {0.5,0.75,1.0,1.2,1.5}
battleZoomLevels = {1.0,1.2,1.5}
BattleCam = function()
    local bc = {};
    bc._zoomIndex = 1;
    bc.factor = battleZoomLevels[bc._zoomIndex];
    bc.deadZoneW = gamewidth / 7;
    bc.deadZoneH = gameheight / 7;
    bc.zoom = function(direction)
        bc._zoomIndex = bc._zoomIndex + direction;
        if bc._zoomIndex > #battleZoomLevels then
            bc._zoomIndex = #battleZoomLevels;
        end
        if bc._zoomIndex < 1 then
            bc._zoomIndex = 1
        end
        bc.factor = battleZoomLevels[bc._zoomIndex];
        if(game.battle.actionMenu) then
            game.battle.actionMenu.configureSize(bc);
        end
        if(game.battle.pickWeaponMenu) then
            game.battle.actionMenu.configureSize(bc);
        end
    end
    bc.recenter = function(b,x,y)
        local halftile = math.floor(game.tileSize / 2 + 0.5);
        local centerX = (x-1) * (game.tileSize) + halftile;
        local centerY = (y-1) * (game.tileSize) + halftile;
        local screenSpaceX = centerX * bc.factor;
        local screenSpaceY = centerY * bc.factor;
        bc.xoff = screenSpaceX - math.floor(gamewidth / 2);
        bc.yoff = screenSpaceY - math.floor(gameheight / 2);
        --don't let it clip outside the map bounds
        if bc.xoff < 0 then bc.xoff = 0; end
        if bc.yoff < 0 then bc.yoff = 0; end
        local mapwidth = #b.map.cells[1] * game.tileSize;
        local mapheight = #b.map.cells * game.tileSize;
        local screenMW = math.floor(mapwidth * bc.factor + 0.5);
        local screenMH = math.floor(mapheight * bc.factor + 0.5);
        if bc.xoff + gamewidth > screenMW then
            bc.xoff = screenMW - gamewidth;
        end
        if bc.yoff + gameheight > screenMH then
            bc.yoff = screenMH - gameheight;
        end
    end
    bc.xoff = 0;
    bc.yoff = 0;
    return bc;
end