request = require("luajit-request")
xml = require("xml")
require("renderer")
require("tags")
require("ui")

function split(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function fetchURL(furl,external)
    tree = nil
    offset = 0
    if furl=="" then furl=url end
    if string.find(furl,"t://")==1 then furl="http://syvis.net:7302/koyhanmiehendns/?url="..furl end
    if external then
        love.system.openURL(furl)
    else
        local success=true
        if (string.find(furl,"command/")==1) then
            if furl=="command/back" then
                if #history>1 then
                    table.remove(history)
                    url=history[#history]
                    fetchURL(url)
                    table.remove(history)
                end
            end
        elseif (string.find(furl,"about/")==1) then
            page=love.filesystem.read(furl..".xml")
            success, tree = pcall(xml.collect,page)
            if not success then
                love.graphics.setBackgroundColor(1,0,0)
                tree=nil
            end
        else
            response = request.send(furl)
            if not (response==false) then
                success, tree = pcall(xml.collect,response.body)
                love.graphics.setBackgroundColor(1,1,1)
            else
                fetchURL("about/notfound")
                love.graphics.setBackgroundColor(1,0,0)
            end
            if not success then
                love.graphics.setBackgroundColor(1,0,0)
                tree=nil
                fetchURL("about/displayerror")
            end
            table.insert(history,furl)
            love.timer.sleep(0.2)
        end
    end
end

function love.load()
    love.graphics.setBackgroundColor(1,1,1)

    url='about/home'
    history={'about/home'}
    cache={}
    fetchURL(url)
    offset=0
    love.keyboard.setKeyRepeat(true)
end