--XML parser (not mine, I found it from the side of the road)

local xml={}
function xml.parseargs(s)
    local arg = {}
    string.gsub(s, "([%-%wöäå]+)=([\"'])(.-)%2", function (w, _, a)
        arg[w] = a
    end)
    return arg
end
      
function xml.collect(s)
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
            table.insert(top, {label=label, xarg=xml.parseargs(xarg), empty=1})
        elseif c == "" then   -- start tag
            top = {label=label, xarg=xml.parseargs(xarg)}
            table.insert(stack, top)   -- new level
        else  -- end tag
            local toclose = table.remove(stack)  -- remove top
            top = stack[#stack]
            assert(not( #stack < 1), "nothing to close with "..label)
            assert(not( toclose.label ~= label),"trying to close "..toclose.label.." with "..label)
            table.insert(top, toclose)
        end
        i = j+1
    end
    local text = string.sub(s, i)
    if not string.find(text, "^%s*$") then
        table.insert(stack[#stack], text)
    end
    assert(not (#stack > 1), "unclosed "..(stack[#stack].label or "shit"))
    return stack[1]
end

return xml