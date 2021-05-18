request = require("luajit-request")

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

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

rootdefaults = {
    x=16,
    y=32,

    color = {0,0,0},
    bgcolor = {1,1,1,0},
    bordercolor = {0,0,0,0},
    borderwidth=0,

    font = "sans1",
    align = "left",
    padding = 0,
    margin = 0,
    ident = 0,

    direction = "down",
    block = "both",
}

defaults = {
    tekstiä = {
        font = "sans1",
        margin = 16,
        block = "both",
    },
    otsikko = {
        font = "sans3",
        margin = 16,
        block = "both",
    },
    pienempiotsikko = {
        font = "sans2",
        margin = 16,
        block = "both",
    },
    nappula = {
        font = "sans1",
        bordercolor = {0,0,0},
        bgcolor = {0.9,0.9,0.9},
        block = "both",
        padding = 4,
        selectcolor = {0.3,0.3,1},
    },
    linkkinappulat = {
        direction = "right",
        block = "vertical",
    },
    päähine = {
        bgcolor = {0.9,0.9,0.9},
        width = function(element) return love.graphics.getWidth() end,
        x = 0,
        ident = 16,
    },
    kuva = {
        image = function(element)
            if not cache[element.xarg["lähde"]] then
                local response = request.send(element.xarg["lähde"])
                local data = love.data.newByteData(response.body)
                cache[element.xarg["lähde"]] = love.graphics.newImage(data)
                print("yee")
            end
            return cache[element.xarg["lähde"]]
        end,
        width = function(element) return element.xarg["leveys"] end,
        height = function(element) return element.xarg["korkeus"] end,
        bordercolor = {0,0,0}
    },
    väli = {
        height = function(element) return element.xarg["korkeus"] or 16 end,
        block = "vertical"
    }
}

actions = {
    nappula = function(element)
        if element.xarg["kohde"] then
            if element.xarg["avaaulkoisesti"] then
                fetchURL(element.xarg["kohde"],true)
            else
                url=element.xarg["kohde"]
                fetchURL(url)
            end
        end
    end
}

function getDefaults(element)
    local default = defaults[element.label] or {}
    local processed = {}
    for i,v in pairs(default) do
        if type(v) == "function" then
            processed[i] = v(element)
        else
            processed[i] = v
        end
    end
    return processed
end

function renderElement(content,element,o,state)
    table.insert(layers,love.graphics.newCanvas())
    love.graphics.translate(0,-offset)
    love.graphics.setCanvas(layers[#layers])
    local merge = getDefaults(element)
    o = mergeoptions(o,merge)
    local img = o.image
    local w,h=0,0
    if content~="" then
        text = love.graphics.newText(fonts[o.font], content)
        text:setf(content, love.graphics.getWidth(), o.align)

        w = o.width or math.min(love.graphics.getWidth()-o.x,text:getWidth()+o.ident)
        text:setf(content, w, o.align)
        h = o.height or text:getHeight()
    else
        w = o.width or love.graphics.getWidth()-o.x
        h = o.height or (img and (img:getHeight()/img:getWidth())*w or 32)
    end
    local mx,my=love.mouse.getPosition()
    my=my+offset
    love.graphics.setColor(o.bgcolor)
    if (mx>o.x and mx<o.x+w+o.padding*3 and my>o.y and my<o.y+h+o.padding*3) then
        if o.selectcolor then love.graphics.setColor(o.selectcolor) end
        if love.mouse.isDown(1) and actions[element.label] then actions[element.label](element) end
    end
    love.graphics.rectangle('fill',o.x,o.y,w+o.padding*3,h+o.padding*3)
    if img then
        love.graphics.setColor(1,1,1)
        love.graphics.draw(o.image,o.x,o.y,0,(w+o.padding*3)/img:getWidth(),(h+o.padding*3)/img:getHeight())
    end
    love.graphics.setColor(o.bordercolor)
    love.graphics.setLineWidth(o.borderwidth)
    love.graphics.rectangle('line',o.x,o.y,w+o.padding*3,h+o.padding*3)
    love.graphics.setColor(o.color)
    if content~="" then
        love.graphics.draw(text,o.x+o.padding+o.ident,o.y+o.padding)
    end
    if (o.block=="vertical" or o.block=="both") and o.direction == "down" then
        o.y=o.y+h+o.margin+(o.padding*3)
    elseif (o.block=="horizontal" or o.block=="both") and o.direction == "right" then
        o.x=o.x+w+o.margin+(o.padding*3)
    end
    love.graphics.setCanvas()
    love.graphics.origin()
    return o,w+o.margin+(o.padding*3),h+o.margin+(o.padding*3)
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

function rendertestausxml(element,options)
    local thisoptions = deepcopy(options)
    if type(element[1])=="table" then
        local childoptions = mergeoptions(thisoptions,getDefaults(element))
        local mw,mh = 0,0
        for index,element in ipairs(element) do
            local merge, ow, oh = rendertestausxml(element,childoptions)
            childoptions.x, childoptions.y = merge.x, merge.y
            mw,mh=math.max(mw,ow or 0),math.max(mh,oh or 0)
        end
        local w,h=math.max(childoptions.x-options.x,mw), math.max(childoptions.y-options.y,mh)
        local o = deepcopy(thisoptions)
        o.width,o.height=w,h
        local merge = renderElement("",element,o,"render")
        thisoptions.y = h + thisoptions.y
    else
        merge, width, height = renderElement(string.gsub(element[1] or "", '^%s*(.-)%s*$', '%1'),element,thisoptions,"render")
        thisoptions = mergeoptions(thisoptions,merge)
    end
    return thisoptions, width, height
end

function render(tree)
    layers={}
    contentheight=0
    for index,branch in ipairs(tree) do
        if branch.label=="testausxml" then
            local options = rendertestausxml(branch,rootdefaults)
            contentheight=options.y
        end
    end
    love.graphics.setColor(1,1,1)
    for i=#layers,1,-1 do
        love.graphics.draw(layers[i])
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

function fetchURL(furl,external)
    if furl=="" then furl=url end
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
            success, tree = pcall(collect,page)
            if not success then
                love.graphics.setBackgroundColor(1,0,0)
                tree=nil
                fetchURL("about/displayerror")
            end
        else
            response = request.send(furl)
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
            table.insert(history,furl)
            love.timer.sleep(0.2)
        end
    end
end

function love.load()
    love.graphics.setBackgroundColor(1,1,1)
    fonts = {}
    fonts["sans1"] = love.graphics.newFont(12)
    fonts["sans2"] = love.graphics.newFont(18)
    fonts["sans3"] = love.graphics.newFont(24)

    url='https://testausserveri.github.io/testausbrowser/index.xml'
    history={}
    cache={}
    fetchURL(url)
    offset=0
    love.keyboard.setKeyRepeat(true)
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
            table.remove(history)
            url=history[#history]
            fetchURL(url)
            table.remove(history)
        end
    elseif key=="v" and love.keyboard.isDown("lctrl") then
        url=love.system.getClipboardText()
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

function love.draw()
    if tree then
        render(tree)
    end
    love.graphics.setColor(0.8,0.9,0.9)
    love.graphics.rectangle('fill',0,0,love.graphics.getWidth(),32)
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle('line',0,0,love.graphics.getWidth(),32)
    love.graphics.print(url, 32, 8)
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle('fill', love.graphics.getWidth()-4,32,4,offset/(contentheight-love.graphics.getHeight())*(love.graphics.getHeight()-32))
end