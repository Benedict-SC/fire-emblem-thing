tileSize = 50;
Battle = function(mapfile)
    local battle = {};
    battle.state = "MAINPHASE"; --PATHING, MOVING, ACTION, TARGET, COMBAT
    battle.map = Map(mapfile);
    battle.selector = love.graphics.newImage("assets/img/selector.png");
    battle.selectorPos = {x=1,y=1};
    battle.units = battle.map.units;
    battle.render = function()
        battle.map.renderTerrain();
        if battle.state == "PATHING" or battle.state == "MOVING" then
            for i=1,#(battle.movePath),1 do
                path.renderPathBit(battle.movePath,i);
            end
        end
        battle.map.renderUnits();
        if battle.state == "MAINPHASE" or battle.state == "PATHING" then
            if (battle.selectorPos.x >= 1 and battle.selectorPos.y >= 1) then
                love.graphics.draw(battle.selector,(battle.selectorPos.x - 1)*tileSize,(battle.selectorPos.y - 1)*tileSize)
            end
        end
        if battle.state == "ACTION" then
            battle.actionMenu.render({factor=1,xoff=0,yoff=0});
        end
    end
    battle.update = function()
        battle.updateSelectorPosition();
        if battle.state == "MAINPHASE" then
            if(battle.input_detail()) then --We want to pull up the stats for some unit on the battlefield
                local occ = battle.map.cells[battle.selectorPos.y][battle.selectorPos.x].occupant;
                if occ then
                    game.statspage.unit = occ;
                    game.statspage.setAlignment(occ.faction);
                    game.state = "STATS";
                end
            elseif(battle.input_select()) then --We've clicked on a specific map square to take some action on it
                local occ = battle.map.cells[battle.selectorPos.y][battle.selectorPos.x].occupant;
                if occ --[[and not occ.movedThisTurn]] then --we've clicked a unit, so we're going to get its range set up and change states to the PATHING state.
                    local nodes = battle.map.nodes(occ); --get the navigation nodes
                    local startNode = nodes[battle.selectorPos.y][battle.selectorPos.x];
                    local nodes1D = nodes.oneDimensionDown();
                    local nodelist = dijkstra(startNode,occ.mov); --populate the navigation nodes with costs and get the subset of nodes that are considered in-range
                    for i=1,#nodelist,1 do --for all those nodes, turn on the valid-move-option overlay
                        local node = nodelist[i];
                        node.marked = true; --mark it so we can subtract it to get out-of-range nodes;
                        battle.map.cells[node.y][node.x].moveOn = true;
                    end
                    --now let's calculate attack ranges
                    local ranges = occ.getRangeSpan();
                    local unmarked = nodes1D.filter(function(x) return not (x.marked) end); --get just the nodes out of range
                    for i=1,#ranges,1 do
                        for j=1,#unmarked,1 do --for each attack range, have each out-of-move-range check if any of the in-move-range spaces are within that attack range. assume attack ranges are commutative and not blocked by walls. TODO: revise this if that assumption changes
                            local target = unmarked[j];
                            local nodesWithoutFriends = nodelist.filter(function(x) 
                                local rangeOcc = battle.map.cellFromNode(x).occupant;
                                return rangeOcc == nil or rangeOcc == occ;
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
                    battle.state = "PATHING";
                    battle.initMovement(nodes,startNode);
                end
            end
        elseif (battle.state == "PATHING") then
            battle.processNodePath();
            if battle.input_select() then --we've clicked on a space to move to
                local cell = battle.map.cells[battle.selectorPos.y][battle.selectorPos.x];
                local node = battle.moveNodes[battle.selectorPos.y][battle.selectorPos.x];

                if (not node.hittable) and (not node.marked) then
                    --do nothing- out of range, invalid input
                elseif cell.occupant == battle.moveUnit then 
                    --you're not moving this turn- just go to the action state immediately
                elseif cell.occupant and not cell.occupant.friendly and node.hittable then --you're trying to attack an enemy
                    --check if the terminus of the path arrow is in range of the occupant
                    --if so, move there, and when done moving there, transition straight to combat preview instead of action
                    --if not, find any marked nodes in range of the target, and select the lowest CSF to move to before transitioning
                elseif cell.occupant and cell.occupant.friendly then 
                    --whoops, that's just a friend- it'll show up in your movement range but don't try and move there. invalid input.
                elseif node.hittable and cell.occupant then
                    --transition straight to the attack menu
                elseif node.hittable and not cell.occupant then
                    --that's not a valid movement target
                else --you're moving to an empty square. 
                    battle.clearOverlays();
                    battle.moveUnit.walkIndex = 1;
                    local segFunc = function(percent) 
                        local u = battle.moveUnit;
                        local origin = battle.movePath[1];
                        local src = battle.movePath[u.walkIndex];
                        local dest = battle.movePath[u.walkIndex + 1];
                        local srcOffX = tileSize * (src.x - origin.x);
                        local srcOffY = tileSize * (src.y - origin.y);
                        local segmentOffX = percent * tileSize * (dest.x - src.x);
                        local segmentOffY = percent * tileSize * (dest.y - src.y);
                        u.xoff = srcOffX + segmentOffX;
                        u.yoff = srcOffY + segmentOffY;
                        --also maybe change the orientation of the movement sprite if we're doing that                        
                    end
                    local segEndFunc;
                    segEndFunc = function()
                        local u = battle.moveUnit;
                        u.walkIndex = u.walkIndex + 1;
                        if u.walkIndex == #battle.movePath then
                            battle.map.moveUnitFromTo(battle.movePath[1].x,
                                                battle.movePath[1].y,
                                                battle.movePath[#battle.movePath].x,
                                                battle.movePath[#battle.movePath].y);
                            u.xoff = 0;
                            u.yoff = 0;
                            u.walkIndex = nil;
                            battle.actionMenu = ActionMenu(u);
                            battle.resetPathing();
                            battle.state = "ACTION"; --TODO: ACTION
                        else
                            async.doOverTime(0.06,segFunc,segEndFunc);
                        end
                    end
                    battle.state = "MOVING";
                    async.doOverTime(0.1,segFunc,segEndFunc);
                end
            elseif battle.input_cancel() then
                battle.resetPathing();
                battle.clearOverlays();
                battle.state = "MAINPHASE";
            end
        elseif (battle.state == "MOVING") then
            --skip and cancel inputs during the walk go here
        elseif (battle.state == "ACTION") then
            if battle.input_select() then
                battle.state = "MAINPHASE";
            end
        elseif (battle.state == "TARGET") then
        elseif (battle.state == "COMBAT") then
        end
    end
    --SECTION: MOVEMENT STATE PATHFINDING
    battle.resetPathing = function()
        battle.movePath = Array();
        battle.moveNodes = nil;
        battle.moveStart = nil;
        battle.moveBudget = 0;
        battle.moveCSF = 0;
        battle.moveUnit = nil;
    end
    battle.resetPathing();
    battle.initMovement = function(nodes,startNode)
        battle.moveUnit = battle.map.cells[startNode.y][startNode.x].occupant;
        battle.moveBudget = battle.moveUnit.mov;
        battle.moveNodes = nodes;
        battle.movePath = Array();
        battle.moveStart = startNode;
        battle.moveCSF = 0;
        battle.movePath.push(startNode);
    end
    battle.processNodePath = function()
        if not battle.selectorInBounds() then return; end
        local hoverNode = battle.moveNodes[battle.selectorPos.y][battle.selectorPos.x];
        local hoverCell = battle.map.cellFromNode(hoverNode);
        if not (hoverNode.marked) then --the hovered node is out of range, so don't do anything
            return;
        end
        local dist = hoverNode.manhattanDistance(battle.movePath[#battle.movePath]);
        if dist == 0 then --we haven't moved cells, so don't do anything right now
            return;
        end --otherwise, we have, so handle different cases
        --first, the case where you've already got the node on the path. clip the path to that node.
        if battle.movePath.has(hoverNode) then
            local clippedPath = Array();
            battle.moveCSF = 0; --reset CSF
            for i=1,#(battle.movePath),1 do --re-add it to the path and update cost-so-far
                local clipNode = battle.movePath[i];
                local clipCSF = battle.map.costToEnter(battle.moveUnit,battle.map.cellFromNode(clipNode));
                clippedPath.push(battle.movePath[i]);
                if clipNode ~= battle.moveStart then
                    battle.moveCSF = battle.moveCSF + clipCSF;
                end
                if battle.movePath[i] == hoverNode then
                    break;
                end
            end
            battle.movePath = clippedPath;
            return;
        end
        --otherwise, it's an unfamiliar node. 
        if dist == 1 then --we're adding to the continuity of the path
            --first, check the cost and see if it's in our movement budget.
            local nodeCost = battle.map.costToEnter(battle.moveUnit,hoverCell);
            if battle.moveCSF + nodeCost <= battle.moveBudget then --we're fine
                battle.movePath.push(hoverNode);
                battle.moveCSF = battle.moveCSF + nodeCost;
                return;
            end
        end 
        --if we get through to here, we're on a cell that's in our range but we've lost continuity, so default to the shortest path.
        local pathBack = Array();
        local backNode = hoverNode;
        battle.moveCSF = backNode.costSoFar;
        while backNode ~= battle.moveStart do
            pathBack.push(backNode);
            backNode = backNode.preferredConnBack.src;
        end
        pathBack.push(battle.moveStart);
        battle.movePath = pathBack.reverse();
    end
    battle.clearOverlays = function()
        for i=1,#battle.map.cells,1 do
            for j=1,#battle.map.cells[1],1 do
                battle.map.cells[i][j].moveOn = false;
                battle.map.cells[i][j].hitOn = false;
            end
        end
    end
    --SECTION: INPUT PROCESSING FUNCTIONS
    battle.updateSelectorPosition = function()
        if (controlMode == "KEYBOARD" or controlMode == "CONTROLLER") then
            if input["down"] then
                local turboThisFrame = turbosProcessed["down"] < turboCounts["down"];
                if turboThisFrame then turbosProcessed["down"] = turbosProcessed["down"] + 1; end
                if pressedThisFrame["down"] or turboThisFrame then
                    battle.selectorPos.y = battle.selectorPos.y + 1;
                    if battle.selectorPos.y > #battle.map.cells then battle.selectorPos.y = #battle.map.cells; end
                end
            end
            if input["up"] then 
                local turboThisFrame = turbosProcessed["up"] < turboCounts["up"];
                if turboThisFrame then turbosProcessed["up"] = turbosProcessed["up"] + 1; end
                if pressedThisFrame["up"] or turboThisFrame then
                    battle.selectorPos.y = battle.selectorPos.y - 1;
                    if battle.selectorPos.y < 1 then battle.selectorPos.y = 1; end
                end
            end
            if input["right"] then 
                local turboThisFrame = turbosProcessed["right"] < turboCounts["right"];
                if turboThisFrame then turbosProcessed["right"] = turbosProcessed["right"] + 1; end
                if pressedThisFrame["right"] or turboThisFrame then
                    battle.selectorPos.x = battle.selectorPos.x + 1;
                    if battle.selectorPos.x > #battle.map.cells[1] then battle.selectorPos.x = #battle.map.cells[1]; end
                end
            end
            if input["left"] then 
                local turboThisFrame = turbosProcessed["left"] < turboCounts["left"];
                if turboThisFrame then turbosProcessed["left"] = turbosProcessed["left"] + 1; end
                if pressedThisFrame["left"] or turboThisFrame then
                    battle.selectorPos.x = battle.selectorPos.x - 1;
                    if battle.selectorPos.x < 1 then battle.selectorPos.x = 1; end
                end
            end
        elseif controlMode == "MOUSE" then
            local mx,my = love.mouse.getPosition();
            battle.selectorPos.x = math.floor(mx/tileSize) + 1;
            battle.selectorPos.y = math.floor(my/tileSize) + 1;
        end
    end
    battle.input_detail = function()
        local inbounds = battle.selectorInBounds();
        local mouseinput = pressedThisFrame.mouse2;
        local otherinput = pressedThisFrame.inspect;
        return inbounds and (mouseinput or otherinput);
    end
    battle.input_select = function()
        local inbounds = battle.selectorInBounds();
        local mouseinput = pressedThisFrame.mouse1;
        local otherinput = pressedThisFrame.action;
        return inbounds and (mouseinput or otherinput);
    end
    battle.input_cancel = function()
        local mouseinput = false;
        if(battle.state == "PATHING") then
            mouseinput = pressedThisFrame.mouse2;
        end
        local otherinput = pressedThisFrame.cancel;
        return mouseinput or otherinput;
    end
    battle.selectorInBounds = function()
        local s = battle.selectorPos;
        local maxX = battle.map.cells[1].size;
        local maxY = battle.map.cells.size;
        return s.x > 0 and s.x <= maxX and s.y > 0 and s.y <= maxY;
    end
    return battle;
end