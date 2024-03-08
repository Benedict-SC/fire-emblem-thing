Battle = function(mapfile)
    local battle = {};
    battle.state = "PREBATTLE"; --MAINPHASE, PATHING, MOVING, ACTION, PICKWEAPON, GLOBALMENU, COMBATPREVIEW, TARGET, COMBAT, DISPLAY, TALK, REPOSITION, OVERVIEW, PREBATTLE
    battle.map = Map(mapfile);
    battle.displayStuff = Array();
    battle.camera = BattleCam();

    battle.selector = love.graphics.newImage("assets/img/selector.png");
    battle.selectorPos = {x=5,y=5};
    battle.units = battle.map.units;
    battle.casualties = Array();
    battle.activeFaction = #(battle.map.factionOrder);

    battle.preBattleMenu = PreBattleMenu();
    battle.repositionCell = nil;

    battle.render = function()
        --DEBUG_TEXT = battle.state;
        love.graphics.pushCanvas(battle.map.drawCanvas);
        battle.map.renderTerrain();
        if battle.state == "PATHING" or battle.state == "MOVING" then
            for i=1,#(battle.movePath),1 do
                path.renderPathBit(battle.movePath,i);
            end
        end
        if battle.state == "REPOSITION" or battle.repositionCell then
            battle.map.renderStartingPositions();
            if (battle.repositionCell and battle.state == "REPOSITION") then
                love.graphics.draw(battle.selector,(battle.repositionCell.occupant.x - 1)*game.tileSize,(battle.repositionCell.occupant.y - 1)*game.tileSize)
            end
        end
        battle.map.renderUnits();
        if battle.state == "MAINPHASE" or battle.state == "PATHING" or battle.state == "COMBATPREVIEW" or battle.state == "REPOSITION" or battle.state == "OVERVIEW" then
            if (battle.selectorPos.x >= 1 and battle.selectorPos.y >= 1) then
                love.graphics.draw(battle.selector,(battle.selectorPos.x - 1)*game.tileSize,(battle.selectorPos.y - 1)*game.tileSize)
            end
        end
        love.graphics.popCanvas();
        love.graphics.draw(battle.map.drawCanvas,-battle.camera.xoff,-battle.camera.yoff,0,battle.camera.factor,battle.camera.factor);
        if battle.state == "ACTION" or battle.state == "PICKWEAPON" or battle.state == "GLOBALMENU" or battle.state == "PREBATTLE" then
            local menus = {["ACTION"]=battle.actionMenu,["PICKWEAPON"]=battle.pickWeaponMenu,["GLOBALMENU"]=battle.globalMenu,["PREBATTLE"]=battle.preBattleMenu};
            local menuToRender = menus[battle.state];
            menuToRender.render(battle.camera);
        end
        if battle.state == "COMBATPREVIEW" then
            battle.fight.renderPreview();
        end
        if (battle.state == "COMBAT") then
            battle.fightScreen.render();
        end
        if battle.state == "TALK" then
            battle.convo.render();
        end
        if battle.state == "DISPLAY" then
            for i=1,#(battle.displayStuff),1 do
                local thing = battle.displayStuff[i];
                love.graphics.draw(thing.drawable,thing.x,thing.y);
            end
        end
    end
    battle.update = function()
        battle.processZoomInput();
        if battle.state == "MAINPHASE" then
            battle.updateSelectorPosition();
            if(battle.input_detail()) then --We want to pull up the stats for some unit on the battlefield
                local occ = battle.map.cells[battle.selectorPos.y][battle.selectorPos.x].occupant;
                if occ then
                    game.statspage.unit = occ;
                    game.statspage.setAlignment(occ.faction);
                    game.state = "STATS";
                elseif controlMode == "MOUSE" then --you've right-clicked but the square is empty
                    battle.globalMenu = BlankMenu(battle.selectorPos.x,battle.selectorPos.y);
                    battle.state = "GLOBALMENU";
                end
            elseif(battle.input_select()) then --We've clicked on a specific map square to take some action on it
                local occ = battle.map.cells[battle.selectorPos.y][battle.selectorPos.x].occupant;
                if occ and not occ.used and occ.faction == battle.map.factionOrder[battle.activeFaction] then --we've clicked an unused friendly unit, so we're going to get its range set up and change states to the PATHING state.
                    battle.pathfind(occ);
                elseif controlMode ~= "MOUSE" then --we've selected an empty square, an enemy, or a used unit, and should pull up the map menu.
                    battle.globalMenu = BlankMenu(battle.selectorPos.x,battle.selectorPos.y);
                    battle.state = "GLOBALMENU";
                end
                battle.recenterOnSelector();
            end
        elseif (battle.state == "REPOSITION") then
            battle.updateSelectorPosition();
            if(battle.input_detail()) then
                local occ = battle.map.cells[battle.selectorPos.y][battle.selectorPos.x].occupant;
                if occ then
                    game.statspage.unit = occ;
                    game.statspage.setAlignment(occ.faction);
                    game.state = "STATS";
                elseif controlMode == "MOUSE" then
                    if battle.repositionCell then
                        battle.repositionCell = nil;
                    else
                        battle.state = "PREBATTLE";
                    end
                end
            elseif(battle.input_select()) then 
                local cell = battle.map.cells[battle.selectorPos.y][battle.selectorPos.x];
                local occ = cell.occupant;
                if cell.isStartingPosition then
                    if battle.repositionCell then
                        if occ then --we're swapping two units
                            local mover = battle.repositionCell.occupant;
                            local movee = occ;
                            if not (mover == movee) --[[don't swap with yourself--]] then 
                                battle.state = "DISPLAY";
                                MoveFX.circleSwapUnits(mover,movee,0.15,function() 
                                    battle.repositionCell.occupant = movee;
                                    cell.occupant = mover;
                                    battle.repositionCell = nil;
                                    local moverx = mover.x;
                                    local movery = mover.y;
                                    mover.x = movee.x;
                                    mover.y = movee.y;
                                    movee.x = moverx;
                                    movee.y = movery;
                                    battle.state = "REPOSITION";
                                end);
                            end
                        else --we're moving repositionCell.occupant to this cell
                            local mover = battle.repositionCell.occupant;
                            battle.state = "DISPLAY";
                            local target= {x = battle.selectorPos.x,y = battle.selectorPos.y};
                            MoveFX.circleSwapUnits(mover,target,0.15,function() 
                                cell.occupant = mover;
                                battle.repositionCell.occupant = nil;
                                battle.repositionCell = nil;
                                mover.x = target.x;
                                mover.y = target.y;
                                battle.state = "REPOSITION";
                            end);
                        end
                    elseif occ then 
                        battle.repositionCell = cell;
                    else
                        --nothing here! "nuh-uh" sound
                    end
                else
                    --play some "nuh-uh" sound effect
                end
                battle.recenterOnSelector();
            elseif(battle.input_cancel()) then
                if battle.repositionCell then
                    battle.repositionCell = nil;
                else
                    battle.state = "PREBATTLE";
                end
            end
        elseif (battle.state == "OVERVIEW") then
            battle.updateSelectorPosition();
            if(battle.input_detail()) then
                local occ = battle.map.cells[battle.selectorPos.y][battle.selectorPos.x].occupant;
                if occ then
                    game.statspage.unit = occ;
                    game.statspage.setAlignment(occ.faction);
                    game.state = "STATS";
                elseif controlMode == "MOUSE" then
                    battle.state = "PREBATTLE";
                end
            elseif(battle.input_cancel()) then
                battle.state = "PREBATTLE"; 
            end
        elseif (battle.state == "PATHING") then
            battle.updateSelectorPosition();
            battle.processNodePath();
            if battle.input_select() then --we've clicked on a space to move to
                local cell = battle.map.cells[battle.selectorPos.y][battle.selectorPos.x];
                local node = battle.moveNodes[battle.selectorPos.y][battle.selectorPos.x];

                if (not node.hittable) and (not node.marked) then
                    --do nothing- out of range, invalid input
                elseif cell.occupant == battle.moveUnit then 
                    --that's you- you're not moving, go straight to the action state.
                    battle.actionMenu = ActionMenu(battle.moveUnit);
                    battle.originalCoords = {y=battle.moveUnit.y,x=battle.moveUnit.x};
                    battle.resetPathing();
                    battle.state = "ACTION"; --TODO: ACTION
                elseif node.hittable and not cell.occupant then
                    --that's not a valid movement target
                elseif node.hittable and cell.occupant and not battle.moveUnit.friendly(cell.occupant) then --you're trying to attack an enemy
                    --check if the terminus of the path arrow is in range of the occupant
                    --if so, move there, and when done moving there, transition straight to combat preview instead of action
                    --if not, find any marked nodes in range of the target, and select the lowest CSF to move to before transitioning
                elseif node.hittable and cell.occupant then --occupant is friendly
                    --either do all that stuff from the previous step but go to heal instead if heal is your only 1-range option
                    --otherwise invalid input
                elseif cell.occupant and battle.moveUnit.friendly(cell.occupant) then 
                    --whoops, that's just a friend- it'll show up in your movement range but don't try and move there. invalid input.
                else --you're moving to an empty square. 
                    battle.clearOverlays();
                    battle.moveUnit.walkIndex = 1;
                    battle.originalCoords = {y=battle.moveUnit.y,x=battle.moveUnit.x};
                    local segFunc = function(percent) 
                        local u = battle.moveUnit;
                        local origin = battle.movePath[1];
                        local src = battle.movePath[u.walkIndex];
                        local dest = battle.movePath[u.walkIndex + 1];
                        local srcOffX = game.tileSize * (src.x - origin.x);
                        local srcOffY = game.tileSize * (src.y - origin.y);
                        local segmentOffX = percent * game.tileSize * (dest.x - src.x);
                        local segmentOffY = percent * game.tileSize * (dest.y - src.y);
                        u.xoff = srcOffX + segmentOffX;
                        u.yoff = srcOffY + segmentOffY;
                        --also maybe change the orientation of the movement sprite if we're doing that                        
                    end
                    local segEndFunc;
                    segEndFunc = function()
                        local u = battle.moveUnit;
                        u.walkIndex = u.walkIndex + 1;
                        if u.walkIndex == #battle.movePath then
                            local wx = battle.movePath[#battle.movePath].x;
                            local wy = battle.movePath[#battle.movePath].y;
                            battle.map.moveUnitTo(u,wx,wy);                            
                            battle.camera.recenter(battle,wx,wy);
                            u.xoff = 0;
                            u.yoff = 0;
                            u.walkIndex = nil;
                            battle.actionMenu = ActionMenu(u);
                            battle.resetPathing();
                            battle.state = "ACTION"; --TODO: ACTION
                        else                     
                            battle.camera.recenter(battle,
                                    battle.movePath[u.walkIndex].x,
                                    battle.movePath[u.walkIndex].y);
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
        elseif (battle.state == "ACTION") or (battle.state == "PICKWEAPON") or (battle.state == "GLOBALMENU") or (battle.state == "PREBATTLE") then
            local menus = {["ACTION"]=battle.actionMenu,["PICKWEAPON"]=battle.pickWeaponMenu,["GLOBALMENU"]=battle.globalMenu,["PREBATTLE"]=battle.preBattleMenu};
            local menuToControl = menus[battle.state];
            if battle.input_cancel() then
                if battle.state == "PICKWEAPON" then 
                    battle.state = "ACTION"; 
                elseif battle.state == "ACTION" then
                    battle.map.moveUnitTo(battle.actionMenu.unit,
                                            battle.originalCoords.x,
                                            battle.originalCoords.y);
                    battle.pathfind(battle.actionMenu.unit);
                elseif battle.state == "GLOBALMENU" then
                    battle.state = "MAINPHASE";
                end
            else
                if controlMode == "MOUSE" then
                    menuToControl.setCursorWithMouse(battle.camera);
                    if battle.input_select() then
                        menuToControl.executeCurrentOption();
                    end
                else
                    if battle.input_select() then
                        menuToControl.executeCurrentOption();
                    elseif pressedThisFrame["up"] then
                        menuToControl.moveCursor(-1);
                    elseif pressedThisFrame["down"] then
                        menuToControl.moveCursor(1);
                    end
                end
            end
        elseif (battle.state == "COMBATPREVIEW") then
            --special selector positioning
            battle.updateTargetingSelector();
            local targetUnit = battle.map.cells[battle.selectorPos.y][battle.selectorPos.x].occupant;
            if (battle.fight.def ~= targetUnit) then  
                battle.fight = Fight(battle.pickWeaponMenu.unit,targetUnit);
            end
            if battle.input_cancel() then
                battle.state = "PICKWEAPON";
            end
            if battle.input_select() then
                battle.fightScreen = FightScreen(battle.fight);
                battle.clearOverlays();
                battle.fightScreen.begin();
                battle.state = "COMBAT";
            end
        elseif (battle.state == "TARGET") then
        elseif (battle.state == "COMBAT") then
            battle.fightScreen.update();
        elseif (battle.state == "TALK") then
            battle.convo.update();
        end
    end
    --SECTION: EXTERNAL CONTROL
    battle.resolveFight = function()
        local target = battle.fightScreen.fight.def;
        if target.hp <= 0 then
            battle.killUnit(target,battle.resolveAttackerEffects);
        else
            battle.resolveAttackerEffects();
        end
    end
    battle.resolveAttackerEffects = function()
        local unit = battle.fightScreen.fight.agg;
        if unit.hp <= 0 then --whoops, kill 'em
            battle.killUnit(unit,function() 
                battle.endUnitsTurn(unit);
            end);
        else --they're alive!
            if unit.doesCanto() then

            else
                --TODO: check if the turn is over and change phases if so
                battle.endUnitsTurn(unit);
            end
        end
    end
    battle.changePhase = function()
        battle.map.units.forEach(function(x) 
            x.used = false;
        end);
        battle.activeFaction = battle.activeFaction + 1;
        if battle.activeFaction > #(battle.map.factionOrder) then battle.activeFaction = 1; end

        battle.state = "DISPLAY";
        battle.displayStuff = Array();
        local faction = battle.map.factionOrder[battle.activeFaction];
        local factionBannerUrl = "assets/img/phase-other.png";
        if faction == "PLAYER" then
            factionBannerUrl = "assets/img/phase-player.png"
        elseif faction == "ENEMY" then
            factionBannerUrl = "assets/img/phase-enemy.png"
        end
        local phaseText = love.graphics.newImage(factionBannerUrl);

        local ptThing = {};
        ptThing.drawable = phaseText;
        ptThing.x = -400;
        ptThing.y = 100;
        battle.displayStuff.push(ptThing);
        async.doOverTime(0.3,function(percent) 
            ptThing.x = -400 + math.floor(percent * 500 + 0.5);
        end,function() 
            async.wait(1.0,function()
                async.doOverTime(0.3,function(percent) 
                    ptThing.x = 100 + math.floor(percent * 500 + 0.5);
                end,function() 
                    battle.state = "MAINPHASE";
                end)
            end);
        end)
    end
    battle.killUnit = function(unit,whendone)
        battle.casualties.push(unit);
        unit.markedForDeath = true;
        unit.deathFlash = 0;
        unit.deathAlpha = 1;
        async.doOverTime(0.5,function(percent) 
            unit.deathFlash = 1- math.abs(percent * 2 - 1);
            if percent > 0.5 then
                unit.deathAlpha = 1 - ((percent-0.5) * 2);
            else
                unit.deathAlpha = 1;
            end
        end,function() 
            battle.map.removeUnit(unit);
            whendone();
        end);
    end
    battle.endUnitsTurn = function(unit)
        unit.used = true;
        local factionName = battle.map.factionOrder[battle.activeFaction];
        if factionName == "PLAYER" then
            local unused = battle.map.playerUnits().filter(function(x) 
                return not x.used;
            end);
            if #unused <= 0 then
                battle.changePhase();
            else 
                battle.state = "MAINPHASE";
            end
        else
            local unused = battle.map.factionUnits(factionName).filter(function(x) 
                return not x.used;
            end);
            if #unused <= 0 then
                battle.changePhase();
            else 
                battle.state = "MAINPHASE"; --TODO: queue up next AI turn, actually
            end            
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
    battle.pathfind = function(occ)
        local nodes = battle.map.nodes(occ); --get the navigation nodes
        local startNode = nodes[occ.y][occ.x];
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
            battle.recenterOnSelector();
        elseif controlMode == "MOUSE" then
            local mx,my = love.mouse.getPosition();
            mx = mx + battle.camera.xoff;
            my = my + battle.camera.yoff;
            mx = math.floor(mx / battle.camera.factor + 0.5);
            my = math.floor(my / battle.camera.factor + 0.5);
            battle.selectorPos.x = math.floor(mx/game.tileSize) + 1;
            battle.selectorPos.y = math.floor(my/game.tileSize) + 1;
        end
    end
    battle.updateTargetingSelector = function()
        if controlMode == "MOUSE" then
            local mx,my = love.mouse.getPosition();
            mx = mx + battle.camera.xoff;
            my = my + battle.camera.yoff;
            mx = math.floor(mx / battle.camera.factor + 0.5);
            my = math.floor(my / battle.camera.factor + 0.5);
            local x = math.floor(mx/game.tileSize) + 1;
            local y = math.floor(my/game.tileSize) + 1;
            local matchingUnits = battle.horizontalTargetList.filter(function(u) return u.x == x and u.y == y; end);
            if matchingUnits.size > 0 then
                local unit = matchingUnits[1];
                battle.horizontalTargetIndex = battle.horizontalTargetList.indexOf(unit);
                battle.verticalTargetIndex = battle.verticalTargetList.indexOf(unit);
                battle.selectorPos.x = x;
                battle.selectorPos.y = y;
                --battle.camera.recenter(battle,x,y);
            end
        elseif controlMode == "KEYBOARD" then
            if pressedThisFrame["right"] then
                battle.horizontalTargetIndex = battle.horizontalTargetIndex + 1;
                if battle.horizontalTargetIndex > battle.horizontalTargetList.size then
                    battle.horizontalTargetIndex = 1;
                end
                local unit = battle.horizontalTargetList[battle.horizontalTargetIndex];
                battle.verticalTargetIndex = battle.verticalTargetList.indexOf(unit);
                battle.selectorPos.x = unit.x;
                battle.selectorPos.y = unit.y;
            elseif pressedThisFrame["left"] then
                battle.horizontalTargetIndex = battle.horizontalTargetIndex - 1;
                if battle.horizontalTargetIndex < 1 then
                    battle.horizontalTargetIndex = battle.horizontalTargetList.size;
                end
                local unit = battle.horizontalTargetList[battle.horizontalTargetIndex];
                battle.verticalTargetIndex = battle.verticalTargetList.indexOf(unit);
                battle.selectorPos.x = unit.x;
                battle.selectorPos.y = unit.y;
            elseif pressedThisFrame["down"] then
                battle.verticalTargetIndex = battle.verticalTargetIndex + 1;
                if battle.verticalTargetIndex > battle.verticalTargetList.size then
                    battle.verticalTargetIndex = 1;
                end
                local unit = battle.verticalTargetList[battle.verticalTargetIndex];
                battle.horizontalTargetIndex = battle.horizontalTargetList.indexOf(unit);
                battle.selectorPos.x = unit.x;
                battle.selectorPos.y = unit.y;
            elseif pressedThisFrame["up"] then
                battle.verticalTargetIndex = battle.verticalTargetIndex - 1;
                if battle.verticalTargetIndex < 1 then
                    battle.verticalTargetIndex = battle.verticalTargetList.size;
                end
                
                local unit = battle.verticalTargetList[battle.verticalTargetIndex];
                if not unit then
                    error("bad index: " .. battle.verticalTargetIndex);
                end
                battle.horizontalTargetIndex = battle.horizontalTargetList.indexOf(unit);
                battle.selectorPos.x = unit.x;
                battle.selectorPos.y = unit.y;
                battle.camera.recenter(battle,unit.x,unit.y);
            end
        elseif controlMode == "CONTROLLER" then
            if pressedThisFrame["up"] or pressedThisFrame["down"] or pressedThisFrame["left"] or pressedThisFrame["right"] then
                local vec = input.getNormalizedJoystickVector();
                --[[local targetSpace = {x=battle.selectorPos.x + vec.x,y=battle.selectorPos.y + vec.y};
                local matchingUnits = battle.verticalTargetList.filter(function(unit) 
                    return (unit.x == targetSpace.x) and (unit.y == targetSpace.y);
                end);
                if (matchingUnits.size > 0) then
                    local unit = matchingUnits[1];
                    battle.selectorPos.x = unit.x;
                    battle.selectorPos.y = unit.y;
                    battle.horizontalTargetIndex = battle.horizontalTargetList.indexOf(unit);
                    battle.verticalTargetIndex = battle.verticalTargetList.indexOf(unit);
                end]]--
                local snapSelect = false; 
                if #(battle.pickWeaponMenu.selectedWeapon.range) == 1 then
                    local manhattanVec = input.getManhattanNormalizedJoystickVector(battle.pickWeaponMenu.selectedWeapon.range[1]);
                    local targetSpace = {x=battle.pickWeaponMenu.unit.x + manhattanVec.x,y=battle.pickWeaponMenu.unit.y + manhattanVec.y};
                    local matchingUnits = battle.verticalTargetList.filter(function(unit) 
                        return (unit.x == targetSpace.x) and (unit.y == targetSpace.y);
                    end);
                    if matchingUnits.size >= 1 then
                        local unit = matchingUnits[1];
                        battle.selectorPos.x = unit.x;
                        battle.selectorPos.y = unit.y;
                        battle.horizontalTargetIndex = battle.horizontalTargetList.indexOf(unit);
                        battle.verticalTargetIndex = battle.verticalTargetList.indexOf(unit);
                        snapSelect = true;
                    end
                end
                if not snapSelect then --no unit was found to snap to, so we do it the hard way
                    if vec.y == 0 then 
                        battle.horizontalTargetIndex = battle.horizontalTargetIndex + vec.x;
                        if battle.horizontalTargetIndex < 1 then
                            battle.horizontalTargetIndex = battle.horizontalTargetList.size;
                        end  
                        if battle.horizontalTargetIndex > battle.horizontalTargetList.size then
                            battle.horizontalTargetIndex = 1;
                        end
                        local unit = battle.horizontalTargetList[battle.horizontalTargetIndex];
                        battle.verticalTargetIndex = battle.verticalTargetList.indexOf(unit);
                        battle.selectorPos.x = unit.x;
                        battle.selectorPos.y = unit.y;
                    else
                        battle.verticalTargetIndex = battle.verticalTargetIndex + vec.y;
                        if battle.verticalTargetIndex < 1 then
                            battle.verticalTargetIndex = battle.verticalTargetList.size;
                        end
                        if battle.verticalTargetIndex > battle.verticalTargetList.size then
                            battle.verticalTargetIndex = 1;
                        end
                        
                        local unit = battle.verticalTargetList[battle.verticalTargetIndex];
                        battle.horizontalTargetIndex = battle.horizontalTargetList.indexOf(unit);
                        battle.selectorPos.x = unit.x;
                        battle.selectorPos.y = unit.y;
                    end
                end
            end
        end
        
    end
    battle.recenterOnSelector = function()
        battle.camera.recenter(battle,battle.selectorPos.x,battle.selectorPos.y);
    end
    battle.processZoomInput = function()
        if pressedThisFrame["zoomIn"] then
            battle.camera.zoom(1);
            battle.recenterOnSelector();
        elseif pressedThisFrame["zoomOut"] then
            battle.camera.zoom(-1);
            battle.recenterOnSelector();
        end
    end
    battle.input_detail = function(ignoreBounds)
        local inbounds = battle.selectorInBounds();
        local mouseinput = pressedThisFrame.mouse2;
        local otherinput = pressedThisFrame.inspect;
        return (ignoreBounds or inbounds) and (mouseinput or otherinput);
    end
    battle.input_select = function(ignoreBounds)
        local inbounds = battle.selectorInBounds();
        local mouseinput = pressedThisFrame.mouse1;
        local otherinput = pressedThisFrame.action;
        return (ignoreBounds or inbounds) and (mouseinput or otherinput);
    end
    battle.input_cancel = function()
        local mouseinput = false;
        --if(battle.state == "PATHING" or battle.state == "ACTION" or battle.state == "PICKWEAPON" or battle.state == "COMBATPREVIEW") then
        if battle.state ~= "MAINPHASE" then
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