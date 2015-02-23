 module(..., package.seeall)

local widget = require( "widget" )
local storyboard = require( "storyboard" )
local json = require ( "json" ) 
local mime = require( "mime" )
local loadingSheet = require( "loading" )
local encode = require( "encode" )
local MultipartFormData = require("class_MultipartFormData")

local picture = ""
local spinner
local camera, plus, info

local function removeSpinner()
    spinner:stop()
    display.remove(spinner)
    spinner = nil
end

local function loadURL(url)
    local group = display.newGroup()

    local bg = display.newImageRect(group, "assets/blue_bg.png", storyboard.screen.width, 64 - storyboard.screen.top)
    bg.x = storyboard.screen.width/2
    bg.y = (64 - storyboard.screen.top) / 2

    local line = display.newRect(group, display.contentCenterX, (65-storyboard.screen.top), storyboard.screen.width, 3 )
    line.fill = {0}

    local webView = native.newWebView( display.contentCenterX, (480 - bg.y)/2 + 48, 320, 480 - bg.y )
    webView:request( url )

    local done_button = widget.newButton({
        width = 160,
        height = 40,
        label = "Done",
        labelColor = { default = { 255 }, over = { 200 } },
        labelYOffset = -4, 
        font = native.systemFont,
        fontSize = 18,
        emboss = false,
        onRelease = function()
            webView:removeSelf()
            display.remove(group)
            group = nil
        end
    })
    group:insert(done_button)
    done_button.x = 30
    done_button.y = storyboard.screen.top + 20
end

local function loadVideo(filename)
    local group = display.newGroup()

    local video = native.newVideo( display.contentCenterX, display.contentCenterY, storyboard.screen.width, storyboard.screen.height )

    local function videoListener( event )
        --print( "Event phase: " .. event.phase )

        if event.phase == "ended" then
            -- stop the video and remove
            video:pause()
            video:removeSelf()
            video = nil

            display.remove( group )
            group = nil
            --display.setDrawMode( "forceRender" )
        end

        if event.errorCode then
            native.showAlert( "Error!", event.errorMessage, { "OK" } )
        end
    end

    video:load(filename, system.TemporaryDirectory)
    video:addEventListener( "video", videoListener )
    video:play()
end

local function downloadVideo(url)
    local filename = tostring(os.time()) .. ".mp4"

    local function download(event)
        if event.isError then
            native.showAlert( "Network Error", "Download failed, please check your network connection", { "OK" } )
        else
            --print( "Downloaded successfully" )
            --loadingSheet.destroy()
            removeSpinner()
            loadVideo(filename)
        end
    end

    network.download(url, "GET", download, filename, system.TemporaryDirectory)
end

-- Send picture
-- Compare phash's
-- Get most likely match
-- Get url, type
-- If url, show
-- If movie, download, show
local function sendFile()
    --display.setDrawMode( "forceRender" )
    local multipart = MultipartFormData.new()
    multipart:addFile("picture", system.pathForFile(picture, system.TemporaryDirectory), "image/png", picture)

    local params = {}
    params.body = multipart:getBody() -- Must call getBody() first!
    params.headers = multipart:getHeaders() -- Headers not valid until getBody() is called.

    local function networkListener(event)
        if ( event.isError ) then
            native.showAlert( "Error", "Network Error! Please try again", {"Thanks"})    
        else
            --print(event.response)
            camera.alpha = 1
            plus.alpha = 1
            info.alpha = 1

            local result = json.decode( event.response )
            if result["success"] == 0 then
                native.showAlert( "Sorry :(", "We could not find any similar content", {"Thanks"})    
                --loadingSheet.destroy()
                removeSpinner()
            else
                local content_type = result['type']
                local url = result['url']

                if content_type == "url" then
                    --loadingSheet.destroy()
                    removeSpinner()
                    loadURL(url)
                else
                    downloadVideo(url)
                end             
                
                return
            end
        end
    end

    network.request( "http://ec2-54-201-110-77.us-west-2.compute.amazonaws.com/augment/decode.php", "POST", networkListener, params )
end

function new()
    --display.setDrawMode( "forceRender" )

    local g = display.newGroup()

    local shape = display.newRect( display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight )
    shape.fill = { type="camera" }
    --g:insert(shape)
    --shape.fill = { 0,0,255 }

    local xpos, ypos = display.contentCenterX, display.contentHeight - 10
    local circle = display.newCircle(g, xpos, ypos, 1)
    local xdirection = 1
    circle.alpha = .004

    local function animate(event)
        xpos = xpos + ( 2.8 * xdirection );

        if (xpos > display.contentWidth - 20 or xpos < 20) then
                xdirection = xdirection * -1;
        end
        if circle.x ~= nil then 
            circle:translate( xpos - circle.x, 0 )
        end
    end
    Runtime:addEventListener( "enterFrame", animate );

    -- test : loadURL("http://www.yahoo.com")
    -- test : loadVideo("IMG_1140.MOV")

    local function onPhotoComplete( event )
       if ( event.completed ) then
            local photo = event.target
            if photo then
                local gp = display.newGroup()
                photo.width = 320
                photo.height = 240
                photo.x = display.contentCenterX
                photo.y = display.contentCenterY
                gp:insert(photo)
                picture = tostring(os.time())..".png"
                display.save( gp, { filename=picture, baseDir=system.TemporaryDirectory, isFullResolution=true } )
                display.remove(gp)
                gp = nil    

                --loadingSheet.create("ANALYZING")

                spinner = widget.newSpinner
                {
                    width = 50,
                    height = 50
                }
                spinner.x = display.contentCenterX
                spinner.y = display.contentHeight * .9
                spinner:start()
                sendFile()
            end
        end
    end

    camera = widget.newButton
    {
        defaultFile = "assets/camera.png",
        overFile = "assets/camera_over.png",
        height = 480 / 568 * 100,
        width = 100,
        onRelease = function()
            camera.alpha = 0
            plus.alpha = 0
            info.alpha = 0

            local camSound = audio.loadSound( "assets/cam.m4a" )
            local playCam = audio.play( camSound )

            local screenCap = display.captureScreen( false )
            screenCap.x = display.contentCenterX
            screenCap.y = display.contentCenterY
            screenCap.width = 320
            screenCap.height = 240

            local gp = display.newGroup()
            gp:insert(screenCap)
            picture = tostring(os.time())..".png"
            display.save( gp, { filename=picture, baseDir=system.TemporaryDirectory, isFullResolution=true } )
            display.remove(gp)
            gp = nil

            spinner = widget.newSpinner
            {
                width = 50,
                height = 50
            }
            spinner.x = display.contentCenterX
            spinner.y = display.contentHeight * .9
            spinner:start()
            sendFile()  

            --[[if ( media.hasSource( media.Camera ) ) then
               media.capturePhoto( { listener = onPhotoComplete } )
            else
               native.showAlert( "Error", "This device does not have a camera.", { "OK" } )
            end]]--
        end
    }
    camera.x = display.contentCenterX
    camera.y = display.contentHeight * .9
    --g:insert(camera)

    plus = widget.newButton
    {
        defaultFile = "assets/plus.png",
        overFile = "assets/plus_over.png",
        height = 30,
        width = 30,
        onRelease = function()
            --shape.fill = nil
            --Runtime:removeEventListener( "enterFrame", animate )
            --display.remove(g)
            --g = nil
            display.remove(camera)
            display.remove(plus)
            display.remove(info)
            camera = nil
            plus = nil
            info = nil
            encode.new()
        end
    }
    plus.x = display.contentCenterX * .25
    plus.y = display.contentHeight * .9
    --g:insert(plus)

    info = widget.newButton
    {
        defaultFile = "assets/info.png",
        overFile = "assets/info_over.png",
        height = 50,
        width = 50,
        onRelease = function()
            loadURL("http://ec2-54-201-110-77.us-west-2.compute.amazonaws.com/augment/")
        end
    }
    info.x = display.contentCenterX * 1.75
    info.y = display.contentHeight * .9

    storyboard.cur = g
    return g
end