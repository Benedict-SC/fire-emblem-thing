--require("util");
require("terrain");
tiles = {
    love.graphics.newImage("assets/img/grass.png"),
    love.graphics.newImage("assets/img/forest.png"),
    love.graphics.newImage("assets/img/hill.png")
}
moveOverlay = love.graphics.newImage("assets/img/rangeMove.png");
hitOverlay = love.graphics.newImage("assets/img/rangeHit.png");
errorImg = love.graphics.newImage("assets/img/qmark.png");
Map = function(filename)
    local map = {};
    map.cells = Array();
    map.units = Array();
    map.enemyUnits = Array();
    map.playerUnits = Array();
    map.otherUnits = Array();

    map.drawCanvas = nil;--love.graphics.newCanvas(); --we need to wait until we have bounds

    local jsonstring = love.filesystem.read(filename);
    local data = json.decode(jsonstring);

    for i=1,#(data.tiles),1 do
        local row = Array();
        for j=1,#(data.tiles[1]),1 do
            local cell = Cell(data.tiles[i][j]);
            row.push(cell);
        end
        map.cells.push(row);
    end

    map.drawCanvas = love.graphics.newCanvas(#map.cells[1] * game.tileSize,#map.cells * game.tileSize);

    --local combinedunits = arrayify(data.enemyUnits);
    --combinedunits.concatenate(data.playerUnits);

    for i=1,#(data.enemyUnits),1 do
        local unitdata = data.enemyUnits[i]
        local unit = ActiveUnit(unitdata);
        --unit.faction = "ENEMY"; -- enemy by default
        --unit.friendly = false; --false by default
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
        map.cells[unitdata.y][unitdata.x].occupant = unit;
        map.units.push(unit);
        map.enemyUnits.push(unit);
    end
    --the following is temporary- later, load player units from the actual player army setup
    for i=1,#(data.playerUnits),1 do
        local unitdata = data.playerUnits[i]
        local unit = ActiveUnit(unitdata);
        unit.faction = "PLAYER";
        unit.friendly = true;
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
        map.cells[unitdata.y][unitdata.x].occupant = unit;
        map.units.push(unit);
        map.playerUnits.push(unit);
    end
    map.renderTerrain = function()
        for i=1,#(map.cells),1 do
            for j=1,#(map.cells[1]),1 do
                local cell = map.cells[i][j]
                local tilecode = cell.terrainType;
                love.graphics.draw(tiles[tilecode],(j-1)*50,(i-1)*50);
                if cell.moveOn then
                    love.graphics.draw(moveOverlay,(j-1)*50,(i-1)*50);
                elseif cell.hitOn then
                    love.graphics.draw(hitOverlay,(j-1)*50,(i-1)*50);
                end
            end
        end
        --[[for i=1,#(map.units),1 do
            local unit = map.units[i];
            love.graphics.draw
        end]]--
    end
    map.renderUnits = function()
        for i=1,#(map.cells),1 do
            for j=1,#(map.cells[1]),1 do
                local cell = map.cells[i][j];
                local unit = cell.occupant;
                if unit ~= nil then
                    love.graphics.draw(unit.img,(j-1)*50 + unit.xoff,(i-1)*50 + unit.yoff);
                end
            end
        end
    end
    map.costToEnter = function(unit,cell) 
        local emptySpaceCost = terrain[cell.terrainType].costToEnter(unit.class.movementType());
        if cell.occupant then
            if cell.occupant.friendly ~= unit.friendly then
                return 999;
            end
        end
        return emptySpaceCost;
    end
    map.nodes = function(unit)
        local nodes = Array();
        for i=1,#(map.cells),1 do
            nodes.push(Array());
            for j=1,#(map.cells[1]),1 do
                local tile = map.cells[i][j];
                local node = Node(j,i,tile);
                nodes[i].push(node);
            end
        end
        for i=1,#nodes,1 do
            for j=1,#(nodes[i]),1 do
                local node = nodes[i][j];
                local n = (i > 1) and nodes[i-1][j] or false;
                local s = (i < #nodes) and nodes[i+1][j] or false;
                local w = (j > 1) and nodes[i][j-1] or false;
                local e = (j < #nodes[i]) and nodes[i][j+1] or false;
                if n then node.connections.push(Connection(map.costToEnter(unit,n.cell),node,n)); end
                if s then node.connections.push(Connection(map.costToEnter(unit,s.cell),node,s)); end
                if w then node.connections.push(Connection(map.costToEnter(unit,w.cell),node,w)); end
                if e then node.connections.push(Connection(map.costToEnter(unit,e.cell),node,e)); end
            end
        end
        return nodes;
    end
    map.cellFromNode = function(node)
        return map.cells[node.y][node.x];
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
                    if mhd == ranges[k] then
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
Cell = function(code) --these are used to store map data and persist
    local cell = {};
    cell.terrainType = code;
    cell.moveOn = false;
    cell.hitOn = false;
    return cell;
end
Node = function(x,y,cell) --these are used by pathfinding and are ephemeral, lasting only for the current navigation action
    local node = {};
    node.x = x;
    node.y = y;
    node.connections = Array();
    node.costSoFar = 0;
    node.cell = cell;
    node.preferredConnBack = nil;
    node.manhattanDistance = function (node2)
        local mhd = math.abs(node2.x - node.x) + math.abs(node2.y - node.y);
        --print(mhd);
        return mhd;
    end

    return node;
end
Connection = function(cost,src,dest)
    local conn = {};
    conn.cost = cost;
    conn.src = src;
    conn.dest = dest;
    return conn;
end
dijkstra = function(startNode,budget) --modified dijkstra that gets costs and paths for all nodes in range
    local open = Array();
    local closed = Array();
    open.push(startNode);
    while (#open > 0) do
        if #open > 1000 then error("too ass!") end
        --get cheapest so far in the open list
        local cheapest = open[1];
        for i=1,#open,1 do
            if open[i].costSoFar < cheapest.costSoFar then
                cheapest = open[i];
            end
        end
        --print("cheapest is (" .. cheapest.x .. "," .. cheapest.y .. ")");
        local conns = cheapest.connections;
        for i=1,#conns,1 do
            local conn = conns[i]
            local dest = conn.dest;
            if(dest == cheapest) then error("recursive path!") end
            local newCost = cheapest.costSoFar + conn.cost;
            local onClosed = closed.indexOf(dest) >= 1;
            local onOpen = open.indexOf(dest) >= 1;
            if onClosed then 
                goto continue 
            elseif onOpen then
                if dest.costSoFar <= newCost then
                    goto continue
                end
            end
            dest.costSoFar = newCost;
            dest.preferredConnBack = conn;
            open.push(dest);
            ::continue::
        end
        open.removeItem(cheapest);
        closed.push(cheapest);
    end
    return closed.filter(function(x) return x.costSoFar <= budget end);
end