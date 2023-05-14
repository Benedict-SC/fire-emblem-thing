UnitClass = function(name,types,mounted,horse,flying,armor,magic,promoted)
    local class = {};
    class.name = name or "Default";
    class.weaponTypes = types or {"LANCE","BOW","SWORD","AXE","ANIMA","DARK","LIGHT","STAFF"};
    class.mounted = mounted or false;
    class.magic = magic or false;
    class.horse = horse or false;
    class.flying = flying or false;
    class.armor = armor or false;
    class.promoted = promoted or false;
    class.movementType = function()
        if class.flying then
            return movementTypes[4];
        end
        if class.horse then
            return movementTypes[2];
        end
        if class.magic then
            return movementTypes[3];
        end
        return movementTypes[1];
    end
    return class;
end
classLibrary = {
    Soldier=UnitClass("Soldier",{"LANCE"},false,false,false,false,false,false),
    Mercenary=UnitClass("Mercenary",{"SWORD"},false,false,false,false,false,false),
    Myrmidon=UnitClass("Myrmidon",{"SWORD"},false,false,false,false,false,false),
    Knight=UnitClass("Knight",{"LANCE"},false,false,false,true,false,false),
    Cavalier=UnitClass("Cavalier",{"SWORD","LANCE"},true,true,false,false,false,false),
    Fighter=UnitClass("Fighter",{"AXE"},false,false,false,false,false,false),
    Brigand=UnitClass("Brigand",{"AXE"},false,false,false,false,false,false),
    Archer=UnitClass("Archer",{"BOW"},false,false,false,false,false,false),
    Mage=UnitClass("Mage",{"ANIMA"},false,false,false,false,true,false),
    Cleric=UnitClass("Cleric",{"STAFF"},false,false,false,false,true,false),
    PegKnight=UnitClass("Pegasus Knight",{"LANCE"},true,false,true,false,false,false),
    WyvernRider=UnitClass("Wyvern Rider",{"LANCE"},true,false,true,false,false,false),
    Shaman=UnitClass("Shaman",{"DARK"},false,false,false,false,true,false),
    Monk=UnitClass("Monk",{"LIGHT"},false,false,false,false,true,false),
    Lord=UnitClass("Lord",{"SWORD"},false,false,false,false,false,false)
};