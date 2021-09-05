--the basic keybinds and input handling
function love.keypressed(key, scancode)
    if key=="return" then
        fetchURL(url)
    elseif key=="backspace" then
        url=url:sub(0,-2)
    elseif key=="left" then
        if #history>1 then
            table.remove(history)
            url=history[#history]
            fetchURL(url)
            table.remove(history)
        end
    elseif key=="v" and love.keyboard.isDown("lctrl") then
        url=love.system.getClipboardText()
    elseif key=="q" and love.keyboard.isDown("lctrl") then
        love.event.quit()
    end
end

function love.textinput(t)
    url = url .. t
end

function love.wheelmoved( x, y )
    offset=offset-(y*20)
    if offset<0 then offset=0 end
    if offset>contentheight-love.graphics.getHeight() then offset=math.max(contentheight-love.graphics.getHeight(),0) end
end