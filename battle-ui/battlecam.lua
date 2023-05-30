battleZoomLevels = {0.5,0.75,1.0,1.2,1.5}
BattleCam = function()
    local bc = {};
    bc._zoomIndex = 3;
    bc.factor = battleZoomLevels[bc._zoomIndex];
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
    bc.xoff = 0;
    bc.yoff = 0;
    return bc;
end