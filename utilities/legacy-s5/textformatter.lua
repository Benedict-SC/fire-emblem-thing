--parse formatted text (<c=hex>, <f=implicitly-tff>, <s=pixels>, <i> and <b> tags) into a series of strings with associated formatting data
--using that string collection, draw formatted text into a rectangle
DEFAULT_TEXT_SIZE = 12;
DEFAULT_FONT_NAME = "arial";
TextFormatter = {};
TextDrawer = function (rect,fstrings,chars)
	local td = {};
	td.rect = rect;
	td.fstrings = fstrings and fstrings or nil;
	td.charsDrawn = chars and chars or 0;
	td.textSizeOverride = nil;

	td.setLocation = function(x,y)
		td.rect.x = x;
		td.rect.y = y;
	end

	td.draw = function()
		local fullchars = math.floor(td.charsDrawn);
		--local canv = love.graphics.newCanvas(rect.w,rect.h);
		--love.graphics.pushCanvas(canv);
		if DEBUG_TEXTRECT then
			love.graphics.setColor(1,1,1);
			love.graphics.rectangle("line",rect.x,rect.y,rect.w,rect.h);
		end
		--first count how many fstrings can be drawn in their entirety
		local charsleft = fullchars;
		local fulldraws = 0;
		for i = 1,#td.fstrings,1 do
			local text = td.fstrings[i].text;
			if charsleft >= #text then
				fulldraws = fulldraws + 1;
				charsleft = charsleft - #text;
			else
				break;
			end
		end
		--draw the full strings
		local lastX = 0; --track where our last string ended
		local lastY = 0;
		for i=1,fulldraws+1,1 do
			local isCut = false;
			if i == fulldraws+1 then
				--draw the incomplete string, if applicable
				if fulldraws < #td.fstrings and charsleft > 0 then
					isCut = true;
					--error("[" .. td.fstrings[i].text:sub(1,charsleft) .. "]");
				else
					--error("chars left is " .. charsleft)
					break;
				end
			end
			local fstring = td.fstrings[i];
			local ftext = isCut and fstring.text:sub(1,charsleft) or fstring.text;
			local uncutWords = splitSpaces(fstring.text,true);
			local uncutText = table.concat(subArray(uncutWords,1,countWords(ftext))," ");
			local size = fstring.props.size and fstring.props.size or (td.textSizeOverride and td.textSizeOverride or DEFAULT_TEXT_SIZE);
			--if td.textSizeOverride then
			--	debug_console_string = "" .. td.textSizeOverride .. "/" .. size;
			--end
            local fontname = DEFAULT_FONT_NAME;
			if fstring.props.font then --actually get font from formatting data
                fontname = fstring.props.font;
			end
			if fstring.props.bold then
				fontname = fontname .. "-b";
			end
			if fstring.props.italic then
				fontname = fontname .. "-i";
			end
			local font = Fonts.getFont(fontname,size);
            love.graphics.setFont(font);

			if not fstring.props.color then
				love.graphics.setColor(1,1,1);
			else
				love.graphics.setColor(fstring.props.color.red,fstring.props.color.green,fstring.props.color.blue,fstring.props.color.alpha);
			end
			love.graphics.setShader(textColorShader);

			local width = font:getWidth(ftext);
			local height = font:getHeight(ftext);
			local uncutWidth = font:getWidth(uncutText);
			local uncutHeight = font:getHeight(uncutText);

			if uncutWidth + lastX <= td.rect.w then
				love.graphics.print(ftext,rect.x+lastX,rect.y+lastY);
				lastX = lastX + width;
			else
				--local midcount = 0;
				while uncutWidth + lastX > td.rect.w do
					--if midcount > 1000 then error ("trying to write [" .. ftext .. "] full [" .. uncutText .. "], width/uncutWidth+lastX is " .. width .. "/" .. uncutWidth .. "+" ..lastX .. ", rect is " .. td.rect.w); end
					--midcount = midcount + 1;
					local words = splitSpaces(ftext,true);
					local uncutWords = splitSpaces(uncutText,true);
					--each step, join some number of things into a string and measure that
					local j = #words - 1;
					local drew = false;
					while j > 0 do
						local trytext = table.concat(subArray(words,1,j)," ");
						local fulltrytext = table.concat(subArray(uncutWords,1,j)," ");
						--if #words == 13 and j == 2 then error("lastx is " .. lastX) end
						width = font:getWidth(trytext);
						uncutWidth = font:getWidth(fulltrytext);
						if uncutWidth + lastX <= td.rect.w then --this string fits, so let's draw it and send the rest back through
							if lastX == 0 then
								trytext = trimLeadingSpaces(trytext);
								fulltrytext = trimLeadingSpaces(fulltrytext);
							end
							love.graphics.print(trytext,rect.x+lastX,rect.y+lastY);
							drew = true;
							lastY = lastY + height;
							lastX = 0;
							ftext = table.concat(subArray(words,j+1,#words-j)," ");
							uncutText = table.concat(subArray(uncutWords,j+1,#words-j)," ");
							width = font:getWidth(ftext);
							uncutWidth = font:getWidth(uncutText);
							break;
						end
						j = j-1;
					end
					if not drew then
						width = font:getWidth(ftext);
						uncutWidth = font:getWidth(uncutText);
						if lastX == 0 then
							local oneword = words[1];
							if not oneword then oneword = ""; end
							love.graphics.print(oneword,rect.x+lastX,rect.y+lastY);
							ftext = table.concat(subArray(words,2,#words-1)," ");
							uncutText = table.concat(subArray(uncutWords,2,#words-1)," ");
							--lastY = lastY+height;
							--love.graphics.print(ftext,rect.x+lastX,rect.y+lastY);
						end
						lastY = lastY+height;
						lastX = 0;
					end
				end
				if ftext:sub(1,1) == " " then --strip leading spaces on a new line
					ftext = ftext:sub(2);
				end
				love.graphics.print(ftext,rect.x+lastX,rect.y+lastY);
				width = font:getWidth(ftext);
				lastX = lastX + width;
			end
		end


		love.graphics.setColor(1,1,1);
		love.graphics.setShader();
		--love.graphics.popCanvas();
		--return canv;
	end
	return td;
end

TextFormatter.formattedStringLength = function(fstrings)
	local charcount = 0;
	for i=1,#fstrings,1 do
		charcount = charcount + #(fstrings[i].text);
	end
	return charcount;
end
TextFormatter.formattedStringWidth = function(fstrings)
	local oldFont = love.graphics.getFont();
	local width = 0;
	for i=1,#fstrings,1 do
		local fstring = fstrings[i];
		local ftext = fstring.text;
		local size = fstring.props.size and fstring.props.size or DEFAULT_TEXT_SIZE;
		local fontname = DEFAULT_FONT_NAME;
			if fstring.props.font then --actually get font from formatting data
                fontname = fstring.props.font;
				if fstring.props.bold then
                    fontname = fontname .. "b";
                end
                if fstring.props.italic then
                    fontname = fontname .. "i";
                end
			end
		local font = Fonts.getFont(fontname,size);
        love.graphics.setFont(font);
		
		local fragWidth = font:getWidth(ftext);
		width = width + fragWidth;
	end
	love.graphics.setFont(oldFont);
	return width;
end

TextFormatter.getFormattedStrings = function(ftext)
	local state = "CONTENT";
	local tokenlist = Array();

	local contentString = "";
	local tagString = "";
	for i=1,#ftext,1 do
		local char = ftext:sub(i,i);
		if char == "<" then
			state = "TAG";
			tokenlist.push({tag=false,str=contentString});
			tagString = "";
		elseif char == ">" then
			state = "CONTENT";
			tokenlist.push({tag=true,str=tagString,terminate=(tagString:sub(1,1) == "/")});
			contentString = "";
		else
			if state == "TAG" then
				tagString = tagString .. char;
			else
				contentString = contentString .. char;
				if i == #ftext then
					tokenlist.push({tag=false,str=contentString});
				end
			end
		end
	end
	--we now have a list of tokens
	local tagstack = Array();
	local fstringlist = Array();
	for i=1,#tokenlist,1 do
		local token = tokenlist[i];
		if token.tag then
			if token.terminate then
				tagstack.pop();
			else
				if not token.str then error("tag has no string"); end
				tagstack.push(token.str);
			end
		else
			--create the string with the tag data
			local tagsCopy = table.shallowcopy(tagstack);
			--strip undrawable special characters
			token.str = token.str:gsub("…","...");
			token.str = token.str:gsub("’","'");
			token.str = token.str:gsub("‘","'");
			token.str = input.replaceButtonPrompts(token.str);
			local fstring = TextFormatter.createFstring(tagsCopy,token.str);
			if #(fstring.text) > 0 then
				fstringlist.push(fstring);
			end
		end
	end
	return fstringlist;
end
TextFormatter.createFstring = function(tstack,str)
	local props = {
		size = nil;
		font = nil;
		color = nil;
		bold = false;
		italic = false;
	}
	while #tstack > 0 do
		local tagstring = table.remove(tstack,#tstack);
		local kind = tagstring:sub(1,1);
		if kind == "c" then
			if not props.color then
				props.color = {red=0,green=0,blue=0,alpha=1}
				local hexstring = tagstring:sub(4);
				if #hexstring < 6 then error("bad hex code") end;
				props.color.red = tonumber(hexstring:sub(1,2),16)/255;
				props.color.green = tonumber(hexstring:sub(3,4),16)/255;
				props.color.blue = tonumber(hexstring:sub(5,6),16)/255;
				if #hexstring == 8 then
					props.color.alpha = tonumber(hexstring:sub(7,8),16)/255;
				end
			end
		elseif kind == "f" then
			if not props.font then
				props.font = tagstring:sub(3);
			end
		elseif kind == "s" then
			if not props.size then
				props.size = tonumber(tagstring:sub(3),10);
			end
		elseif kind == "b" then
			props.bold = true;
		elseif kind == "i" then
			props.italic = true;
		else
			error("bad tag");
		end
	end
	return {text=str,props=props};
end
