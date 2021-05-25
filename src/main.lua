request = require("luajit-request")
xml = require("xml")
require("renderer")
require("tags")
require("ui")

console = {content=string.rep("\n ",10)}
console.log = function(text)
    local rows=split(console.content,"\n")
    table.insert(rows,text)
    if #rows>10 then
        table.remove(rows,1)
    end
    console.content=table.concat(rows,"\n")
end

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
    offset = 0
    if furl=="" then furl=url end
    if string.find(furl,"/")==1 then
        if string.find(url,"%.xml")==nil then url=url.."/index.xml" end
        local s = string.find(url,"://")
        local t = split(string.sub(url,s+1),"/")
        t[#t]=string.sub(furl,2)
        furl=string.sub(url,1,s+2)..table.concat(t,"/")
    end
    if (furl~="about/notfound" and furl~="about/displayerror" and not external) then
        url=furl
        table.insert(history,furl)
        love.graphics.setBackgroundColor(1,1,1)
    elseif furl=="about/notfound" or furl=="about/displayerror" then
        love.graphics.setBackgroundColor(1,0,0)
    end
    if string.find(furl,"t://")==1 then console.log("Getting redirection from köyhänmiehenDNS for "..furl) furl="207.180.196.31:7302/koyhanmiehendns/?url="..furl end
    if external then
        love.system.openURL(furl)
    else
        local success=true
        if (string.find(furl,"command/")==1) then
            console.log("Running command: "..furl)
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
            console.log(success and "local file " .. furl.." loaded succesfully." or furl.." errored in xml parse with: "..tree)
            if not success then
                love.graphics.setBackgroundColor(1,0,0)
                tree=nil
            end
        else
            local start = love.timer.getTime()*1000
            response = request.send(furl)
            local stop = love.timer.getTime()*1000
            console.log(response and "HTTP request to "..furl.." returned code "..response.code.." in "..(stop-start).." ms" or "request to "..furl.." unsuccesful.")
            if not (response==false or response.code==404) then
                local start = love.timer.getTime()*1000
                success, tree = pcall(xml.collect,response.body)
                local stop = love.timer.getTime()*1000
                console.log(success and "XML parse succesful in "..(stop-start).." ms" or "XML parse errored with: "..tree)
            else
                fetchURL("about/notfound")
                table.remove(history)
            end
            if not success then
                tree=nil
                fetchURL("about/displayerror")
                table.remove(history)
            end
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