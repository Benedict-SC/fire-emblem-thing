MoveFX = {};
MoveFX.circleSwapUnits = function(unit1,unit2,seconds,whenDone)
    local point1 = {x=(unit1.x - 1)*game.tileSize,y=(unit1.y - 1)*game.tileSize};
    local point2 = {x=(unit2.x - 1)*game.tileSize,y=(unit2.y - 1)*game.tileSize};

    local midpoint = {x=(point1.x+point2.x)/2,y=(point1.y+point2.y)/2};
    local xdist1 = midpoint.x-point1.x;
    local ydist1 = midpoint.y-point1.y;
    local radius = math.sqrt((xdist1*xdist1)+(ydist1*ydist1));
    local angle1 = math.atan(ydist1/xdist1);
    if xdist1 > 0 then --atan can't tell sign
        angle1 = angle1 + math.pi; 
    elseif xdist1 < 0 then
        --do nothing
    else --oh hell x is 0
        if ydist1 < 0 then
            angle1 = math.pi/2;
        else
            angle1 = 3*math.pi/2
        end
    end 
    local angle2 = angle1+math.pi;

    async.doOverTime(seconds,function(percent) 
        local angularDisplacement = percent*math.pi;
        local newpoint1 = {x=math.cos(angle1 + angularDisplacement)*radius,y=math.sin(angle1+angularDisplacement)*radius};
        local newpoint2 = {x=math.cos(angle2 + angularDisplacement)*radius,y=math.sin(angle2+angularDisplacement)*radius};
        --DEBUG_TEXT = "point1: " .. newpoint1.x .. "/" .. newpoint1.y;
        if unit1 then
            unit1.xoff = (newpoint1.x + midpoint.x) - point1.x;
            unit1.yoff = (newpoint1.y + midpoint.y) - point1.y;
        end
        if unit2 then
            unit2.xoff = (newpoint2.x + midpoint.x) - point2.x;
            unit2.yoff = (newpoint2.y + midpoint.y) - point2.y;
        end
    end,function() 
        if unit1 then
            unit1.xoff = 0;
            unit1.yoff = 0;
        end
        if unit2 then
            unit2.xoff = 0;
            unit2.yoff = 0;
        end
        whenDone();
    end);
end