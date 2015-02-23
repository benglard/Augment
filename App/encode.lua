module(..., package.seeall)

local widget = require( "widget" )
local storyboard = require( "storyboard" )
local json = require ( "json" ) 
local mime = require( "mime" )
local loadingSheet = require( "loading" )
local MultipartFormData = require("class_MultipartFormData")

local url = ""
local video = ""
local picture = ""

local function goNext()
    if (url == "" and video == "") or (picture == "") then
    	native.showAlert( "Error", "Please enter a url or a video and take a picture", {"Thanks!"} )		
    	return
    end

    if (url ~= "" and video ~= "") then 
    	native.showAlert( "Error", "Please enter a url OR a video", {"Thanks!"} )		
    	return
    end

    loadingSheet.create("SENDING")

    --print("URL " .. url)
    --print("Video " .. video)
    --print("Picture ".. picture)

    --upload
    local multipart = MultipartFormData.new()

    local content_type = "url"
    if video ~= "" then content_type = "video" end
    multipart:addField("type", content_type)

    if content_type == "url" then 
    	multipart:addField("url", url)
    else
    	multipart:addFile("video", system.pathForFile(video, system.TemporaryDirectory), "video/quicktime", video)
    end
    multipart:addFile("picture", system.pathForFile(picture, system.TemporaryDirectory), "image/png", picture)

    local params = {}
    params.body = multipart:getBody() -- Must call getBody() first!
    params.headers = multipart:getHeaders() -- Headers not valid until getBody() is called.

    local function networkListener(event)
        if ( event.isError ) then
            native.showAlert( "Error", "Network Error! Please try again", {"Thanks"})    
        else
        	--print(event.response)
            local result = json.decode( event.response )
            if result["success"] == 0 then
            	native.showAlert( "Error", "Sorry, file analysis failed, please try again.", {"Thanks"}) 
            	loadingSheet.destroy()   
            else
            	url = ""
            	video = ""
            	picture = ""
            	display.remove(storyboard.cur)
            	storyboard.cur = nil
            	loadingSheet.destroy()
            	home.new()
            	native.showAlert( "Success", "Your reality has been encoded!", {"Dismiss"})
            	return
            end
        end
    end

    network.request( "http://ec2-54-201-110-77.us-west-2.compute.amazonaws.com/augment/send_data.php", "POST", networkListener, params )
end

function new()
    local g = display.newGroup()

    local url_field

    local function screenMoved(event)
    	if(event.phase=="began")then
    		startX=event.x
    		xOrig = g.x
    	elseif(event.phase=="moved")then	
    		native.setKeyboardFocus( nil )

    		if(xOrig + (event.x-startX)<0)then
    			g.x=0
    		end
    	
    		if(xOrig + (event.x-startX)>0 and xOrig + (event.x-startX)<storyboard.screen.width-20)then
    			g.x = xOrig + (event.x-startX)
    			g.alpha = 1 - (g.x / storyboard.screen.width)
    			if url_field ~= nil then
    				url_field.alpha = g.alpha 
    				url_field.x = g.x + storyboard.screen.width/2
    			end
    		end
    	elseif( event.phase == "ended") then
    		if(g.x > 240) then
    			if url_field ~= nil then
    				url_field:removeSelf( )
        			url_field = nil
    			end
    			display.remove( storyboard.cur )
    			storyboard.cur = nil
    			home.new()
    		elseif (g.x > 125) then 
    			transition.to( g, { time=200, x=(240),transition=easing.inExpo } )
    		else
    			transition.to( g, { time=200, x=(0),transition=easing.inExpo } )
    			g.alpha = 1				
    		end
    	elseif( event.phase == "moved" and g.x == 0) then
    	end
    end


    local bg = display.newImageRect(g, "assets/blue_bg.png", storyboard.screen.width, 64 - storyboard.screen.top)
    bg.x = storyboard.screen.width/2
    bg.y = (64 - storyboard.screen.top) / 2

    local line = display.newRect( display.contentCenterX, (65-storyboard.screen.top), storyboard.screen.width, 3 )
    line.fill = {0}
    g:insert(line)

    local new_text = {
    	parent = g,
    	text = "New Encoding",
    	x = storyboard.screen.width/2,
    	y = 15 + storyboard.screen.top,
    	fontSize = 22,
    	font = native.systemFont,
    }
    local new_disp = display.newText(new_text)
    new_disp:setTextColor(255)

    local next_button = widget.newButton({
    	width = 160,
    	height = 40,
    	label = "Next",
        labelColor = { default = { 255 }, over = { 200 } },
    	labelYOffset = -4, 
    	font = native.systemFont,
    	fontSize = 18,
    	emboss = false,
    	onRelease = goNext
    })
    g:insert(next_button)
    next_button.x = 297
    next_button.y = storyboard.screen.top + 20

    local back_button = widget.newButton({
    	defaultFile = "assets/back.png",
    	overFile = "assets/back.png",
    	height = 32,
    	width = 59,
    	onRelease = function()
    		native.setKeyboardFocus( nil )
    		if url_field ~= nil then
    			url_field:removeSelf( )
    			url_field = nil
    		end

    		display.remove(storyboard.cur)
    		storyboard.cur = nil
    		home.new()
    	end
    })
    back_button.x = 32
    back_button.y = storyboard.screen.top + 15
    g:insert(back_button)

    local h = 480 - (64 - storyboard.screen.top)
    local bottom_bg = display.newRect(g, storyboard.screen.width/2, 265, 320, h)
    bottom_bg.fill = { 192,192,192 }

    local type_text = {
    	parent = g,
    	text = "Type of content:",
    	--x = storyboard.screen.width/2 - 73,
    	y = next_button.y + 60,
    	fontSize = 18,
    	font = native.systemFont,
    }
    local typet = display.newText(type_text)
    typet:setTextColor(0)
    typet.x = 20 + typet.contentWidth/2

    local url_button, vid_button, picture_text, picture_button, url_button_done, picture_button_done

    local been_moved = false
    local function move(dist)
    	if dist > 0 and been_moved then return end

    	vid_button.y = vid_button.y + dist
    	picture_text.y = picture_text.y + dist
    	picture_button.y = picture_button.y + dist
    	been_moved = true
    end

    url_button = widget.newButton
    {
    	defaultFile = "assets/gray.png",
    	overFile = "assets/gray_over.png",
    	height = 40,
    	width = 240,
    	label = "URL",
    	labelColor = { default={0}, over={255} },
    	emboss = false,
    	onRelease = function()
    		move(40)
    		url_field.isVisible = true
    	end
    }
    url_button.x = display.contentCenterX
    url_button.y = display.contentCenterY * .6
    g:insert(url_button)

    url_button_done = widget.newButton
    {
    	defaultFile = "assets/gray_done.png",
    	overFile = "assets/gray_done.png",
    	height = 40,
    	width = 240,
    	label = "URL",
    	labelColor = { default={0}, over={255} },
    	emboss = false,
    	onRelease = function()
    		return true
    	end
    }
    url_button_done.x = display.contentCenterX
    url_button_done.y = display.contentCenterY * .6
    url_button_done.isVisible = false
    g:insert(url_button_done)

    local function fieldListener(event)
    	if ( "submitted" == event.phase ) then
    		url = url_field.text

    		--if storyboard.debug then print(url) end

    		native.setKeyboardFocus( nil )

    		if url ~= "" then 
    			-- add http
        		url_button.isVisible = false
        		url_button_done.isVisible = true
        		url_field:removeSelf( )
        		url_field = nil
        	end
        	move(-40)
    	end
    end

    url_field = native.newTextField(storyboard.screen.width/2, url_button.y + 40, 240, 30)
    url_field.isVisible = false
    url_field.size = storyboard.textsize * 1.8
    url_field:setReturnKey("next")
    url_field:addEventListener( "userInput", fieldListener )

    local function copyVideoFile(videoPath,dstName,dstPath)
      local rfilePath=videoPath
      local wfilePath=system.pathForFile(dstName,dstPath)
      local rfh=io.open(rfilePath,"rb")
      local wfh=io.open(wfilePath,"wb")
      if not(wfh) then
        return false
      else
        local data=rfh:read("*a")
        if not(data) then
          return false
        else
          if not(wfh:write(data)) then
            return false
          end
        end
      end
      rfh:close()
      wfh:close()
      return true
    end

    local function onVideoComplete(event)
      if (event.completed) then
        local videoFileExtension=".mov"
        if (system.getInfo("platformName")=="Android") then
          videoFileExtension=".mp4"
        end
        local videoFilePath=string.sub(event.url,8,-1)
        local savedVideoFileName="video" .. tostring(os.time()) .. videoFileExtension
        video = savedVideoFileName
        local savedVideoDirectory=system.TemporaryDirectory

        if (copyVideoFile(videoFilePath,savedVideoFileName,savedVideoDirectory)) then
          --your video is now saved under (savedVideoDirectory) directory
          --and the filename of the video is (savedVideoFileName)
          --do whatever you need to do :)

          --[[local function mediaPlayListener(event)
            print("video ended")
          end
          media.playVideo(savedVideoFileName,savedVideoDirectory,true,mediaPlayListener)]]--

          vid_button.isVisible = false
          url_button_done:setLabel( "Video" )
          url_button_done.y = vid_button.y
          url_button_done.isVisible = true
        end
      end
    end

    local function takeVideo()
    	media.captureVideo({listener=onVideoComplete,
    						preferredQuality="high",
    						preferredMaxDuration=20})
    end

    local function selectVideo()
    	media.selectVideo( { listener = onVideoComplete, mediaSource = media.PhotoLibrary } ) 
    end

    local function onAlertComplete(event)
    	--print( "index => ".. event.index .. "    action => " .. event.action )

    	local action = event.action
    	if "clicked" == event.action then
    		if event.index == 2 then
    			return
    		elseif event.index == 1 then
    			selectVideo()
    		--elseif event.index == 2 then 
    		--	takeVideo()
    		end
    	elseif "cancelled" == event.action then
    	end
    end

    vid_button = widget.newButton
    {
    	defaultFile = "assets/gray.png",
    	overFile = "assets/gray_over.png",
    	height = 40,
    	width = 240,
    	label = "Video",
    	labelColor = { default={0}, over={255} },
    	emboss = false,
    	onRelease = function()
    		--local alert = native.showAlert( "New Video", "Upload a video", { "Choose Existing", "Take Video", "None" }, onAlertComplete )
    		local alert = native.showAlert( "New Video", "Upload a video", { "Choose Existing", "None" }, onAlertComplete )
    	end
    }
    vid_button.x = display.contentCenterX
    vid_button.y = url_button.y + 60
    g:insert(vid_button)

    local picture_button_done

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

    		    picture_button.isVisible = false
    		    picture_button_done.isVisible = true
    		end
        end
    end

    local picture_ops = {
    	parent = g,
    	text = "Take Picture:",
    	--x = storyboard.screen.width/2 - 140,
    	y = vid_button.y + 60,
    	fontSize = 18,
    	font = native.systemFont,
    }
    picture_text = display.newText(picture_ops)
    picture_text:setTextColor(0)
    picture_text.x = 20 + picture_text.contentWidth/2

    picture_button = widget.newButton
    {
    	defaultFile = "assets/gray.png",
    	overFile = "assets/gray_over.png",
    	height = 40,
    	width = 240,
    	label = "Take Picture",
    	labelColor = { default={0}, over={255} },
    	emboss = false,
    	onRelease = function()
    		local cam, bb

    		local bg = display.newRect( display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight )
    		bg.fill = { type="camera" }

    		bb = widget.newButton({
    			defaultFile = "assets/back.png",
    			overFile = "assets/back.png",
    			height = 32,
    			width = 59,
    			onRelease = function()
    				display.remove(bg)
    				bg = nil
    				display.remove(cam)
    				cam = nil
    				display.remove(bb)
    				bb = nil
    			end
    	    })
    	    bb.x = 40
    	    bb.y = storyboard.screen.top + 10

    		cam = widget.newButton
    		{
    			defaultFile = "assets/camera.png",
    			overFile = "assets/camera_over.png",
    			height = 480 / 568 * 100,
    			width = 100,
    			onRelease = function()
    				cam.alpha = 0
    				bb.alpha = 0

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

    				display.remove(bg)
    				bg = nil
    				display.remove(cam)
    				cam = nil
    				display.remove(bb)
    				bb = nil

    				picture_button.isVisible = false
    		    	picture_button_done.isVisible = true
    			end
    		}
    		cam.x = display.contentCenterX
    		cam.y = display.contentHeight * .9

    		--[[if ( media.hasSource( media.Camera ) ) then
    		   media.capturePhoto( { listener = onPhotoComplete } )
    		else
    		   native.showAlert( "Error", "This device does not have a camera.", { "OK" } )
    		end]]--
    	end
    }
    picture_button.x = display.contentCenterX
    picture_button.y = vid_button.y + 110
    g:insert(picture_button)

    picture_button_done = widget.newButton
    {
    	defaultFile = "assets/gray_done.png",
    	overFile = "assets/gray_done.png",
    	height = 40,
    	width = 240,
    	label = "Take Picture",
    	labelColor = { default={0}, over={255} },
    	emboss = false,
    	onRelease = function()
    		return true
    	end
    }
    picture_button_done.x = display.contentCenterX
    picture_button_done.y = vid_button.y + 110
    picture_button_done.isVisible = false
    g:insert(picture_button_done)

    g:addEventListener( "touch", screenMoved )
    storyboard.cur = g
    return g
end