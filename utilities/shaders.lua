--shader that treats 1,1,1 as fully white and 0,0,0 as unmodified.
flashShader = love.graphics.newShader[[
        vec4 effect( vec4 color, Image texture, vec2 texpoint, vec2 screenpoint){
			vec4 pixel = Texel(texture, texpoint);
            vec4 space = vec4(1-pixel.r,1-pixel.g,1-pixel.b,0.0);
            space.r *= color.r;
            space.g *= color.g;
            space.b *= color.b;
			return pixel + space;
		}
    ]]
