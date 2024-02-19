TemplateUnit = function(tdata)
    local unit = {};
    unit.mapSpriteFile = tdata.mapSpriteFile or "assets/img/defaultsoldier.png";
    unit.portraitFile = tdata.portraitFile or "assets/img/defaultportrait.png";
    unit.class = UnitClass();
    unit.name = tdata.name or "Enemy";
    unit.maxhpBase = tdata.maxhp or 1;
    unit.strBase = tdata.str or 0;
    unit.sklBase = tdata.skl or 0;
    unit.lukBase = tdata.luk or 0;
    unit.spdBase = tdata.spd or 0;
    unit.defBase = tdata.def or 0;
    unit.resBase = tdata.res or 0;
    unit.maxhpGrowth = tdata.mhpg or 50;
    unit.strGrowth = tdata.strg or 30;
    unit.sklGrowth = tdata.sklg or 40;
    unit.lukGrowth = tdata.lukg or 20;
    unit.spdGrowth = tdata.spdg or 30;
    unit.defGrowth = tdata.defg or 30;
    unit.resGrowth = tdata.resg or 20;
    unit.mov = tdata.mov or 3;
    unit.con = tdata.con or 10;
    return unit;
end