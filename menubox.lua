MenuBox = function(blueprintImg,borderW,borderH) 
    local mb = {};
    mb.bw = borderW;
    mb.bh = borderH or borderW; --you can just pass one argument if the gutters are the same
    mb.source = blueprintImg;
        --initial draw logic
    local w = mb.source:getWidth();
    local h = mb.source:getHeight();
    --set the internal draw sizes
    mb.midW = w - (2*mb.bw);
    mb.midH = h - (2*mb.bh);
    mb.xoffs = {0,mb.bw,mb.bw+mb.midW};
    mb.yoffs = {0,mb.bh,mb.bh+mb.midH};
    --initialize the panels
    mb.panels = Array();
    mb.panels[1] = Array();
    mb.panels[2] = Array();
    mb.panels[3] = Array();
    --corners
    mb.panels[1][1] = love.graphics.newCanvas(mb.bw,mb.bh);
    mb.panels[1][3] = love.graphics.newCanvas(mb.bw,mb.bh);
    mb.panels[3][1] = love.graphics.newCanvas(mb.bw,mb.bh);
    mb.panels[3][3] = love.graphics.newCanvas(mb.bw,mb.bh);        
    --sides
    mb.panels[1][2] = love.graphics.newCanvas(mb.midW,mb.bh);
    mb.panels[2][1] = love.graphics.newCanvas(mb.bw,mb.midH);
    mb.panels[2][3] = love.graphics.newCanvas(mb.bw,mb.midH);
    mb.panels[3][2] = love.graphics.newCanvas(mb.midW,mb.bh);
    --center
    mb.panels[2][2] = love.graphics.newCanvas(mb.midW,mb.midH);
    --paint them in
    for i=1,#mb.panels,1 do
        for j=1,#mb.panels[i],1 do
            local panel = mb.panels[i][j];
            love.graphics.pushCanvas(panel);
            if not (panel.dynamicTransparency) then
                love.graphics.setBlendMode("alpha","premultiplied");
            end
            love.graphics.draw(mb.source,-mb.xoffs[j],-mb.yoffs[i]);
            love.graphics.setBlendMode("alpha","alphamultiply");
            love.graphics.popCanvas();
        end
    end

    mb.draw = function(x,y)
        for i=1,#mb.panels,1 do
            for j=1,#mb.panels[i],1 do
                local panel = mb.panels[i][j];
                local yscale = 1;
                if i == 2 then yscale = mb.adjustedMidH / mb.midH; end
                local xscale = 1;
                if j == 2 then xscale = mb.adjustedMidW / mb.midW; end
                love.graphics.draw(panel,mb.xoffs[j]+x,mb.yoffs[i]+y,0,xscale,yscale);
            end
        end
    end
    mb.adjustedMidW = mb.midW;
    mb.adjustedMidH = mb.midH;
    mb.resize = function (w,h)
        --can't resize smaller than the border size
        if w < (2*mb.bw + 1) then w = (2*mb.bw + 1); end
        if h < (2*mb.bh + 1) then h = (2*mb.bh + 1); end  
        --set draw offsets
        mb.xoffs = {0,mb.bw,w-mb.bw};
        mb.yoffs = {0,mb.bh,h-mb.bh};
        mb.adjustedMidW = mb.xoffs[3] - mb.xoffs[2];
        mb.adjustedMidH = mb.yoffs[3] - mb.yoffs[2];
    end
    return mb;
end