--shader that treats 1,1,1 as fully white and 0,0,0 as unmodified.
flashShader = love.graphics.newShader[[
    vec4 effect( vec4 color, Image texture, vec2 texpoint, vec2 screenpoint){
			vec4 pixel = Texel(texture, texpoint);
            vec4 space = vec4(1-pixel.r,1-pixel.g,1-pixel.b,0.0);
            space.r *= color.r * pixel.a;
            space.g *= color.g * pixel.a;
            space.b *= color.b * pixel.a;
			pixel += space;
      pixel *= color.a;
      return pixel;
		}
]]
grayShader = love.graphics.newShader[[
  vec4 effect( vec4 color, Image texture, vec2 texpoint, vec2 screenpoint){
    vec4 pixel = Texel(texture, texpoint);
    number hue = (pixel.r + pixel.g + pixel.b) / 3.0;
    return vec4(hue,hue,hue,pixel.a);
  }
]]