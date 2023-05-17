path = {};
path.bits = {love.graphics.newImage("assets/img/path-start.png"),
            love.graphics.newImage("assets/img/path-straight.png"),
            love.graphics.newImage("assets/img/path-bend.png"),
            love.graphics.newImage("assets/img/path-cap.png"),
            love.graphics.newImage("assets/img/path-any.png")};
path.renderPathBit = function(movepath,idx)
    if (#movepath <= 1) then return; end
    local rotations = 0;
    local bitIdx;
    if idx == 1 then
        bitIdx = 1;
        nextBitXDelta = movepath[idx+1].x - movepath[idx].x;
        nextBitYDelta = movepath[idx+1].y - movepath[idx].y;
        if nextBitYDelta == -1 then
            rotations = 0;
        elseif nextBitYDelta == 1 then
            rotations = 2;
        elseif nextBitXDelta == -1 then
            rotations = 3;
        else
            rotations = 1;
        end
    elseif idx == #(movepath) then
        bitIdx = 4;
        lastBitXDelta = movepath[idx-1].x - movepath[idx].x;
        lastBitYDelta = movepath[idx-1].y - movepath[idx].y;
        if lastBitYDelta == -1 then
            rotations = 2;
        elseif lastBitYDelta == 1 then
            rotations = 0;
        elseif lastBitXDelta == -1 then
            rotations = 1;
        else
            rotations = 3;
        end
    else
        bitIdx = 5;
        nextBitXDelta = movepath[idx+1].x - movepath[idx].x;
        nextBitYDelta = movepath[idx+1].y - movepath[idx].y;
        lastBitXDelta = movepath[idx-1].x - movepath[idx].x;
        lastBitYDelta = movepath[idx-1].y - movepath[idx].y;
        --there's probably an elegant way to do this next mess but fuck me if i'm going to figure it out
        if lastBitXDelta == -1 then 
            if nextBitXDelta == 1 then
                bitIdx = 2;
                rotations = 1;
            elseif nextBitYDelta == 1 then
                bitIdx = 3;
                rotations = 1;
            else
                bitIdx = 3;
                rotations = 2;
            end
        elseif lastBitXDelta == 1 then
            if nextBitXDelta == -1 then
                bitIdx = 2;
                rotations = 1;
            elseif nextBitYDelta == 1 then
                bitIdx = 3;
                rotations = 0;
            else
                bitIdx = 3;
                rotations = 3;
            end
        elseif lastBitYDelta == 1 then
            if nextBitYDelta == -1 then
                bitIdx = 2;
                rotations = 0;
            elseif nextBitXDelta == 1 then
                bitIdx = 3;
                rotations = 0;
            else
                bitIdx = 3;
                rotations = 1;
            end
        elseif lastBitYDelta == -1 then
            if nextBitYDelta == 1 then
                bitIdx = 2;
                rotations = 0;
            elseif nextBitXDelta == 1 then
                bitIdx = 3;
                rotations = 3;
            else
                bitIdx = 3;
                rotations = 2;
            end
        end
    end
    local radians = rotations * (math.pi / 2); --clockwise for some reason???
    --DEBUG_TEXT = "rotations is " .. rotations;
    local xoff = 0;
    local yoff = 0;
    if(rotations == 1) then 
        xoff = game.tileSize; 
    end
    if(rotations == 2) then 
        yoff = game.tileSize;
        xoff = game.tileSize;
    end
    if(rotations == 3) then 
        yoff = game.tileSize;
    end

    love.graphics.draw(path.bits[bitIdx],(movepath[idx].x - 1)*game.tileSize+xoff,(movepath[idx].y - 1)*game.tileSize+yoff,radians);
end