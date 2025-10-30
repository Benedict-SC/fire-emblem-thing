--require("util");
require("terrain");
moveOverlay = love.graphics.newImage("assets/img/rangeMove.png");
hitOverlay = love.graphics.newImage("assets/img/rangeHit.png");
healOverlay = love.graphics.newImage("assets/img/rangeHeal.png");
interactOverlay = love.graphics.newImage("assets/img/interactTile.png");
repositionOverlay = love.graphics.newImage("assets/img/startingPosition.png");
errorImg = love.graphics.newImage("assets/img/qmark.png");
Map = function(filename)
    local map = {};
    map.cells = Array();
    map.units = Array();
    map.interacts = {};
    map.playerUnits = function()
        return map.units.filter(function(x) return x.faction == "PLAYER"; end);
    end
    map.enemyUnits = function()
        return map.units.filter(function(x) return x.faction == "ENEMY"; end);
    end
    map.factionUnits = function(factionName)
        return map.units.filter(function(x) return x.faction == factionName; end);
    end

    map.drawCanvas = nil;--love.graphics.newCanvas(); --we need to wait until we have bounds

    local jsonstring = love.filesystem.read(filename);
    local data = json.decode(jsonstring);
    map.factionOrder = data.factionOrder and arrayify(data.factionOrder) or arrayify({"PLAYER","ENEMY"});
    map.bounds = data.bounds or {x0=0,y0=0,x1=#data.tiles[1],y1=#data.tiles};
    map.cellInBounds = function(x,y)
        return x > map.bounds.x0 and x <= map.bounds.x1 and y > map.bounds.y0 and y <= map.bounds.y1;
    end

    for i=1,#(data.tiles),1 do
        local row = Array();
        for j=1,#(data.tiles[1]),1 do
            local sourceCell = data.tiles[i][j];
            local cell = Cell(sourceCell.tile);
            cell.isStartingPosition = sourceCell.isStartingPosition;
            cell.walls = sourceCell.walls;
            cell.inBounds = map.cellInBounds(j,i);
            if sourceCell.interactions then
                for k=1,#(sourceCell.interactions),1 do
                    local si = sourceCell.interactions[k];
                    print("cell " .. j .. "," .. i .. " is getting an interaction with id " .. si.id);
                    local int = Interaction(si,j,i,cell);
                    map.interacts[si.id] = int;
                    cell.interactions.push(int);
                end
            end

            row.push(cell);
        end
        map.cells.push(row);
    end
    map.props = arrayify(data.props);
    map.propRegister = {};
    map.props.forEach(function(x) 
        x.imgFile = x.img;
        x.img = love.graphics.newImage(x.imgFile);
        x.naturalWidth = x.img:getWidth();
        x.naturalHeight = x.img:getHeight();
        x.sx = x.w / x.naturalWidth;
        x.sy = x.h / x.naturalHeight;
        if x.id then --in case something needs to get it for in-game graphics changes
            map.propRegister[x.id] = x;
        end;
    end);

    map.drawCanvas = love.graphics.newCanvas(#map.cells[1] * game.tileSize,#map.cells * game.tileSize);
    data.units = arrayify(data.units);
    --[[if data.startingPositions then --all maps should have at least one but some test maps don't
        map.startingPositions = arrayify(data.startingPositions);
        for i=1,#(map.startingPositions),1 do
            local pos = map.startingPositions[i];
            map.cells[pos.y][pos.x].isStartingPosition = true;
        end
    end--]]
    UnitData.loadArmyDataToMapData(data.units);
    for i=1,#(data.units),1 do
        local unitdata = data.units[i]
        local unit = Unit(unitdata);
        if(unitdata.classPreset) then
            unit.class = classLibrary[unitdata.classPreset];
        end
        if(unitdata.presetWeapons) then
            for j=1,#unitdata.presetWeapons,1 do 
                local wepon = weaponCache.getInstance(unitdata.presetWeapons[j]);
                wepon.img = love.graphics.newImage(wepon.iconfile);
                unit.inventory.push(wepon);
            end
        end
        if(unitdata.presetItems) then
            for j=1,#unitdata.presetItems,1 do 
                local item = itemCache.getInstance(unitdata.presetItems[j]);
                item.img = love.graphics.newImage(item.iconfile);
                unit.inventory.push(item);
            end
        end
        unit.loadSprites();
        unit.equipFirstWeapon();
        map.cells[unitdata.y][unitdata.x].occupant = unit;
        map.units.push(unit);
    end
    map.renderFloor = function()
        map.renderTerrain();
        map.renderPaintovers();
        map.renderUI();
    end
    map.renderTerrain = function()
        for i=1,#(map.cells),1 do
            for j=1,#(map.cells[1]),1 do
                local cell = map.cells[i][j]
                local tilecode = cell.terrainType;
                love.graphics.draw(terrainImages[tilecode],(j-1)*game.tileSize,(i-1)*game.tileSize);
            end
        end
        map.renderGrid();
    end
    map.renderGrid = function()
        love.graphics.setLineWidth(1);
        love.graphics.setColor(0.8,0.8,0.8,0.5);
        for y=1,#(map.cells),1 do
            for x=1,#(map.cells[1]),1 do
                local drawrightborder = (y > map.bounds.y0) and (y <= map.bounds.y1) and (x >= map.bounds.x0) and (x <= map.bounds.x1);
                local drawbottomborder = (x > map.bounds.x0) and (x <= map.bounds.x1) and (y >= map.bounds.y0) and (y <= map.bounds.y1);
                if drawbottomborder then
                    love.graphics.line((x-1)*game.tileSize,y*game.tileSize,x*game.tileSize,y*game.tileSize);
                end
                if drawrightborder then
                    love.graphics.line(x*game.tileSize,(y-1)*game.tileSize,x*game.tileSize,y*game.tileSize);
                end
            end
        end
        love.graphics.setColor(1,1,1,1);
    end
    map.renderPaintovers = function()
        for i=1,#map.props,1 do
            local prop = map.props[i];
            love.graphics.draw(prop.img,prop.x,prop.y,0,prop.sx,prop.sy);
        end
    end
    map.renderUI = function()
        for i=1,#(map.cells),1 do
            for j=1,#(map.cells[1]),1 do
                local cell = map.cells[i][j];
                if cell.moveOn then
                    love.graphics.draw(moveOverlay,(j-1)*game.tileSize,(i-1)*game.tileSize);
                elseif cell.hitOn then
                    love.graphics.draw(hitOverlay,(j-1)*game.tileSize,(i-1)*game.tileSize);
                elseif cell.interactOn then
                    love.graphics.draw(interactOverlay,(j-1)*game.tileSize,(i-1)*game.tileSize);
                end
                local drewObjective = false;
                cell.interactions.forEach(function(x) 
                    if x.displaysOnMap and not drewObjective then
                        love.graphics.draw(interactOverlay,(j-1)*game.tileSize,(i-1)*game.tileSize);
                        drewObjective = true;
                    end
                end);
            end
        end
    end
    map.renderStartingPositions = function()
        for i=1,#map.cells,1 do
            for j=1,#(map.cells[1]),1 do
                local cell = map.cells[i][j];
                if cell.isStartingPosition then
                    love.graphics.draw(repositionOverlay,(j-1)*game.tileSize,(i-1)*game.tileSize);
                end
            end
        end
    end
    map.renderUnits = function()
        for i=1,#(map.cells),1 do
            for j=1,#(map.cells[1]),1 do
                local cell = map.cells[i][j];
                local unit = cell.occupant;
                if unit ~= nil then
                    if unit.used then
                        love.graphics.setShader(grayShader);
                    end
                    if unit.markedForDeath then
                        love.graphics.setShader(flashShader);
                        love.graphics.setColor(unit.deathFlash,unit.deathFlash,unit.deathFlash,unit.deathAlpha);
                    end
                    love.graphics.draw(unit.img,(j-1)*game.tileSize + unit.xoff,(i-1)*game.tileSize + unit.yoff);
                    love.graphics.setColor(1,1,1,1);
                    love.graphics.setShader();
                end
            end
        end
    end
    map.costToEnter = function(unit,cell) 
        local emptySpaceCost = terrain[cell.terrainType].costToEnter(unit.class.movementType());
        if cell.occupant then
            if cell.occupant.faction ~= unit.faction then
                return 999;
            end
        end
        if not cell.inBounds then
            return 999;
        end
        return emptySpaceCost;
    end
    map.nodes = function(unit)
        local nodes = Array();
        nodes.y0 = map.bounds.y0;
        nodes.x0 = map.bounds.x0;
        for i=1+nodes.y0,map.bounds.y1,1 do
            nodes.push(Array());
            for j=1,#(map.cells[1]),1 do
                local tile = map.cells[i][j];
                if tile.inBounds then
                    local node = Node(j,i,tile);
                    nodes[i-nodes.y0].push(node);
                end
            end
        end
        for i=1,#nodes,1 do
            for j=1,#(nodes[i]),1 do
                local node = nodes[i][j];
                local n = (i > 1) and nodes[i-1][j] or false;
                local s = (i < #nodes) and nodes[i+1][j] or false;
                local w = (j > 1) and nodes[i][j-1] or false;
                local e = (j < #nodes[i]) and nodes[i][j+1] or false;
                if n then 
                    local cost = map.costToEnter(unit,n.cell);
                    if n.cell.walls and n.cell.walls.s then
                        if n.cell.walls.s == "HIGH" then
                            cost = 999;
                        elseif unit.class.movementType() ~= "FLYING" then
                            cost = 999;
                        end
                    end
                    node.connections.push(Connection(cost,node,n)); 
                end
                if s then 
                    local cost = map.costToEnter(unit,s.cell);
                    if s.cell.walls and s.cell.walls.n then
                        if s.cell.walls.n == "HIGH" then
                            cost = 999;
                        elseif unit.class.movementType() ~= "FLYING" then
                            cost = 999;
                        end
                    end
                    node.connections.push(Connection(cost,node,s)); 
                end
                if w then 
                    local cost = map.costToEnter(unit,w.cell);
                    if w.cell.walls and w.cell.walls.e then
                        if w.cell.walls.e == "HIGH" then
                            cost = 999;
                        elseif unit.class.movementType() ~= "FLYING" then
                            cost = 999;
                        end
                    end
                    node.connections.push(Connection(cost,node,w)); 
                end
                if e then 
                    local cost = map.costToEnter(unit,e.cell);
                    if e.cell.walls and e.cell.walls.w then
                        if e.cell.walls.w == "HIGH" then
                            cost = 999;
                        elseif unit.class.movementType() ~= "FLYING" then
                            cost = 999;
                        end
                    end
                    node.connections.push(Connection(cost,node,e)); 
                end
            end
        end
        nodes.getFromCoords = function(x,y)
            return nodes[y-nodes.y0][x-nodes.x0];
        end
        return nodes;
    end
    map.cellFromNode = function(node)
        return map.cells[node.y][node.x];
    end
    map.getAdjacentCells = function(x,y)
        local adjs = Array();
        if (x-1 >= 1) and (x-1 <= #(map.cells[1])) and (y >= 1) and (y <= #(map.cells)) and (x-1 > map.bounds.x0) then
            adjs.push(map.cells[y][x-1]);
        end
        if (x+1 >= 1) and (x+1 <= #(map.cells[1])) and (y >= 1) and (y <= #(map.cells)) and (x+1 <= map.bounds.x1) then
            adjs.push(map.cells[y][x+1]);
        end
        if (x >= 1) and (x <= #(map.cells[1])) and (y-1 >= 1) and (y-1 <= #(map.cells)) and (y-1 > map.bounds.y0) then
            adjs.push(map.cells[y-1][x]);
        end
        if (x >= 1) and (x <= #(map.cells[1])) and (y+1 >= 1) and (y+1 <= #(map.cells)) and (y+1 <= map.bounds.y1) then
            adjs.push(map.cells[y+1][x]);
        end
        return adjs;
    end
    map.unitAt = function(x,y)
        return map.cells[y][x].occupant;
    end
    map.cellContainingUnit = function(unit) --being O(n^2) is the price of units not containing location data
        for i=1,#(map.cells),1 do
            for j=1,#(map.cells[1]),1 do
                local cell = map.cells[i][j];
                if cell.occupant == unit then
                    return cell;
                end
            end
        end
        return nil;
    end
    map.removeUnit = function(unit)
        map.units.removeItem(unit);
        map.cells[unit.y][unit.x].occupant = nil;
    end
    map.moveUnitTo = function(unit,destX,destY) 
        map.cells[unit.y][unit.x].occupant = nil;
        unit.x = destX;
        unit.y = destY;
        map.cells[destY][destX].occupant = unit;
    end
    map.highlightAttackRange = function(unit,weapon)
        local ranges = Array();
        if weapon then 
            ranges.concatenate(weapon.range);
        else
            ranges = unit.getWeaponRanges();
        end
        local cellsInRange = map.getCellsInRanges(unit.x,unit.y,ranges);
        --first clear the hit range on all cells;
        map.cells.forEach(function(row) row.forEach(function(cell) cell.hitOn = false; end); end)
        --then set the ones that need to be highlighted
        cellsInRange.forEach(function(x) x.hitOn = true; end);
    end
    map.getCellsInRanges = function(x,y,ranges)
        local inRangeCells = Array();
        for i=1,#map.cells,1 do
            for j=1,#map.cells[i],1 do
                local inRange = false;
                local mhd = math.abs(x - j) + math.abs(y - i);
                for k=1,#ranges,1 do
                    if mhd == ranges[k] and map.cellInBounds(j,i) then
                        inRange = true;
                        break;
                    end
                end
                if inRange then
                    inRangeCells.push(map.cells[i][j]);
                end
            end
        end 
        return inRangeCells;
    end
    return map;
end