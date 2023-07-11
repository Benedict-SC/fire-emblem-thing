Fonts = {};
Fonts.archive = {};
Fonts.getFont = function(fontId,size) 
    local fontAttempt = Fonts.archive[fontId];
    if not fontAttempt then
        fontAttempt = {};
        Fonts.archive[fontId] = fontAttempt;
    end
    
    local specificFontAttempt = fontAttempt[size];
    if specificFontAttempt then
        return specificFontAttempt;
    else
        fontAttempt[size] = love.graphics.newFont("assets/font/" .. fontId .. ".ttf", size);
        return fontAttempt[size];
    end
end