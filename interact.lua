Interaction = function(id)
    local int = {}; --oh this variable name won't be confusing i bet. don't worry lua doesn't have ints
    int.id = id;
    int.name = "ACTION_NAME"
    int.execute = function() end;
    int.displays = false;

    int.addMenuOption = function(actionmenu)
        local intOption = {name=int.name};
        intOption.onPick = int.execute;
        actionmenu.options.insert(1,itemOption);
    end

    return int;
end