movementTypes = {"FOOT","HORSE","MAGIC","FLYING"};
terrain = {
    {name="Grass",costToEnter = function(movtype) 
        return 1;
    end},
    {name="Forest",costToEnter = function(movtype) 
        if (movtype == "FLYING") then return 1; end
        return 2;
    end},
    {name="Hills",costToEnter = function(movtype) 
        if (movtype == "FLYING") then return 1; end
        return 3;
    end},
    {name="Sand",costToEnter = function(movtype) 
        if (movtype == "FLYING") then return 1; end
        if (movtype == "MAGIC") then return 1; end
        if (movtype == "FOOT") then return 2; end
        return 3;
    end},
    {name="Wall",costToEnter = function(movtype) 
        if (movtype == "FLYING") then return 1; end
        return 999; --no way jose
    end},
    {name="HighWall",costToEnter = function(movtype) 
        return 999; --not even flying dudes
    end}
};
