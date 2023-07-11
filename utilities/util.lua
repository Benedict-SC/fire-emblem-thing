Array = function(...)
	local arr = {};
	local argnum = select("#",...);
	if argnum > 0 then
		for i = 1, argnum do
			arr[i] = select(i,...);
		end
	end
	return arrayify(arr);
end
arrayify = function(bareArray)
	if bareArray == nil then
		return nil;
	end
    bareArray.size = #bareArray;
	bareArray.push = function(el)
		bareArray.size = bareArray.size + 1;
		bareArray[bareArray.size] = el;
	end
	bareArray.pop = function()
		local val = bareArray[bareArray.size];
		bareArray[bareArray.size] = nil;
		bareArray.size = bareArray.size - 1;

		return val;
	end
	bareArray.peek = function()
		return bareArray[bareArray.size];
	end
    bareArray.concatenate = function(otherArray)
        for i=1,#otherArray,1 do
            bareArray.push(otherArray[i]);
        end
        return bareArray;
    end
	bareArray.reverse = function()
		local backwards = Array();
		for i=#bareArray,1,-1 do
			backwards.push(bareArray[i]);
		end
		return backwards;
	end
	bareArray.indexOf = function(obj)
		local result = -1;
		for i=1,#bareArray do
			if obj == bareArray[i] then
				result = i;
				break;
			end
		end
		return result;
	end
	bareArray.has = function(obj)
		return bareArray.indexOf(obj) ~= -1;
	end
	bareArray.remove = function(idx)
		table.remove(bareArray,idx);
		bareArray.size = bareArray.size - 1;
	end
	bareArray.removeItem = function(obj)
		local idx = bareArray.indexOf(obj);
		if idx >= 1 then
			table.remove(bareArray,idx);
			bareArray.size = bareArray.size - 1;
		end
	end
	bareArray.filter = function(filterFunction)
		local out = Array();
		for i=1,bareArray.size,1 do
			if filterFunction(bareArray[i]) then out.push(bareArray[i]) end
		end
		return out;
	end
	bareArray.forEach = function(eachFunction)
		for i=1,bareArray.size,1 do
			eachFunction(bareArray[i]);
		end
	end
	bareArray.map = function(mapFunction)
		local out = Array();
		for i=1,bareArray.size,1 do
			out.push(mapFunction(bareArray[i]));
		end
		return out;
	end
	bareArray.sorted = function(comparator) 
		local out = Array();
		out = out.concatenate(bareArray);
		table.sort(out,comparator);
		return out;
	end
	bareArray.oneDimensionDown = function()
		local newArray = Array();
		for i=1,#bareArray,1 do
			for j=1,#(bareArray[1]),1 do
				newArray.push(bareArray[i][j]);
			end
		end
		return newArray;
	end
	return bareArray;
end
deepcopy = function(orig) --http://lua-users.org/wiki/CopyTable
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
signof = function(x)
	if x < 0 then
	  return -1;
	elseif x > 0 then
	  return 1;
	else
	  return 0;
	end
 end
 manhattan = function(obj1,obj2)
	return math.abs(obj1.x-obj2.x) + math.abs(obj1.y-obj2.y);
 end
 random099 = function()
	return math.floor(math.random() * 100);
 end
 --here's some legacy string processing from s5
 splitSpaces = function(str,preserveEnds)
	local tokens = Array();
	for token in string.gmatch(str, "%S+") do
		tokens.push(token);
	end
	if preserveEnds and tokens[1] then 
		if str:sub(1,1) == " " then
			tokens[1] = " " .. tokens[1];
		end
		if str:sub(#str,#str) == " " and #tokens > 0 then
			tokens[#tokens] = tokens[#tokens].." ";
		end
	end
	return tokens;
end
countWords = function(str)
	local num = 0;
	for token in string.gmatch(str, "%S+") do
		num = num + 1;
	end
	return num;
end
capitalize = function(str)
	if #str == 1 then 
		return str:upper();
	elseif #str == 0 then
		return str;
	else
		return str:sub(1,1):upper() .. str:sub(2); 
	end
end
trimSpaces = function(str)
	str = trimLeadingSpaces(str);
	while str:sub(#str,#str) == " " do
		str = str:sub(1,#str-1);
	end
	return str;
end
trim = function(str)
	-- from PiL2 20.4
	return str:gsub("^%s*(.-)%s*$", "%1");
end
trimLeadingSpaces = function(str)
	while str:sub(1,1) == " " do
		str = str:sub(2);
	end
	return str;
end
subArray = function(array,startIndex,length)
	startIndex = startIndex or 1;
	maxIndex = startIndex - 1 + length;
	local subarray = Array();
	if maxIndex > #array then maxIndex = #array; end
	for i=startIndex,maxIndex,1 do
		subarray.push(array[i]);
	end
	return subarray;
end