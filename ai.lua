AIManager = function() 
    local ai = {};
    ai.unitList = Array();
    ai.assignUnitList = function(unitList)
        ai.unitList = unitList.map(function(x) 
            return {unit=x,turnTaken=false};
        end);
    end
    ai.getPossibleCombats = function(unit,map)
        DEBUG_TEXT = "";
        local possibleCombats = Array();
        local nodes = map.nodes(unit);
        local nodes1D = nodes.oneDimensionDown();
        local nodesWithEnemies = nodes1D.filter(function(x) 
            if not x.cell.occupant then 
                return false; 
            end
            return not unit.friendly(x.cell.occupant);
        end);
        local startNode = nodes[unit.y][unit.x];
        ai.startNode = startNode; --save this for later pathfinding
        local nodeslist = Pathfinding.dijkstra(startNode,unit.mov); --populate the navigation nodes with costs
        for i=1,#nodeslist,1 do --for all those nodes, mark them 
            local node = nodeslist[i];
            node.marked = true; --mark it so we can subtract it to get out-of-range nodes;
        end
        ai.reachableNodes = nodeslist; --store this for nav later

        --now let's calculate attack ranges
        local ranges = unit.getRangeSpan(function(item) --get all the ranges of owned weapons
            return item.isWeapon;
        end);
        --DEBUG_TEXT = DEBUG_TEXT .. "unit has " .. #ranges .. " ranges.\n";
        --DEBUG_TEXT = DEBUG_TEXT .. #nodesWithEnemies .. " nodes with enemy units exist.\n";
        for i=1,#ranges,1 do --for each range you can attack enemies from,
            for j=1,#nodesWithEnemies,1 do --and for each enemy in those ranges, check all possible combats from spaces you can reach. assume attack ranges are commutative and not blocked by walls. TODO: revise this if that assumption changes
                local enemyNode = nodesWithEnemies[j];
                local manhattanNeighbors = nodes1D.filter(function(x) 
                    return x.manhattanDistance(enemyNode) == ranges[i]; --only consider spaces in range
                end);
                manhattanNeighbors = manhattanNeighbors.filter(function(x) 
                    return x.marked; --only consider combats from reachable spaces
                end);
                manhattanNeighbors = manhattanNeighbors.filter(function(x)
                    return x.cell.occupant == nil;
                end);
                if manhattanNeighbors.size > 0 then 
                    local weps = unit.getWeapons();
                    weps = weps.filter(function(x) return x.hasRange(ranges[i]) end); --consider only combats with weapons that can actually reach from these spaces
                    for k=1,#weps,1 do
                        for m=1,#manhattanNeighbors,1 do
                            local possibility = PossibleCombat(manhattanNeighbors[m],enemyNode,weps[k],ranges[i]);
                            possibleCombats.push(possibility);
                        end
                    end
                end
            end
        end
        return possibleCombats;
    end
    ai.getFightPredictions = function(unit,map,possibleCombats)
        local fightPredictions = Array();
        if (not possibleCombats) or (#possibleCombats < 1) then --no possible combats detected, so check against all enemy combatants for planning
            local unitsToConsider;
            if unit.faction == "ENEMY" then
                unitsToConsider = map.units.filter(function(x) return x.faction ~= "ENEMY"; end);
            else
                unitsToConsider = map.enemyUnits();
            end
            for i=1,#unitsToConsider,1 do
                local opponent = unitsToConsider[i];
                local weaponsToTry = unit.getWeapons();
                for j=1,#weaponsToTry,1 do
                    unit.equipWeapon(weaponsToTry[j]);
                    local fightCalc = Fight(unit,opponent); --note: having this take place in a void makes this hypothetical fight take place at what is likely an extreme range using the current tile, distorting the counterattack prediction. TODO: fix this by creating a virtual node with null terrain. compare the range sets- place the node out of defender's range if possible, otherwise pick the highest range (as a proxy for the most favorable range).
                    local idealRange = 1; --TODO: that's wrong. see previous comment.
                    local prediction = {opponent=opponent,wep=weaponsToTry[j],damage=fightCalc.predictedDamage(0),counter=fightCalc.predictedCounterattack(),range=idealRange}; --TODO: include risk calc
                    fightPredictions.push(prediction);
                end
            end
        else --some stuff is actually in range, so restrict predictions to those combats
            for i=1,#possibleCombats,1 do
                local pc = possibleCombats[i];
                local opponent = pc.def.cell.occupant;--we assume we don't ever get here when that cell is empty.
                unit.equipWeapon(pc.wep);
                local fightCalc = Fight(unit,opponent,pc.atk); 
                local prediction = {opponent=opponent,wep=pc.wep,damage=fightCalc.predictedDamage(0),counter=fightCalc.predictedCounterattack()}; --TODO: include risk calc
                pc.prediction = prediction; --in this case, we don't care about the return value since we're attaching results to the possible combats themselves.
                fightPredictions.push(prediction); --but we'll make the list anyway i guess???
            end
        end
        --[[DEBUG_TEXT = "";
        for i=1,#fightPredictions,1 do
            local fp = fightPredictions[i];
            DEBUG_TEXT = DEBUG_TEXT .. fp.opponent.name .. " with " .. fp.wep.name .. ": " .. fp.damage .. "\n";
        end]]-- 
        return fightPredictions;
    end
    ai.rankPredictions = function(unit,predictionsList) --best to worst
        return predictionsList.sorted(function(a,b)
            return a.damage > b.damage; --TODO: consider crackback for smart units
        end);
    end
    ai.getDecision = function(unit,map) 
        local possibleCombats = ai.getPossibleCombats(unit,map);
        print("possible combats for " .. unit.name .. " at " .. unit.x .. "," .. unit.y .. " with strategy " .. unit.aiStrategy .. ": " .. #possibleCombats);
        if (not unit.aiStrategy) or (unit.aiStrategy == "SENTRY") or ((unit.aiStrategy == "AGGRO") and (#possibleCombats > 0)) then
            print(unit.name .. " has combats and is picking one");
            local possibleCombats = ai.getPossibleCombats(unit,map);
            local chosenCombat;
            if (not unit.aiTactics) or unit.aiTactics == "RANDOM" then
                chosenCombat = possibleCombats[math.random(#possibleCombats)];
            else
                local predictions = ai.getFightPredictions(unit,map,possibleCombats); --we don't really care about the return value- after running this function, the possibleCombats themselves have predictions attached.
                --TODO: sort possible combats based on the predictions and pick the best one
                local sortedPredictions = ai.rankPredictions(unit,predictions);
                local bestTarget = sortedPredictions[1];
                chosenCombat = possibleCombats.firstWhere(function(x) return x.prediction == bestTarget; end);
            end
            if not chosenCombat then return nil; end
            local decision = Decision(chosenCombat.atk,chosenCombat.def,{attackingWith=chosenCombat.wep});
            if chosenCombat.atk ~= ai.startNode then
                decision.createPath(ai.startNode);
            end
            return decision;
        elseif unit.aiStrategy == "AGGRO" --[[aggro and nothing is in range yet--]] then
            print(unit.name .. " has no combats but is AGGRO and must move");
            local predictions = ai.getFightPredictions(unit,map);
            --select a best combat and store a reference to the enemy unit in that combat
            local sortedPredictions = ai.rankPredictions(unit,predictions)
            if #sortedPredictions < 1 then return nil; end --won't usually happen, but just in case we're doing debug stuff
            local bestTarget = sortedPredictions[1];
            --create a new nodes list, find the node containing the enemy, and fill that list with nav data
            local navNodes = map.nodes(unit);
            local targetNode = navNodes.oneDimensionDown().filter(function(x) return x.cell.occupant == bestTarget.opponent end);
            if #targetNode <= 0 then
                error("you somehow predicted a fight with a unit that's not on the map???");
            end
            targetNode = targetNode[1];
            local nodelist = Pathfinding.dijkstra(targetNode); --use your own movement from the enemy's position as a proxy for distance from the enemy
            --make sure you also stored the list of marked nodes it's possible to move to on this turn
            local potentialTargets = Pathfinding.intersectionWithOtherNodes(nodelist,ai.reachableNodes);
            --then, go through your marked nodes and pick one closest to the enemy nodes
            potentialTargets.sort(function(a,b) return a.costSoFar < b.costSoFar; end);
            local intermediateTarget = potentialTargets[1];
            local realIntermediateTarget = ai.reachableNodes.firstWhere(function(x) return (x.x == intermediateTarget.x) and (x.y == intermediateTarget.y); end); --because that's a different set of nodes with different connections "back"
            --then create a path from your start node and go there
            print("intermediate target: " .. realIntermediateTarget.x .. "," .. realIntermediateTarget.y);
            local decision = Decision(realIntermediateTarget,nil,{waiting=true});
            decision.createPath(ai.startNode); --no need to check if the attack is already here- there's no attack, you're definitely moving if you're in this state;
            return decision;
        else
            print(unit.name .. " has an unknown AI situation and ends turn");
            return nil;
        end
        return nil;
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
    ai.prepareTurnIntention = function(aiunit,battle) 
        aiunit.turnTaken = true;
        return ai.getDecision(aiunit.unit,battle.map);
    end

    ai.update = function()
    
    end

    return ai;
end
Decision = function(navTile,targetNode,options)
    local d = {};
    d.navTile = navTile; --the tile you're actually moving to
    d.targetNode = targetNode; --the thing you're doing an action on
    d.options = options;
    d.createPath = function(startNode)
        local pathBack = Array();
        local backNode = navTile;
        d.moveCSF = backNode.costSoFar;
        while backNode ~= startNode do
            pathBack.push(backNode);
            backNode = backNode.preferredConnBack.src;
        end
        pathBack.push(startNode);
        d.movePath = pathBack.reverse();
    end
    return d;
end
PossibleCombat = function(attackingNode,defendingNode,attackerWeapon,range)
    local pc = {};
    pc.atk = attackingNode;
    pc.def = defendingNode;
    pc.wep = attackerWeapon;
    pc.range = range;
    return pc;
end
