-- lua table dump
-- @param root table 要dump的表
-- @param depthMax int dump 深度,默认3层[可选]
-- @param excludeKeys table 排除指定键且值为table的元素[可选]
-- @param excludeTypes table 排除指定的值类型元素[可选]
-- @param noAlignLine bool 是否生成对齐线,默认生成[可选]
local function _tdump(root, depthMax, excludeKeys, excludeTypes, noAlignLine)
    if type(root) ~= "table" then return root end
    depthMax = depthMax or 3
    local concat = table.concat
    local eq, bktL, bktR, bktRC, comma, empty, ellipsis, align1, align2 = " = ", "{", "}", "},", ",", "", "...", "    ", "|   "

    local cache = { [root] = "." }
    local temp = {bktL}
    local keytb1, keytb2 = {"[", "", "]"}, {"[\"", "", "\"]"}
    local function _dump(t, space, name, depth)
        local indent1, indent2 = space .. align1, space .. align2
        for k,v in pairs(t) do
            local kType, vType = type(k), type(v)
            local isLast = not next(t, k) --最后一个字段
            local endMark = isLast and empty or comma
            local tbktR = isLast and bktR or bktRC
            local keytb = kType == "string" and keytb2 or keytb1
            keytb[2] = tostring(k)
            local keyBkt = concat(keytb)

            if vType == "table" then
                if cache[v] then
                    temp[#temp+1] = concat({space, keyBkt, eq, bktL, cache[v], tbktR})
                else
                    local new_key = name .. "." .. tostring(k)
                    cache[v] = new_key .. " ->[".. tostring(v) .."]"

                    -- table 深度判断
                    if (depthMax > 0 and depth >= depthMax) or (excludeKeys and excludeKeys[k]) then
                        temp[#temp+1] = concat({space, keyBkt, eq, bktL, ellipsis, tbktR})
                    else
                        if next(v) then
                            -- 非空table
                            temp[#temp+1] = concat({space, keyBkt, eq, bktL})
                            local indent = (noAlignLine or isLast) and indent1 or indent2
                            _dump(v, indent, new_key, depth+1)
                            temp[#temp+1] = concat({space, tbktR})
                        else
                            temp[#temp+1] = concat({space, keyBkt, eq, bktL, tbktR})
                        end
                    end
                end
            else
                if not excludeTypes or not excludeTypes[vType] then
                    if vType == "string" then
                        v = '\"' .. string.gsub(v, "\"", "\\\"") .. '\"'
                    end
                    temp[#temp+1] = concat({space, keyBkt, eq, tostring(v), endMark})
                end
            end
        end
    end
    _dump(root, align1, empty, 0)
    temp[#temp+1] = bktR
    return concat(temp, "\n")
end

local _print = _G.print
local function _getcallstack(level)
    local info = debug.getinfo(level)
    if info then
        return string.format("[file]=%s,[line]=%d]: ", info.source or "?", info.currentline or 0)
    end
end

table.print = function(root, ...)
    if type(root) ~= "table" then
        _print(root)
    else
        _print(_tdump(root, ...))
    end
end

function xprint( ... )
    local t = {_getcallstack(3)}
    local args = {...}
    local argn = select("#", ...)

    for i=1,argn do
        local value = args[i]
        local ty = type(value)
        if ty == "table" then
            table.insert(t, _tdump(value))
        elseif ty == "string" then
            table.insert(t, '\"' .. value .. '\"')
        else
            table.insert(t, tostring(value))
        end
    end

    _print(table.concat(t, "\n"))
end

-- 修改默认的print，支持显示文件名和行数
local function debug_print(...)
    local prefix = _getcallstack(3)
    if prefix then
        --local tm = os.date("%Y-%m-%d %H:%M:%S", os.time())
        _print(prefix, ...)
    end
end
--print = debug_print

-- test
--[[
local cat = {
    name = "cat",
    sex = "man",
    age = 30,
    phone = {
        {type=1, number=123},
        {type=2, number=456},
    },
    temp = {}
}
local domi = {
    name = "domi",
    sex = "man",
    age = 30,
    phone = {
        {type=1, number=1230000},
        {type=2, number=3210000},
    },
    addrbooks = {cat}
}
table.insert(domi.addrbooks, domi)

--xprint(1, 2, 3, domi)
table.print(domi, -1, nil, nil, false)
--]]