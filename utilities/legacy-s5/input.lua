input = {up=false,down=false,left=false,right=false,action=false,cancel=false,inspect=false,menu=false,leftTab=false,rightTab=false,mouse1=false,mouse2=false};
pressedThisFrame = {up=false,down=false,left=false,right=false,action=false,cancel=false,inspect=false,menu=false,leftTab=false,rightTab=false,mouse1=false,mouse2=false};
releasedThisFrame = {up=false,down=false,left=false,right=false,action=false,cancel=false,inspect=false,menu=false,leftTab=false,rightTab=false,mouse1=false,mouse2=false};
objectiveArrows = {up=false,down=false,left=false,right=false,c=false,x=false,space=false,enter=false};
objectiveArrowsPressed = {up=false,down=false,left=false,right=false,c=false,x=false,space=false,enter=false};

defaultKeyControls = {up={"up","w"},down={"down","s"},left={"left","a"},right={"right","d"},action={"space"},cancel={"x"},inspect={"tab"},menu={"return"},leftTab={"q"},rightTab={"e"},zoomIn={"=","kp+"},zoomOut={"-","kp-"}};
keyControls = {up={"up","w"},down={"down","s"},left={"left","a"},right={"right","d"},action={"space"},cancel={"x"},inspect={"tab"},menu={"return"},leftTab={"q"},rightTab={"e"},zoomIn={"=","kp+"},zoomOut={"-","kp-"}};
controllerControls = {up={"dpup"},down={"dpdown"},left={"dpleft"},right={"dpright"},action={"a"},cancel={"b"},inspect={"y"},menu={"start"},leftTab={"leftshoulder"},rightTab={"rightshoulder"},zoomIn={},zoomOut={}}
checkdowns = {"up","down","left","right","action","cancel","inspect","menu","leftTab","rightTab","zoomIn","zoomOut"};
controlMode = "KEYBOARD";
activeJoystick = love.joystick.getJoysticks()[1];
wheelThisFrame = 0;

inputTimestamps = {up=0,down=0,left=0,right=0,action=0,cancel=0,inspect=0,menu=0,leftTab=0,rightTab=0,mouse1=0,mouse2=0};
turboDelay = 0.0;--0.35; --seconds
turboInterval = 0.09; --seconds
turboCounts = {up=0,down=0,left=0,right=0,action=0,cancel=0,inspect=0,menu=0,leftTab=0,rightTab=0,mouse1=0,mouse2=0};
turbosProcessed = {up=0,down=0,left=0,right=0,action=0,cancel=0,inspect=0,menu=0,leftTab=0,rightTab=0,mouse1=0,mouse2=0};


input.replaceButtonPrompts = function(str)
	if controlMode == "KEYBOARD" then
		str = str:gsub("%%LBUTTON%%",input.capitalize(keyControls.leftTab[1]));
		str = str:gsub("%%ACTIONBUTTON%%",input.capitalize(keyControls.action[1]));
		str = str:gsub("%%CANCELBUTTON%%",input.capitalize(keyControls.cancel[1]));
		str = str:gsub("%%MENUBUTTON%%",input.capitalize(keyControls.menu[1]));
		str = str:gsub("%%RBUTTON%%",input.capitalize(keyControls.rightTab[1]));
	elseif controlMode == "CONTROLLER" then
		str = str:gsub("%%LBUTTON%%",input.capitalize(controllerControls.leftTab[1]));
		str = str:gsub("%%ACTIONBUTTON%%",input.capitalize(controllerControls.action[1]));
		str = str:gsub("%%CANCELBUTTON%%",input.capitalize(controllerControls.cancel[1]));
		str = str:gsub("%%MENUBUTTON%%",input.capitalize(controllerControls.menu[1]));
		str = str:gsub("%%RBUTTON%%",input.capitalize(controllerControls.rightTab[1]));
	end
	return str;
end
input.capitalize = function(str)
	if #str == 1 then 
		return str:upper(); 
	elseif (str == "leftshoulder") then
		return "L";
	elseif (str == "rightshoulder") then
		return "R";
	else
		return str; 
	end
end
input.joystickDeadzone = 0.25;
input.checkIfAnyAreDown = function(keytype)
	if controlMode == "KEYBOARD" then
		local keyarray = keyControls[keytype];
		local found = false;
		for i=1,#keyarray,1 do
			if love.keyboard.isDown(keyarray[i]) then
				found = true;
			end
		end
		return found;
	elseif controlMode == "CONTROLLER" then
		if not activeJoystick then 
			return false;
		end
		local buttonarray = controllerControls[keytype];
		local found = false;
		for i=1,#buttonarray,1 do
			if activeJoystick:isGamepadDown(buttonarray[i]) then
				found = true;
			end
		end
		--controller axis stuff
		if keytype == "down" then
			if activeJoystick:getGamepadAxis("lefty") > input.joystickDeadzone then
				found = true;
			end
		elseif keytype == "up" then
			if activeJoystick:getGamepadAxis("lefty") < -input.joystickDeadzone then
				found = true;
			end
		elseif keytype == "right" then
			if activeJoystick:getGamepadAxis("leftx") > input.joystickDeadzone then
				found = true;
			end
		elseif keytype == "left" then
			if activeJoystick:getGamepadAxis("leftx") < -input.joystickDeadzone then
				found = true;
			end
		elseif keytype == "leftTab" then
			if activeJoystick:getGamepadAxis("triggerleft") > 0.5 then
				found = true;
			end
		elseif keytype == "rightTab" then
			if activeJoystick:getGamepadAxis("triggerright") > 0.5 then
				found = true;
			end
		end
		return found;
	end
	return false;
end
input.getNormalizedJoystickVector = function()
	local x = activeJoystick:getGamepadAxis("leftx");
	local y = activeJoystick:getGamepadAxis("lefty");
	if math.abs(x) < input.joystickDeadzone then
		x = 0;
	else
		x = (x < 0) and -1 or 1;
	end
	if math.abs(y) < input.joystickDeadzone then
		y = 0;
	else
		y = (y < 0) and -1 or 1;
	end
	return {x=x,y=y};
end
input.getManhattanNormalizedJoystickVector = function(distance)
	local x = activeJoystick:getGamepadAxis("leftx");
	local y = activeJoystick:getGamepadAxis("lefty");
	local yProportion = math.abs(y) / (math.abs(x)+math.abs(y));
	ySpaces = math.floor(distance * yProportion + 0.5);
	xSpaces = distance - ySpaces;
	return {x=signof(x) * xSpaces,y=signof(y) * ySpaces};
end
input.update = function()
	pressedThisFrame = {up=false,down=false,left=false,right=false,action=false,cancel=false,menu=false,leftTab=false,rightTab=false,mouse1=false,mouse2=false,zoomIn=false,zoomOut=false};
	releasedThisFrame = {up=false,down=false,left=false,right=false,action=false,cancel=false,menu=false,leftTab=false,rightTab=false,mouse1=false,mouse2=false,zoomIn=false,zoomOut=false};
	objectiveArrowsPressed = {up=false,down=false,left=false,right=false,c=false,x=false,space=false,enter=false};
    
    for i=1,#checkdowns,1 do
        local button = checkdowns[i];
        if input.checkIfAnyAreDown(button) then
            if not input[button] then --this is the initial frame of pressing this button
                pressedThisFrame[button] = true;
				inputTimestamps[button] = love.timer.getTime();
                input[button] = true;
			else --we're holding it down
				local ttime = love.timer.getTime() - inputTimestamps[button];
				ttime = ttime - turboDelay;
				turboCounts[button] = math.floor(ttime / turboInterval);
            end
        else
            if input[button] then
                releasedThisFrame[button] = true;
				turboCounts[button] = 0;
				turbosProcessed[button] = 0;
                input[button] = false;
            end
        end
    end
    if love.mouse.isDown(1) then --mouse1
        if not input.mouse1 then
            input.mouse1 = true;
            pressedThisFrame.mouse1 = true;
			inputTimestamps.mouse1 = love.timer.getTime();
        end
    else
        if input.mouse1 then
            input.mouse1 = false;
            releasedThisFrame.mouse1 = true;
        end
    end
    if love.mouse.isDown(2) then --mouse2
        if not input.mouse2 then
            input.mouse2 = true;
            pressedThisFrame.mouse2 = true;
			inputTimestamps.mouse2 = love.timer.getTime();
        end
    else
        if input.mouse2 then
            input.mouse2 = false;
            releasedThisFrame.mouse2 = true;
        end
    end
	if wheelThisFrame ~= 0 then
		if wheelThisFrame > 0 then
			pressedThisFrame.zoomIn = true;
		else
			pressedThisFrame.zoomOut = true;	
		end
	end
	wheelThisFrame = 0;
end
love.textinput = function(text)
	if game.pronounsMode then
		if game.pronounsScreen.mode == "TEXT" then
			game.pronounsScreen.acceptInput(text);
		end
	end
end
love.keypressed = function(key)
	controlMode = "KEYBOARD";
	local joysticks = love.joystick.getJoysticks()
	for i, joystick in ipairs(joysticks) do
		local gp = "false";
		if joystick:isGamepad() then
			gp = "true";
		end
        --debug_console_string_2 = debug_console_string_2 .. joystick:getName() .. " is gamepad: " .. gp .. "\n";
    end
end
love.gamepadpressed = function(joystick,button)
	if controlMode ~= "CONTROLLER" then
		controlMode = "CONTROLLER";
		activeJoystick = love.joystick.getJoysticks()[1];
	end
	debug_console_string_3 = "controller: " .. button;
end
love.joystickpressed = function(joystick,button)
	if controlMode ~= "CONTROLLER" then
		controlMode = "CONTROLLER";
		activeJoystick = love.joystick.getJoysticks()[1];
	end
	debug_console_string_3 = "controller: " .. button;
end
love.joystickaxis = function(joystick,axis,value)
	if controlMode ~= "CONTROLLER" then
		controlMode = "CONTROLLER";
		activeJoystick = love.joystick.getJoysticks()[1];
	end
end
love.joystickadded = function(joystick)
	--detect if it's a PS4 controller, then set PS4 keybindings
end
love.mousemoved = function(x,y,dx,dy)
    controlMode = "MOUSE";
end
love.mousepressed = function(x,y,dx,dy)
    controlMode = "MOUSE";
end
love.mousemoved = function(x,y,button,istouch,presses)
    controlMode = "MOUSE";
end
love.wheelmoved = function(x,y)
	wheelThisFrame = y;
end