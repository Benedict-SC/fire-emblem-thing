Interaction = function(sourceData,x,y,cell)
    if (not sourceData) or (not sourceData.id) then error("invalid interaction object"); end

    local int = {}; --oh this variable name won't be confusing i bet. don't worry lua doesn't have ints
    int.id = sourceData.id;
    int.name = sourceData.name and sourceData.name or "DEFAULT_NAME";
    int.displaysOnMap = sourceData.displaysOnMap;
    int.displaysInMenu = sourceData.displaysInMenu;
    int.triggersOnTurnEnd = sourceData.triggersOnTurnEnd;
    int.x = x;
    int.y = y;
    int.cell = cell;

    if sourceData.actionType == "Sack" then
        int.execute = function(whendone)
            --TODO: improve customization of this function to specify a specific prop and what to replace it with, rather than guessing based on placeholder image name and physical proximity.
            local spatialCoordinates = {x=(int.x-1)*game.tileSize,y=((int.y-1)*game.tileSize)};
            local propsNorthwestOf = game.battle.map.props.filter(function(prop) 
                return (prop.x <= spatialCoordinates.x) and (prop.y <= spatialCoordinates.y);
            end);
            propsNorthwestOf = propsNorthwestOf.filter(function(prop) 
                return prop.imgFile == "custom/img/cassle.png";
            end);
            propsNorthwestOf.sort(function(a,b) 
                local xdist1 = a.x - spatialCoordinates.x;
                local ydist1 = a.y - spatialCoordinates.y;
                local xdist2 = b.x - spatialCoordinates.x;
                local ydist2 = b.y - spatialCoordinates.y;
                local adist = math.sqrt((xdist1*xdist1)+(ydist1*ydist1));
                local bdist = math.sqrt((xdist2*xdist2)+(ydist2*ydist2));
                return adist < bdist;
            end);
            --local propToSack = game.battle.map.propRegister[sourceData.sacks];
            local propToSack = propsNorthwestOf[1];

            for i=1,#cell.interactions,1 do --remove all interactions from this tile. nothing to do with a destroyed house!
                game.battle.map.interacts[cell.interactions[i].id] = nil;
            end
            cell.interactions = Array(); 

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