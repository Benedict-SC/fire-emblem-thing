AIManager = function() 
    local ai = {};
    ai.unitList = Array();
    ai.assignUnitList = function(unitList)
        ai.unitList = unitList.map(function(x) 
            return {unit=x};
        end);
    end
    ai.loadNavNodes = function(unit,map)
        ai.nodes = map.nodes(unit);
    end
    ai.getPossibleCombats = function(unit)
        DEBUG_TEXT = "";
        local possibleCombats = Array();
        local nodes1D = ai.nodes.oneDimensionDown();
        local nodesWithEnemies = nodes1D.filter(function(x) 
            if not x.cell.occupant then 
                return false; 
            end
            return not unit.friendly(x.cell.occupant);
        end);
        local startNode = ai.nodes[unit.y][unit.x];
        local nodeslist = dijkstra(startNode,unit.mov); --populate the navigation nodes with costs
        for i=1,#nodeslist,1 do --for all those nodes, mark them 
            local node = nodeslist[i];
            node.marked = true; --mark it so we can subtract it to get out-of-range nodes;
        end

        --now let's calculate attack ranges
        local ranges = unit.getRangeSpan(function(item) --get all the ranges of owned weapons
            return item.isWeapon;
        end);
        local marked = nodes1D.filter(function(x) return  (x.marked) end);
        DEBUG_TEXT = DEBUG_TEXT .. "unit has " .. #ranges .. " ranges.\n";
        DEBUG_TEXT = DEBUG_TEXT .. #nodesWithEnemies .. " nodes with enemy units exist.\n";
        for i=1,#ranges,1 do --for each range you can attack enemies from,
            for j=1,#nodesWithEnemies,1 do --and for each enemy in those ranges, check all possible combats from spaces you can reach. assume attack ranges are commutative and not blocked by walls. TODO: revise this if that assumption changes
                local enemyNode = nodesWithEnemies[j];
                local manhattanNeighbors = nodes1D.filter(function(x) 
                    return x.manhattanDistance(enemyNode) == ranges[i]; --only consider spaces in range
                end);
                manhattanNeighbors = manhattanNeighbors.filter(function(x) 
                    return x.marked; --only consider combats from reachable spaces
                end);
                if manhattanNeighbors.size > 0 then 
                    local weps = unit.getWeapons();
                    weps = weps.filter(function(x) return x.hasRange(ranges[i]) end); --consider only combats with weapons that can actually reach from these spaces
                    for k=1,#weps,1 do
                        for m=1,#manhattanNeighbors,1 do
                            local possibility = PossibleCombat(manhattanNeighbors[m],enemyNode,weps[k]);
                            possibleCombats.push(possibility);
                        end
                    end
                end
            end
        end
        return possibleCombats;
    end
    ai.pickTarget = function(unit,map)
        ai.loadNavNodes(unit,map);
        local possibleCombats = ai.getPossibleCombats(unit);
        --DEBUG_TEXT = "" .. #possibleCombats .. " possible combats.";
        local dbg = "Can attack:\n";
        for i=1,#possibleCombats,1 do
            local pc = possibleCombats[i];
            dbg = dbg .. pc.def.cell.occupant.name .. " from (" .. pc.atk.x .. "/" .. pc.atk.y .. ") with " .. pc.wep.name .. "\n";
        end
        DEBUG_TEXT = DEBUG_TEXT .. dbg;
    end
    ai.beginTurn = function()
        ai.unitList.forEach(function(x) 
            x.turnTaken = false;
        end);

    end
    ai.getNextUnit = function()
        for i=1,#ai.unitList,1 do
            local u = ai.unitList[i];
            if not u.turnTaken then
                return u;
            end
        end
        return nil;
    end

    ai.update = function()
    
    end

    return ai;
end
PossibleCombat = function(attackingNode,defendingNode,attackerWeapon)
    local pc = {};
    pc.atk = attackingNode;
    pc.def = defendingNode;
    pc.wep = attackerWeapon;
    return pc;
end
