module("gerich.class", package.seeall)

local gerich=require"gerich"

function class( baseClass )
    if baseClass then
        if type(baseClass) ~= "table" then
            error("Wrong parent of class")
        end
    end
    
    local new_class_stub = {}
    local new_class = {}
    local constructor
    local class_mt = {  __index = new_class  }
    
    function new_class_stub:new(...)
        local newinst
        if baseClass then
            if baseClass.new then
                newinst=baseClass:new(unpack(arg))
            else
                newinst=baseClass
            end
        else
            newinst={}
        end
        setmetatable( newinst, class_mt )
        if constructor then
            constructor(newinst,unpack(arg))
        end
        return newinst
    end

    function new_class:class()
        return new_class
    end
    
    function new_class:isa( theClass )
        local b_isa = false

        local cur_class = new_class

        while ( cur_class ~= nil ) and ( not b_isa ) do
            if cur_class == theClass then
                b_isa = true
            else
                if cur_class.superClass then
                    if type(cur_class.superClass)=="function" then
                        cur_class = cur_class:superClass()
                    end
                end
            end
        end

        return b_isa
    end

    function new_class:superClass()
        return baseClass
    end

    local new_class_mt ={ __newindex = 
                        function(table,key,value)
                            if key=="new" then
                                constructor=value
                            else
                                new_class_stub[key]=value;
                            end
                        end,
                        __index = 
                        function(table,key)
                            local h= new_class_stub[key]
                            if h then
                                return h
                            else
                                if baseClass then
                                    return baseClass[key]
                                end
                            end
                        end
                        }
    
    setmetatable(  new_class, new_class_mt  )

    return new_class
end

function new(class,...)
    return class:new(unpack(arg))
end

function lib()
    return class,new
end