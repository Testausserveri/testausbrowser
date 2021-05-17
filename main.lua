request = require("luajit-request")

function parseargs(s)
    local arg = {}
    string.gsub(s, "([%-%wöäå]+)=([\"'])(.-)%2", function (w, _, a)
        arg[w] = a
    end)
    return arg
end
      
function collect(s)
    local stack = {}
    local top = {}
    table.insert(stack, top)
    local ni,c,label,xarg, empty
    local i, j = 1, 1
    while true do
        ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%wöäå:]+)(.-)(%/?)>", i)
        if not ni then break end
        local text = string.sub(s, i, ni-1)
        if not string.find(text, "^%s*$") then
            table.insert(top, text)
        end
        if empty == "/" then  -- empty element tag
            table.insert(top, {label=label, xarg=parseargs(xarg), empty=1})
        elseif c == "" then   -- start tag
            top = {label=label, xarg=parseargs(xarg)}
            table.insert(stack, top)   -- new level
        else  -- end tag
            local toclose = table.remove(stack)  -- remove top
            top = stack[#stack]
            if #stack < 1 then
            error("nothing to close with "..label)
            end
            if toclose.label ~= label then
            error("trying to close "..toclose.label.." with "..label)
            end
            table.insert(top, toclose)
        end
        i = j+1
    end
    local text = string.sub(s, i)
    if not string.find(text, "^%s*$") then
        table.insert(stack[#stack], text)
    end
    if #stack > 1 then
        error("unclosed "..stack[#stack].label)
    end
    return stack[1]
end

renderers = {}

renderers["kuva"] = function(content,element,o,prerender)
    if not prerender then
        love.graphics.setColor(1,1,1)
        local url=element.xarg["lähde"]
        if (cache[url]==nil) then
            response = request.send(url)
            local bytedata = love.data.newByteData(response.body)
            local image = love.graphics.newImage(bytedata)
            cache[url] = image
        end
        local image = cache[url]
        local w = element.xarg.leveys or image:getWidth()
        local h = element.xarg.korkeus or (image:getHeight()/image:getWidth())*w
        love.graphics.draw(image,o.x,o.y,0,w/image:getWidth(),h/image:getHeight())
        return o
    else
        return 0,0
    end
end

renderers["päähine"] = function(content,element,o,prerender)
    if not prerender then
        local w,h=getDimensions(element,o)
        love.graphics.setColor(o.bgcolor)
        love.graphics.rectangle('fill',0,o.y,love.graphics.getWidth(),h)
        o.y=o.y+8
        return o
    else
        return 0,0
    end
end

renderers["otsikko"] = function(content,element,o,prerender)
    text = love.graphics.newText(font3, content)
    text:setf(content, love.graphics.getWidth()-o.x, "left")

    if not prerender then
        love.graphics.setColor(o.color)
        love.graphics.draw(text,o.x,o.y)
        o.y=o.y+text:getHeight()+16
        return o
    else
        return text:getWidth(), text:getHeight()+16
    end
end

renderers["pienempiotsikko"] = function(content,element,o,prerender)
    text = love.graphics.newText(font2, content)
    text:setf(content, love.graphics.getWidth()-o.x, "left")

    if not prerender then
        love.graphics.setColor(o.color)
        love.graphics.draw(text,o.x,o.y+text:getHeight())
        o.y=o.y+text:getHeight()+16
        return o
    else
        return text:getWidth(), text:getHeight()+16
    end
end

renderers["tekstiä"] = function(content,element,o,prerender)
    text = love.graphics.newText(font, content)
    text:setf(content, love.graphics.getWidth()-o.x, "left")

    if not prerender then
        love.graphics.setColor(o.color)
        love.graphics.draw(text,o.x,o.y+text:getHeight())

        o.y=o.y+text:getHeight()+16
        return o
    else
        return text:getWidth(), text:getHeight()
    end
end

renderers["nappula"] = function(content,element,o,prerender)
    o.ox=o.ox or 0
    text = love.graphics.newText(font, content)
    text:setf(content, love.graphics.getWidth()-o.x, "left")

    if not prerender then
        love.graphics.setColor(o.bgcolor)
        if o.mx>o.x+o.ox and o.mx<o.x+o.ox+text:getWidth()+8 and o.my>o.y and o.my<o.y+text:getHeight()+8 then
            love.graphics.setColor(o.selectcolor)
            if o.md then
                if element.xarg.avaaulkoisesti then
                    love.system.openURL(element.xarg.url)
                else
                    url=element.xarg.kohde
                    fetchURL(url)
                end
            end
        end
        love.graphics.rectangle('fill',o.x-4+o.ox,o.y-4,text:getWidth()+8,text:getHeight()+8)
        love.graphics.setColor(o.color)
        love.graphics.rectangle('line',o.x-4+o.ox,o.y-4,text:getWidth()+8,text:getHeight()+8)
        love.graphics.draw(text,o.x+o.ox,o.y)

        o.ox=o.ox+text:getWidth()+8
        return o
    else
        return text:getWidth()+8,0
    end
end

function mergeoptions(options,merge)
    local opt={}
    for i,v in pairs(options) do
        opt[i]=v
    end
    for i,v in pairs(merge) do
        opt[i]=v
    end
    return opt
end

function getDimensions(element,options)
    local x,y=0,0
    if type(element[1]) == "table" then
        if renderers[element.label] ~= nil then
            local ox,oy=renderers[element.label]("",element,options,true)
            x,y=x+ox,y+oy
        end
        for k,v in pairs(element) do
            ox,oy=getDimensions(v,options)
            x,y=x+ox,y+oy
        end
    else
        if renderers[element.label] ~= nil then
            local ox,oy=renderers[element.label](string.gsub(element[1], '^%s*(.-)%s*$', '%1'),element,options,true)
            x,y=x+ox,y+oy
        end
    end
    return x,y
end

function rendertestausxml(xml,options)
    for index,element in ipairs(xml) do
        if type(element[1])=="table" then
            if renderers[element.label] ~= nil then
                merge=renderers[element.label]("",element,options)
                options=mergeoptions(options,merge)
            end
            rendertestausxml(element,options)
        elseif type(element[1])=="string" then
            if renderers[element.label] ~= nil then
                merge=renderers[element.label](string.gsub(element[1], '^%s*(.-)%s*$', '%1'),element,options)
                options=mergeoptions(options,merge)
            else
                merge=renderers["tekstiä"](string.gsub(element[1], '^%s*(.-)%s*$', '%1'),element,options)
                options=mergeoptions(options,merge)
            end
        end
    end
end

function render(tree)
    for index,branch in ipairs(tree) do
        if branch.label=="testausxml" then
            rendertestausxml(branch,{
                x=16,
                y=32,

                color={0,0,0},
                bgcolor={0.9,0.9,0.9},
                selectcolor={0.3,0.3,1},

                mx=love.mouse.getX(),
                my=love.mouse.getY(),
                md=love.mouse.isDown(1)
            })
        end
    end
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

function fetchURL(url)
    local success=true
    if (string.find(url,"about/")~=1) then
        table.insert(history,url)
        response = request.send(url)
        if not (response==false) then
            success, tree = pcall(collect,response.body)
            love.graphics.setBackgroundColor(1,1,1)
        else
            fetchURL("about/notfound")
            love.graphics.setBackgroundColor(1,0,0)
        end
        if not success then
            love.graphics.setBackgroundColor(1,0,0)
            tree=nil
            fetchURL("about/displayerror")
            --love.system.openURL(url)
        end
    else
        page=love.filesystem.read(url..".xml")
        success, tree = pcall(collect,page)
        if not success then
            love.graphics.setBackgroundColor(1,0,0)
            tree=nil
            fetchURL("about/displayerror")
        end
    end
    love.timer.sleep(0.2)
end

function love.load()
    love.graphics.setBackgroundColor(1,1,1)
    font = love.graphics.newFont(12)
    font2 = love.graphics.newFont(18)
    font3 = love.graphics.newFont(24)
    url='https://testausserveri.github.io/testausbrowser/index.xml'
    history={}
    cache={}
    fetchURL(url)
    offset=0
end

function love.update(dt)
    
end

function love.keypressed(key, scancode)
    if key=="return" then
        fetchURL(url)
    elseif key=="backspace" then
        url=url:sub(0,-2)
    elseif key=="left" then
        if #history>1 then
            table.remove(history,#history)
            url=history[#history]
            fetchURL(url)
        end
    elseif key=="v" and love.keyboard.isDown("lctrl") then
        url=love.system.getClipboardText()
    end
end

function love.textinput(t)
    url = url .. t
end

function love.wheelmoved( x, y )
    offset=offset+((y^3)*10)
    if offset>0 then offset=0 end
end

function love.draw()
    love.graphics.translate(0,offset)
    if tree then
        render(tree)
    end
    love.graphics.origin()
    love.graphics.setColor(0.8,0.9,0.9)
    love.graphics.rectangle('fill',0,0,love.graphics.getWidth(),32)
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle('line',0,0,love.graphics.getWidth(),32)
    love.graphics.print(url, 32, 8)
end