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
    bc.recenter = function(b,x,y,instant)
        bc.initialOffset = {x=bc.xoff,y=bc.yoff};

        local halftile = math.floor(game.tileSize / 2 + 0.5);
        local centerX = (x-1) * (game.tileSize) + halftile;
        local centerY = (y-1) * (game.tileSize) + halftile;
        local screenSpaceX = centerX * bc.factor;
        local screenSpaceY = centerY * bc.factor;
        local targetOffset = {x=screenSpaceX - math.floor(gamewidth / 2),y= screenSpaceY - math.floor(gameheight / 2)};
        --don't let it clip outside the map bounds
        if targetOffset.x < 0 then targetOffset.x = 0; end
        if targetOffset.y < 0 then targetOffset.y = 0; end
        local mapwidth = #b.map.cells[1] * game.tileSize;
        local mapheight = #b.map.cells * game.tileSize;
        local screenMW = math.floor(mapwidth * bc.factor + 0.5);
        local screenMH = math.floor(mapheight * bc.factor + 0.5);
        if targetOffset.x + gamewidth > screenMW then
            targetOffset.x = screenMW - gamewidth;
        end
        if targetOffset.y + gameheight > screenMH then
            targetOffset.y = screenMH - gameheight;
        end

        if (bc.animation and (not bc.animation.done) and (not bc.animation.cancel)) then
            bc.animation.cancel = true;
        end
        if (instant) then
            bc.xoff = targetOffset.x;
            bc.yoff = targetOffset.y;
        else
            bc.animation = async.doOverTime(0.3,function(percent) 
                local prog = 1 - math.pow(1 - percent, 3);
                local distX = targetOffset.x - bc.initialOffset.x;
                local distY = targetOffset.y - bc.initialOffset.y;
                bc.xoff = bc.initialOffset.x + (prog*distX);
                bc.yoff = bc.initialOffset.y + (prog*distY);
            end,function() 
                bc.xoff = targetOffset.x;
                bc.yoff = targetOffset.y;
            end);
        end
    end
    bc.xoff = 0;
    bc.yoff = 0;
    return bc;
end