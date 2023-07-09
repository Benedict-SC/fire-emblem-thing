screenwidth,screenheight=love.window.getDesktopDimensions();
gamewidth=600;
gameheight=400;
gameFPS = 60;
windowwidth=gamewidth;
windowheight=gameheight;
iconimg = love.graphics.newImage("assets/img/evilbook.png");
love.window.setTitle("Fire Emblem Thrall");
local iconCanvas = love.graphics.newCanvas(305,305);
love.graphics.setCanvas(iconCanvas);
love.graphics.draw(iconimg,0,0);
love.graphics.setCanvas();
love.window.setIcon(iconCanvas:newImageData());
love.window.setMode(gamewidth,gameheight,{
	fullscreen=false;
	resizable=true;
	minwidth=300;
	minheight=200;
	x=screenwidth/2 - (gamewidth/2) -400;
	y=screenheight/2 - (gameheight/2);
	
});

DEBUG_TEXT = "debug output";
DEBUG_FONT = love.graphics.getFont();

require("thirdparty.json4lua");
require("thirdparty.tablecopy");
require("utilities.util");
require("utilities.shaders");
require("utilities.async");
require("utilities.input");
require("utilities.path");
require("utilities.canvas");
require("utilities.animation");
require("weapons");
require("items");
require("map");
require("unitclass")
require("templateunit");
require("activeunit");
require("menubox");
require("textbox");
require("convo");
require("battle");
require("battle-ui.battlecam");
require("battle-ui.actionmenu");
require("battle-ui.blankmenu");
require("battle-ui.statspage");
require("battle-ui.fightscreen");
require("game");
game = Game();
game.init();
function love.draw()
    --first: framerate limit
	local start = love.timer.getTime();
	love.graphics.setColor(1,1,1);
    input.update();
	async.update();
    game.update();
    game.render();
	love.graphics.setFont(DEBUG_FONT);
	love.graphics.setColor(0,0,0);
	love.graphics.print(DEBUG_TEXT,3,3);
	love.graphics.setColor(1,1,1);
	love.graphics.print(DEBUG_TEXT,2,2);
	--love.graphics.print(controlMode,2,16);
    
	--finish framerate limiting
	local frametime = love.timer.getTime() - start;
	love.timer.sleep((1/gameFPS)-frametime)
end
function love.conf(t)
	t.console = true;
end