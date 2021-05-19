fonts = {
    sans1 = love.graphics.newFont(12),
    sans2 = love.graphics.newFont(18),
    sans3 = love.graphics.newFont(24),
}

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
    },
    väli = {
        height = function(element) return element.xarg["korkeus"] or 16 end,
        block = "vertical"
    },
    sisältö = {
        ident = 16
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