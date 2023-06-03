TemplateUnit = function(unitdata)
    local unit = {};
    unit.mapSpriteFile = unitdata.mapSpriteFile or "assets/img/defaultsoldier.png";
    unit.portraitFile = unitdata.portraitFile or "assets/img/defaultportrait.png";
    unit.class = UnitClass();
    unit.name = unitdata.name or "Enemy";
    unit.maxhp = unitdata.maxhp or 1;
    unit.str = unitdata.str or 0;
    unit.skl = unitdata.skl or 0;
    unit.luk = unitdata.luk or 0;
    unit.spd = unitdata.spd or 0;
    unit.def = unitdata.def or 0;
    unit.res = unitdata.res or 0;
    unit.mov = unitdata.mov or 3;
    unit.con = unitdata.con or 10;
    return unit;
end