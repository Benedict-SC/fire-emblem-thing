table.shallowcopy = function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

table.sortedCopy = function(orig,func)
	local newtable = table.shallowcopy(orig);
	table.sort(newtable,func);
	return newtable;
end