display.setStatusBar( display.DefaultStatusBar )

local storyboard = require "storyboard"
local home = require "home"

--Globals
storyboard.statusBarHeight = display.topStatusBarContentHeight
storyboard.screen = {
    left = display.screenOriginX,
    top = storyboard.statusBarHeight,
    right = display.contentWidth - display.screenOriginX,
    bottom = display.contentHeight - display.screenOriginY,
    width = display.contentWidth,
    height = display.contentHeight,
}
storyboard.isSim = "simulator" == system.getInfo( "environment" )

local ph = display.pixelHeight
local textsize = 0
if ph >= 1280 then textsize = 18
elseif ph >= 960 then textsize = 14
elseif ph >= 800 then textsize = 12
else textsize = 8
end
storyboard.textsize = textsize

home.new()