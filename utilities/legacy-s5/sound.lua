sound = {};
sound.bank = {};

sound.muted = false;
sound.unmutedVolume = 1.0;
sound.mute = function()
    sound.muted = true;
	love.audio.setVolume(0);
end
sound.unmute = function()
    sound.muted = false;
	love.audio.setVolume(sound.unmutedVolume);
end
sound.adjustGlobalVolume = function(volPercent)
    sound.unmutedVolume = volPercent;
    love.audio.setVolume(volPercent);
end
sound.downGlobalVolume = function()
    local doubled = round((sound.unmutedVolume*2) - 0.1,2);
    sound.unmutedVolume = doubled/2;
    if sound.unmutedVolume < 0 then 
        sound.unmutedVolume = 0; 
    end
    if not (sound.muted) then
        love.audio.setVolume(sound.unmutedVolume);
    end
end
sound.upGlobalVolume = function()
    local doubled = round((sound.unmutedVolume*2) + 0.1,2);
    sound.unmutedVolume = doubled/2;
    if sound.unmutedVolume > 1 then 
        sound.unmutedVolume = 1;
    end
    if not (sound.muted) then
        love.audio.setVolume(sound.unmutedVolume);
    end
end

sound.play = function(sID) --use only for non-music audio clips
    if not sID then
		return;
    end
    local clip = sound.bank[sID];
	if clip then
        clip.clip:stop();
        clip.clip:play();
	end
end
sound.stop = function(sID)
    if not sID then
		return;
    end
    local clip = sound.bank[sID];
	if clip then
        clip.clip:stop();
	end
end
sound.fade = function(sID,secs) --just for the fire alarm, i think
    if sID then
        local clip = sound.bank[sID];
        clip.setHandle(async.doOverTime(secs,function(percent)
            clip.setVolume(1-percent);
        end,function()
            clip.clip:stop();
        end));
    end
end

sound.bgmList = Array();
sound.bgmName = "none";
async.doEveryXSecsForever(function() --clear out stopped BGMs in the list
    for i=#(sound.bgmList),1,-1 do --for all bgm currently playing
        if not (sound.bgmList[i].clip:isPlaying()) then
            sound.bgmList[i].setHandle(); --cancel whatever it's doing, though it shouldn't be doing anything if stopped
            table.remove(sound.bgmList,i);
        end
    end
end,3);
sound.playBGM = function(sID) --sharp
    for i=#(sound.bgmList),1,-1 do --for all bgm currently playing
        sound.bgmList[i].setHandle(); --cancel whatever it's doing
        sound.bgmList[i].clip:stop();
        table.remove(sound.bgmList,i);
    end
    if sID then
        local bgm = sound.bank[sID];
        bgm.setVolume(1);
        bgm.clip:stop();
        bgm.clip:play();
        sound.bgmName = sID;
        sound.bgmList.setAdd(bgm);
    else
        sound.bgmName = "none";
    end
end
sound.FADETIME = 1;
sound.fadeInBGM = function(sID,whenDone) --if nil is passed, fade out bgm
    --fade out olds
    --debug_console_string = "fading in " .. sID; 
    --debug_console_string_2 = "";
    for i=#(sound.bgmList),1,-1 do --for all bgm currently playing
        local oldBgm = sound.bgmList[i];
        if oldBgm.name ~= sID then --if it's not the one we're fading in
            local timeToFade = sound.FADETIME * oldBgm.normalVolume;
            --debug_console_string_2 = debug_console_string_2 .. "\ntimetofade for " .. oldBgm.name .. " is  " .. timeToFade;
            if timeToFade > sound.FADETIME then --shouldn't ever go above max volume
                timeToFade = sound.FADETIME;
            end
            local originalVolume = oldBgm.normalVolume; --volume when the fade started
            --debug_console_string_3 = oldBgm.name .. " is about to get an async handle";
            oldBgm.setHandle(async.doOverTime(timeToFade,function(percent) --set it to fade out
                --debug_console_string_3 = oldBgm.name .. " volume is " .. oldBgm.normalVolume;
                oldBgm.setVolume((1-percent) * originalVolume);
            end,function() --when done, stop and flag self to be removed from list
                oldBgm.clip:stop();            
            end));
        end
    end
    --fade in new
    if sID then
        local bgm = sound.bank[sID];
        if sound.bgmList.contains(bgm) then --if it's already playing, and fading out or something, then
            local growTime = sound.FADETIME * (1-bgm.normalVolume);
            local originalVolume = bgm.normalVolume;
            bgm.clip:play();
            bgm.setHandle(async.doOverTime(growTime,function(percent)
                bgm.setVolume(originalVolume + (1-originalVolume)*percent);
            end,function()
                bgm.setVolume(1);
                if whenDone then
                    whenDone();
                end
            end));
        else --it's not playing at all, so start it fresh
            bgm.setVolume(0);
            bgm.clip:stop();
            bgm.clip:play();
            bgm.setHandle(async.doOverTime(sound.FADETIME,function(percent)
                bgm.setVolume(percent);
            end,function()
                bgm.setVolume(1);
                if whenDone then
                    whenDone();
                end
            end));
        end
        sound.bgmList.setAdd(bgm);
        sound.bgmName = sID;
    else
        sound.bgmName = "none";
        async.wait(sound.FADETIME,function()
            if whenDone then
                whenDone();
            end
        end);
    end
end
sound.crossfadeBGM = function(sID,oldID,whenDone)
    if oldID and sID then
        local oldBgm = sound.bank[oldID];
        local bgm = sound.bank[sID]; 
        sound.fadeInBGM(sID,whenDone);
        local position = oldBgm.clip:tell();
        bgm.clip:seek(position);
    end
end
sound.stopBGM = function(sID)
    for i=#(sound.bgmList),1,-1 do --for all bgm currently playing
        sound.bgmList[i].setHandle(); --cancel whatever it's doing
        sound.bgmList[i].clip:stop();
        table.remove(sound.bgmList,i);
    end
    sound.bgmName = "none";
end

sound.createWrappedClip = function(name,filename,volumeMult,looping,sourcetype)
    if not volumeMult then
        volumeMult = 1;
    end
    --error(filename);
    local wrapper = {};
    wrapper.name = name;
    wrapper.mult = volumeMult; --never 0;
    wrapper.normalVolume = 1;
    wrapper.loops = looping;
    wrapper.clip = love.audio.newSource(filename,sourcetype);
    wrapper.clip:setLooping(looping);
    wrapper.clip:setVolume(volumeMult);
    wrapper.setVolume = function(vol)
        wrapper.clip:setVolume(vol * volumeMult);
        wrapper.normalVolume = vol;
    end
    wrapper.setHandle = function(handle)
        if wrapper.handle then
            wrapper.handle.cancel = true;
            debug_console_string_3 = wrapper.name .. " got cancelled";
        end
        wrapper.handle = handle;
    end
    return wrapper;
end
sound.makeAndBank = function(name,filename,volumeMult,looping,sourcetype)
    sound.bank[name] = sound.createWrappedClip(name,filename,volumeMult,looping,sourcetype);
end
sound.makeAndBeep = function(name,filename,volumeMult,looping)
    sound.beeps[name] = sound.createWrappedClip(name,filename,volumeMult,looping,"static");
end
sound.beeps = {};

sound.makeAndBank("playerphase","assets/audio/playerphase.ogg",1,false,"static");
sound.makeAndBank("enemyphase","assets/audio/enemyphase.ogg",1,false,"static");
sound.makeAndBank("otherphase","assets/audio/otherphase.ogg",1,false,"static");
sound.makeAndBank("ding","assets/audio/ding.ogg",1,false,"static");

sound.beep = function(sID)
    if not sID then
		return;
    end
    local clip = sound.beeps[sID];
	if clip then
        clip.clip:stop();
        clip.clip:play();
	end
end
sound.debeep = function(sID) 
    if not sID then
		return;
    end
    local clip = sound.beeps[sID];
	if clip then
        clip.clip:stop();
	end
end

if not (sound.bank["playerphase"]) then error("failed to load bgm"); end