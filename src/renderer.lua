function hextorgb(hex)
    local rgb={}
    for i=2,#hex,2 do
        table.insert(rgb,tonumber(string.sub(hex,i,i+1),16)/255)
    end
    return rgb
end

function testhex(input)
    if tostring(tonumber(input)) == input then
        return tonumber(input)
    elseif string.find(input, "^#[%da-fA-F]+$") then
        return hextorgb(input)
    else
        return input
    end
end

translations = {
    x = "x",
    y = "y",
    leveys = "width",
    korkeus = "height",

    väri = "color",
    tausta = "bgcolor",
    reunaväri = "bordercolor",
    korostusväri = "selectcolor",

    reuna = "borderwidth",
    sisennys = "ident",
    keskitys = "align",
    täyte = "padding",
    välijälkeen = "margin",
    väliennen = "spacing",

    fontti = "font",
    suunta = "direction",
    tila = "block",
}


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
    if element.xarg then
        for i,v in pairs(element.xarg) do
            if translations[i] then
                processed[translations[i]] = testhex(v)
            end
        end
    end
    return processed
end

function renderElement(content,element,o,parent)
    table.insert(layers,love.graphics.newCanvas())
    love.graphics.translate(0,-offset)
    love.graphics.setCanvas(layers[#layers])
    local merge = getDefaults(element)
    o = mergeoptions(o,merge)
    local img = o.image
    local w,h=0,0
    if (o.block=="vertical" or o.block=="both") and o.direction == "down" then
        o.y=o.y+o.spacing
    elseif (o.block=="horizontal" or o.block=="both") and o.direction == "right" then
        o.x=o.x+o.spacing
    end
    xpcall(function()
        assert(fonts[o.font]~=nil,"Invalid font")
        if content~="" then
            text = love.graphics.newText(fonts[o.font], content)
            text:setf(content, love.graphics.getWidth(), o.align)

            w = o.width or math.min(love.graphics.getWidth()-o.x-o.ident,text:getWidth()+o.ident)
            if o.direction == "right" and o.width=="fit" then
                w = (love.graphics.getWidth())/#parent-o.padding*3-o.margin
            end
            text:setf(content, w, o.align)
            h = o.height or text:getHeight()
            if o.direction == "down" and o.height=="fit" then
                h = (love.graphics.getHeight())/#parent-o.padding*3-o.margin
            end
        else
            w = o.width or love.graphics.getWidth()-o.x
            h = o.height or (img and (img:getHeight()/img:getWidth())*w or 32)
            if o.direction == "right" and o.width=="fit" then
                w = (love.graphics.getWidth())/#parent-o.padding*3-o.margin
            elseif o.direction == "down" and o.height=="fit" then
                h = (love.graphics.getHeight())/#parent-o.padding*3-o.margin
            end
        end
        if element.label=="testausxml" then
            w = love.graphics.getWidth()-o.x
            h = math.max(h,love.graphics.getHeight())
        end
        local mx,my=love.mouse.getPosition()
        my=my+offset
        assert(type(w)=="number","Invalid width")
        assert(type(h)=="number","Invalid height")

        assert(type(o.bgcolor)=="table","Invalid background color")
        assert(type(o.color)=="table","Invalid text color")
        assert(type(o.bordercolor)=="table","Invalid border color")
        assert(type(o.ident)=="number","Invalid identation property")
        assert(type(o.padding)=="number","Invalid padding property")
        assert(type(o.margin)=="number","Invalid margin property")
        assert(type(o.borderwidth)=="number","Invalid border property")

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
    end, function(error)
        text = love.graphics.newText(fonts["sans2"], "RENDERERROR: "..split(error,":")[3])
        w,h=text:getWidth(),text:getHeight()
        o.padding=0
        o.margin=0
        o.ident=0
        love.graphics.setColor(1,0,0)
        love.graphics.rectangle('fill',o.x,o.y,w+o.padding*3,h+o.padding*3)
        love.graphics.setColor(1,1,1)
        love.graphics.draw(text,o.x+o.padding+o.ident,o.y+o.padding)
    end)
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

function rendertestausxml(element,options,parent)
    local thisoptions = deepcopy(options)
    if type(element[1])=="table" then
        local childoptions = mergeoptions(thisoptions,getDefaults(element))
        local mw,mh = 0,0

        for index,child in ipairs(element) do
            local merge, ow, oh = rendertestausxml(child,childoptions,element)
            childoptions.x, childoptions.y = merge.x, merge.y
            mw,mh=math.max(mw,ow or 0),math.max(mh,oh or 0)
        end
        local w,h=math.max(childoptions.x-options.x,mw), math.max(childoptions.y-options.y,mh)
        local o = deepcopy(thisoptions)
        o.width,o.height=w,h
        local merge = renderElement("",element,o,parent)
        thisoptions.y = h + thisoptions.y
    else
        merge, width, height = renderElement(string.gsub(element[1] or "", '^%s*(.-)%s*$', '%1'),element,thisoptions,parent)
        thisoptions = mergeoptions(thisoptions,merge)
    end
    return thisoptions, width, height
end

function render(tree)
    layers={}
    contentheight=0
    for index,branch in ipairs(tree) do
        if branch.label=="testausxml" then
            local options = rendertestausxml(branch,rootdefaults,tree)
            contentheight=options.y
        end
    end
    love.graphics.setColor(1,1,1)
    for i=#layers,1,-1 do
        love.graphics.draw(layers[i])
    end
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