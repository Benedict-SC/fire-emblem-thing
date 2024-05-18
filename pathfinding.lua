Pathfinding = {};
Pathfinding.displayRange = function(unit,battle) 
    local nodes = battle.map.nodes(unit); --get the navigation nodes
    local startNode = nodes[unit.y][unit.x];
    local nodes1D = nodes.oneDimensionDown();
    local nodelist = Pathfinding.dijkstra(startNode,unit.mov); --populate the navigation nodes with costs and get the subset of nodes that are considered in-range
    for i=1,#nodelist,1 do --for all those nodes, turn on the valid-move-option overlay
        local node = nodelist[i];
        node.marked = true; --mark it so we can subtract it to get out-of-range nodes;
        battle.map.cells[node.y][node.x].moveOn = true;
    end
    --now let's calculate attack ranges
    local ranges = unit.getRangeSpan();
    local unmarked = nodes1D.filter(function(x) return not (x.marked) end); --get just the nodes out of range
    for i=1,#ranges,1 do
        for j=1,#unmarked,1 do --for each attack range, have each out-of-move-range check if any of the in-move-range spaces are within that attack range. assume attack ranges are commutative and not blocked by walls. TODO: revise this if that assumption changes
            local target = unmarked[j];
            local nodesWithoutFriends = nodelist.filter(function(x) 
                local rangeOcc = battle.map.cellFromNode(x).occupant;
                return rangeOcc == nil or rangeOcc == unit;
            end);
            local manhattanNeighbors = nodesWithoutFriends.filter(function(x) 
                return x.manhattanDistance(target) == ranges[i];
            end);
            if manhattanNeighbors.size > 0 then 
                unmarked[j].hittable = true;
            end
        end
    end
    unmarked.forEach(function(x) --turn on the attack range overlays
        if x.hittable then
            battle.map.cells[x.y][x.x].hitOn = true;
        end
    end);
    return nodes,startNode;
end
Pathfinding.dijkstra = function(startNode,budget) --modified dijkstra that gets costs and paths for all nodes in range
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
    if budget then
        return closed.filter(function(x) return x.costSoFar <= budget end);
    else
        return closed;
    end
end
Pathfinding.intersectionWithOtherNodes = function(nodes1D,otherNodes1D) --when multiple node lists are generated for different purposes, get a subset of one that has cells in common with another
    local otherCells = otherNodes1D.map(function(x) return x.cell end);
    return nodes1D.filter(function(x) 
        return otherCells.has(x.cell);
    end);
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
