--The definitions of fonts

fonts = {
    sans1 = love.graphics.newFont(12),
    sans2 = love.graphics.newFont(18),
    sans3 = love.graphics.newFont(24),
}

--The default options for the document root passed to rendertestausxml
rootdefaults = {
    x=0,
    y=32,

    color = {0,0,0},
    bgcolor = {1,1,1,0},
    bordercolor = {0,0,0,0},
    borderwidth=0,

    font = "sans1",
    align = "left",
    padding = 0,
    margin = 0,
    indent = 0,
    contentindent = 0,
    spacing = 0,

    direction = "down",
    block = "both",
    layer = false,
}

--Default options for elements
defaults = {
    tekstiä = {
        font = "sans1",
        margin = 2,
        spacing = 16,
        block = "both",
        bordercolor = {0,0,0,0},
    },
    otsikko = {
        font = "sans3",
        margin = 0,
        block = "both",
        spacing = 16,
        margin = 16,
        color = {0,0,0.3},
        bordercolor = {0,0,0,0},
    },
    pienempiotsikko = {
        font = "sans2",
        margin = 0,
        block = "both",
        spacing = 16,
        margin = 16,
        color = {0.2,0.2,0.4},
        bordercolor = {0,0,0,0},
    },
    nappula = {
        font = "sans1",
        bordercolor = {0,0,0},
        bgcolor = {0.9,0.9,0.9},
        block = "both",
        padding = 4,
        selectcolor = {0.3,0.3,1},
        contentindent = 0,
    },
    linkkinappulat = {
        direction = "right",
        block = "vertical",
        indent = 16,
        bordercolor = {0,0,0,0},
        layer = true,
    },
    rivi = {
        direction = "right",
        block = "vertical",
        bordercolor = {0.5,0.5,0.5},
        layer = true,
    },
    päähine = {
        bgcolor = {0.9,0.9,1},
        width = function(element) return love.graphics.getWidth() end,
        x = 0,
        contentindent = 16,
        bordercolor = {0,0,0,0},
        layer = true,
    },
    kuva = {
        image = function(element)
            if not cache[element.xarg["lähde"]] then
                local response = request.send(element.xarg["lähde"])
                local data = love.data.newByteData(response.body)
                cache[element.xarg["lähde"]] = love.graphics.newImage(data)
            end
            return cache[element.xarg["lähde"]]
        end,
        width = function(element) return element.xarg["leveys"] end,
        height = function(element) return element.xarg["korkeus"] end,
        bordercolor = {0,0,0,0},
        layer = true,
    },
    väli = {
        height = function(element) return element.xarg["korkeus"] or 16 end,
        block = "vertical",
        bordercolor = {0,0,0,0},
    },
    sisältö = {
        contentindent = 16,
        bordercolor = {0,0,0,0},
    }
}

--interaction functions for elements:
actions = {
    nappula = {
        click = function(element,o)
            if element.xarg["kohde"] and love.window.hasMouseFocus() then
                if element.xarg["avaaulkoisesti"] then
                    fetchURL(element.xarg["kohde"],true)
                else
                    fetchURL(element.xarg["kohde"])
                end
                love.timer.sleep(0.2)
            end
            return o
        end,
        hover = function(element)
            o.bgcolor = o.selectcolor
        end
    }
}