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

--Translations to relay testausXML arguments to renderer.
translations = {
    x = "x",
    y = "y",
    leveys = "width",
    korkeus = "height",

    reunaväri = "bordercolor",
    korostusväri = "selectcolor",

    reuna = "borderwidth",
    sisennys = "indent",
    tekstisisennys = "contentindent",
    keskitys = "align",
    täyte = "padding",
    välijälkeen = "margin",
    väliennen = "spacing",

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

--Gets options for an element, merging the element's default options in tags.lua and the manual options given in testausXML.
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

--Merges two option tables, preferring the second.
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

function renderElement(content,element,o,parent)
    --initializes some values
    local merge = getDefaults(element)
    o = mergeoptions(o,merge)
    local img = o.image
    local w,h=0,0
    --moves the coordinates according to the margins and flowing direction
    if (o.block=="vertical" or o.block=="both") and o.direction == "down" then
        o.y=o.y+o.spacing
    elseif (o.block=="horizontal" or o.block=="both") and o.direction == "right" then
        o.x=o.x+o.spacing
    end
    --everything is in protected call, there usually happens errors.
    xpcall(function()
        assert(fonts[o.font]~=nil,"Invalid font")
        --Makes a text object and sizes it accordingly, or otherwise initializes the width and height.
        if content~="" then
            text = love.graphics.newText(fonts[o.font], content)
            text:setf(content, love.graphics.getWidth(), o.align)

            w = o.width or math.min(love.graphics.getWidth()-o.x-o.indent-o.contentindent,text:getWidth()+o.contentindent)
            if w=="fit" then
                w = ((love.graphics.getWidth()-o.indent)/#parent-o.padding*2-o.margin-o.indent)
            end
            text:setf(content, w, o.align)
            h = o.height or text:getHeight()
        else
            w = o.width or love.graphics.getWidth()-o.x
            h = o.height or (img and (img:getHeight()/img:getWidth())*w or 32)
            if w=="fit" then
                w = ((love.graphics.getWidth()-o.indent)/#parent-o.padding*2-o.margin-o.indent)
            end
        end
        --Special cases for document root
        if element.label=="testausxml" then
            w = love.graphics.getWidth()-o.x
            h = math.max(h,love.graphics.getHeight())
        end
        local mx,my=love.mouse.getPosition()
        my=my+offset

        --asserts for some common errors in element properties.
        assert(type(w)=="number","Invalid width")
        assert(type(h)=="number","Invalid height")

        assert(type(o.bgcolor)=="table","Invalid background color")
        assert(type(o.color)=="table","Invalid text color")
        assert(type(o.bordercolor)=="table","Invalid border color")
        assert(type(o.indent)=="number","Invalid indentation property")
        assert(type(o.padding)=="number","Invalid padding property")
        assert(type(o.margin)=="number","Invalid margin property")
        assert(type(o.borderwidth)=="number","Invalid border property")

        --The element's total width & height for the canvas.
        local cw,ch =   w+o.margin+(o.padding*2)+(o.borderwidth*2)+o.indent+o.contentindent,
                        h+o.margin+(o.padding*2)+(o.borderwidth*2)
        if o.layer then
            cw = love.graphics.getWidth()
            if contentheight and contentheight-o.x>0 then
                ch=contentheight-o.x
            else
                ch=love.graphics.getHeight()
            end
        end
        local layer = {
            canvas = love.graphics.newCanvas(cw,ch),
            x = o.x-o.borderwidth,
            y = o.y-o.borderwidth
        }
        
        --checks whether to create a new layer or to merge to an existing layer.
        if getDefaults(parent).layer or o.layer or #layers==0 then
            table.insert(layers,layer)
        else
            layer = layers[#layers]
        end
        love.graphics.setCanvas(layer.canvas)
        love.graphics.translate(-layer.x,-layer.y)

        --draws the background, also calling the click action (IDK why it is here)
        love.graphics.setColor(o.bgcolor)
        if (mx>o.x and mx<o.x+w+o.padding*2 and my>o.y and my<o.y+h+o.padding*2) then
            if o.selectcolor then love.graphics.setColor(o.selectcolor) end
            if love.mouse.isDown(1) and actions[element.label] then actions[element.label].click(element) end
        end
        love.graphics.rectangle('fill',o.x+o.indent,o.y,w+o.padding*2,h+o.padding*2)
        
        --draws image if specified
        if img then
            love.graphics.setColor(1,1,1)
            love.graphics.draw(o.image,o.x+o.indent+o.padding,o.y+o.padding,0,w/img:getWidth(),h/img:getHeight())
        end
        
        --draws borders
        love.graphics.setColor(o.bordercolor)
        love.graphics.setLineWidth(o.borderwidth)
        love.graphics.rectangle('line',o.x+o.indent,o.y,w+o.padding*2,h+o.padding*2)
        
        --draws the text
        love.graphics.setColor(o.color)
        if content~="" then
            love.graphics.draw(text,o.x+(o.padding/2)+o.indent+o.contentindent,o.y+(o.padding/2))
        end

        --increments the coordinates according to the space the element took, to position following elements accordingly.
        if (o.block=="vertical" or o.block=="both") and o.direction == "down" then
            o.y=o.y+h+o.margin+(o.padding*2)
        elseif (o.block=="horizontal" or o.block=="both") and o.direction == "right" then
            o.x=o.x+w+o.margin+(o.padding*2)
        end
        o.layer = false
    end, function(error)
        --handles errors in the drawing functions, draws an error message in place of the element.
        print(error)
        text = love.graphics.newText(fonts["sans2"], "RENDERERROR: "..split(error,":")[3])
        console.log(error)
        w,h=text:getWidth(),text:getHeight()
        o.padding=0
        o.margin=0
        o.indent=0
        love.graphics.setColor(1,0,0)
        love.graphics.rectangle('fill',o.x,o.y,w+o.padding*3,h+o.padding*3)
        love.graphics.setColor(1,1,1)
        love.graphics.draw(text,o.x+o.padding+o.indent,o.y+o.padding)
    end)
    love.graphics.setCanvas()
    love.graphics.origin()
    --returns properties to be inherited by consequent elements, and also the width and height to space parent elements correctly.
    return o,w+o.margin+(o.padding*2),h+o.margin+(o.padding*2)
end

--Recursive function to draw the whole tree.
function rendertestausxml(element,options,parent)
    local thisoptions = deepcopy(options)
    if type(element[1])=="table" then
        local childoptions = mergeoptions(thisoptions,getDefaults(element))
        local mw,mh = 0,0

        --Draws the children of the element, keeping track on the space they require
        for index,child in ipairs(element) do
            local merge, ow, oh = rendertestausxml(child,childoptions,element)
            childoptions.x, childoptions.y = merge.x, merge.y
            mw,mh=math.max(mw,ow or 0),math.max(mh,oh or 0)
        end

        --merges the space required in the element's properties
        local w,h=math.max(childoptions.x-options.x,mw), math.max(childoptions.y-options.y,mh)
        local o = mergeoptions(deepcopy(thisoptions),getDefaults(element))
        o.width,o.height=w,h
        
        --finally renders the element
        local merge = renderElement("",element,o,parent)
        thisoptions.y = h + thisoptions.y
    else
        --If the element doesn't have children, just draw it
        merge, width, height = renderElement(string.gsub(element[1] or "", '^%s*(.-)%s*$', '%1'),element,thisoptions,parent)
        thisoptions = mergeoptions(thisoptions,merge)
    end
    return thisoptions, width, height
end

function render(tree)
    --initializes some values and the layer table
    if not contentheight then contentheight=0 end
    layers={}

    --looks for the testausXML tag in the tree (the root element) and draws it to canvases.
    for index,branch in ipairs(tree) do
        if branch.label=="testausxml" then
            local options = rendertestausxml(branch,rootdefaults,tree)
            contentheight=options.y
        end
    end
    love.graphics.origin()
    love.graphics.setColor(1,1,1)
    --draws the canvases in reverse order, to ensure correct Z-indexes.
    for i=#layers,1,-1 do
        love.graphics.draw(layers[i].canvas,layers[i].x,layers[i].y-offset)
    end
end

function love.draw()
    if tree then
        --protected call, displays displayerror page if render function errors.
        success,error = pcall(render,tree)
        if not success then
            console.log("XML render errored with: "..error)
            fetchURL("about/displayerror")
            return
        end
    else
        contentheight=0
        layers={}
    end
    --draws the url bar
    love.graphics.setColor(0.8,0.9,0.9)
    love.graphics.rectangle('fill',0,0,love.graphics.getWidth(),32)
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle('line',0,0,love.graphics.getWidth(),32)
    love.graphics.print(url, 32, 8)

    --draws the scrollbar
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle('fill', love.graphics.getWidth()-4,32,4,offset/(contentheight-love.graphics.getHeight())*(love.graphics.getHeight()-32))
    r,g,b = love.graphics.getBackgroundColor()

    if love.keyboard.isDown("f3") or g==0 then
        --Draws the developer console, giving some data.
        love.graphics.setFont(fonts.sans1)
        text = love.graphics.newText(fonts.sans1, console.content)
        text:setf(console.content, love.graphics.getWidth(), "left")

        love.graphics.setColor(0,0,0,0.75)
        love.graphics.rectangle('fill', 0,love.graphics.getHeight()-text:getHeight(),love.graphics.getWidth(),text:getHeight())

        love.graphics.setColor(0,0,0)
        local size = 0
        for i,layer in ipairs(layers) do
            size=size+layer.canvas:newImageData():getSize()
        end
        love.graphics.print("LAYERS: "..#layers.." ("..(size/1000).."kB)",32,love.graphics.getHeight()-text:getHeight()-16)

        love.graphics.setColor(1,1,1)
        love.graphics.draw(text,0,love.graphics.getHeight()-text:getHeight())
    end
end