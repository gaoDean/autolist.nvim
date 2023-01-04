-- https://gist.github.com/efrederickson/4080372

--[[
Symbol   Value
I        1
V        5
X        10
L        50
C        100
D        500
M        1000
If a lesser number comes before a greater number (e.g. IX), then
the lesser number is subtracted from the greater number (IX -> 9, 900 -> CM)
So,
Symbol   Value
IV       4
IX       9
XL       40
XC       90
CD       400
CM       900
LM       950
VX is actually valid as 5, along with other irregularities, such as IIIIIV for 8
Copyright (C) 2012 LoDC
]]

local map = {
    I = 1,
    V = 5,
    X = 10,
    L = 50,
    C = 100,
    D = 500,
    M = 1000,
}
local numbers = { 1, 5, 10, 50, 100, 500, 1000 }
local chars = { "I", "V", "X", "L", "C", "D", "M" }

local M = {}

function M.arabic2roman(s)
    --s = tostring(s)
    s = tonumber(s)
    if not s or s ~= s then error"Unable to convert to number" end
    if s == math.huge then error"Unable to convert infinity" end
    s = math.floor(s)
    if s <= 0 then return s end
	local ret = ""
        for i = #numbers, 1, -1 do
        local num = numbers[i]
        while s - num >= 0 and s > 0 do
            ret = ret .. chars[i]
            s = s - num
        end
        --for j = i - 1, 1, -1 do
        for j = 1, i - 1 do
            local n2 = numbers[j]
            if s - (num - n2) >= 0 and s < num and s > 0 and num - n2 ~= n2 then
                ret = ret .. chars[j] .. chars[i]
                s = s - (num - n2)
                break
            end
        end
    end
    return ret
end

function M.roman2arabic(s)
    s = s:upper()
    local ret = 0
    local i = 1
    while i <= s:len() do
    --for i = 1, s:len() do
        local c = s:sub(i, i)
        if c ~= " " then -- allow spaces
            local m = map[c] or error("Unknown Roman Numeral '" .. c .. "'")

            local next = s:sub(i + 1, i + 1)
            local nextm = map[next]

            if next and nextm then
                if nextm > m then
                -- if string[i] < string[i + 1] then result += string[i + 1] - string[i]
                -- This is used instead of programming in IV = 4, IX = 9, etc, because it is
                -- more flexible and possibly more efficient
                    ret = ret + (nextm - m)
                    i = i + 1
                else
                    ret = ret + m
                end
            else
                ret = ret + m
            end
        end
        i = i + 1
    end
    return ret
end

function M.roman_add(roman, arabic_amount)
	return M.arabic2roman(M.roman2arabic(roman) + arabic_amount)
end

return M
