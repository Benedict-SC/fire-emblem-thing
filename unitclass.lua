UnitClass = function(name,types,tier,mounted,horse,flying,armor,magic,promoted)
    local class = {};
    class.name = name or "Default";
    class.tier = tier or 1;
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
    Soldier=UnitClass("Soldier",{"LANCE"},1,false,false,false,false,false,false),
    Mercenary=UnitClass("Mercenary",{"SWORD"},1,false,false,false,false,false,false),
    Myrmidon=UnitClass("Myrmidon",{"SWORD"},1,false,false,false,false,false,false),
    Knight=UnitClass("Knight",{"LANCE"},1,false,false,false,true,false,false),
    Cavalier=UnitClass("Cavalier",{"SWORD","LANCE"},1,true,true,false,false,false,false),
    Fighter=UnitClass("Fighter",{"AXE"},1,false,false,false,false,false,false),
    Brigand=UnitClass("Brigand",{"AXE"},1,false,false,false,false,false,false),
    Archer=UnitClass("Archer",{"BOW"},1,false,false,false,false,false,false),
    Mage=UnitClass("Mage",{"ANIMA"},1,false,false,false,false,true,false),
    Cleric=UnitClass("Cleric",{"STAFF"},1,false,false,false,false,true,false),
    PegKnight=UnitClass("Pegasus Knight",{"LANCE"},1,true,false,true,false,false,false),
    WyvernRider=UnitClass("Wyvern Rider",{"LANCE"},1,true,false,true,false,false,false),
    Shaman=UnitClass("Shaman",{"DARK"},1,false,false,false,false,true,false),
    Monk=UnitClass("Monk",{"LIGHT"},1,false,false,false,false,true,false),
    Lord=UnitClass("Lord",{"SWORD"},1,false,false,false,false,false,false)
};