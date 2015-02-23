module(..., package.seeall)
local widget = require "widget"

local actionSheet = {}
actionSheet.group = {}

function create(text)
    local group = display.newGroup()

    local underlay = display.newRect( group, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight )
    underlay:setFillColor(0.5, 0.5)
    underlay:addEventListener( "touch", function() return true end )

    local roundedrect = display.newRoundedRect( group, display.contentCenterX , display.contentCenterY - 10, 100, 80, 3 )
    roundedrect:setFillColor(0)

    local title = display.newEmbossedText( group, text, 0, 0, native.systemFont, 18 )
    title:setFillColor( 255 )
    title.x = display.contentCenterX
    title.y = display.contentCenterY - 35

    local spinner = widget.newSpinner{}
    spinner.x = display.contentCenterX
    spinner.y = display.contentCenterY
    spinner:start()
    group:insert(spinner)

    actionSheet.group = group
end

function destroy()
    actionSheet.group[4]:stop()
    display.remove(actionSheet.group)
    actionSheet.group = nil
end