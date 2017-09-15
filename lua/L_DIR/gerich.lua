module("gerich",package.seeall)

local old_print=print
function print(...)
    io.write(arg[1].."\n")
    --print(unpack(args))
end

function echo(t)
    if t==nil then t=_G end
    if type(t)=="table" then
        local s=""
        local n
        local ty
        local v
        for n in pairs(t) do
            v=t[n]
            ty=type(v)
            s=tostring(n).." : "..ty
            if ty=="string" then
                s = s.." = \""..v.."\""
            elseif ty=="number" or ty=="boolean" then
                s = s.." = "..tostring(v)
            end
            print(s)
        end
    else
        local mt = getmetatable(t)
        if mt then
            echoTable(mt)
        else
            print("Type of t is "..type(t))
        end
    end
end

function deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function string:split(delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end