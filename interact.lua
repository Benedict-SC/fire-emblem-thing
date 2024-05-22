Interaction = function(sourceData)
    if (not sourceData) or (not sourceData.id) then error("invalid interaction object"); end

    local int = {}; --oh this variable name won't be confusing i bet. don't worry lua doesn't have ints
    int.id = sourceData.id;
    int.name = sourceData.name and sourceData.name or "DEFAULT_NAME";
    int.displaysOnMap = sourceData.displaysOnMap;
    int.displaysInMenu = sourceData.displaysInMenu;
    int.triggersOnTurnEnd = sourceData.triggersOnTurnEnd;

    if sourceData.sacks then
        int.execute = function(whendone)
            local propToSack = game.battle.map.propRegister[sourceData.sacks];
            propToSack.img = love.graphics.newImage("assets/img/sackedcassle.png");
            int.displaysOnMap = false;
            game.battle.ai.currentUnit.unit.aiStrategy = "AGGRO";
            if whendone then 
                whendone();
            end
        end
    else
        int.execute = function(whendone)
            if whendone then 
                whendone();
            end
        end;
    end

    int.addMenuOption = function(actionmenu)
        if int.displaysInMenu then
            local intOption = {name=int.name};
            intOption.onPick = int.execute;
            actionmenu.addOption(intOption,1);
        end --else just. don't.
    end

    return int;
end