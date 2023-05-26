battleZoomLevels = {0.25,0.5,0.75,1.0,1.2,1.5,2.0}
BattleCam = function()
    local bc = {};
    bc._zoomIndex = 4;
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
    end
    bc.xoff = 0;
    bc.yoff = 0;
    return bc;
end