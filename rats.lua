require "lanes"
local linda= lanes.linda()

function genetic_loop()
    require"gerich.ratneuro"
    RatDNK,RatGenetic,RatNN=gerich.ratneuro.lib()
    require"gerich"
    
    --size,mutate_p,crossover_p,best_size,
    --max_accel,max_waccel,max_speed,max_wspeed,
    --maxtime,dt,numtests,
    --radius_range,scale_range
    rg=RatGenetic:new(
       700,0.007,0.8,80,
       0.3,0.09,4,0.3,
       900,0.3,5,
       {5,20},{30,100})
    rg:first_population(
                    function ()
                        --num_neurons,num_inputs,neuronvalue_mutate_factor,bias_mutate_factor,weight_mutate_factor,blx_alpha,parents
                        local newrat=RatDNK:new(10,4,0.1,0.2,0.1)
                        --num_synapses,weight_range,neuronvalue_range,bias_range
                        newrat:generate(46,{-3,3},{-1.57,1.57},{-1,1})
                        return newrat
                    end)
    local best
    while true do
        rg:step()
        best=rg.best_ratdnk:description()
        best.max_speed=rg.max_speed
        best.max_wspeed=rg.max_wspeed
        best.max_speed_inv=rg.max_speed_inv
        best.max_wspeed_inv=rg.max_wspeed_inv
        best.max_accel=rg.max_accel
        best.max_waccel=rg.max_waccel
        best.maxtime=rg.maxtime
        best.dt=rg.dt
        best.radius_range=rg.radius_range
        best.scale_range=rg.scale_range
        linda:send("best",best)
    end
end

function wx_loop()
    -- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
    package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
    require("wx")

    require"gerich"
    require"gerich.neuro"
    require"gerich.ratneuro"

    local Synapse,Neuron,NeuroNet,DNK,Genetic=gerich.neuro.lib()
    
    local RatDNK,RatGenetic,RatNN=gerich.ratneuro.lib()
    local print=gerich.print
    
    local rnd=math.random
    local min=math.min
    local max=math.max
    local sqrt=math.sqrt
    local sin=math.sin
    local cos=math.cos

    local frame = nil
    local best
    local all_best={}
    local all_best_count=0
    local all_best_pntr=0
    local path
    local circle
    
    local window_scale=2
    local window_sizex=600
    local window_sizey=600
    local window_halfsizex=0.5*window_sizex
    local window_halfsizey=0.5*window_sizey

    local function test(x,y)
        local t
        local neurons={}
        local rat=RatNN:new()
        local n,k

        for k,n in pairs(best.ngens) do
            neurons[k]=Neuron:new(n.value,n.bias)
        end

        for k,n in pairs(best.sgens) do
            Synapse:new(neurons[n[1]],neurons[n[2]],n[3])
        end

        rat.neurons=neurons
        rat.max_speed=best.max_speed
        rat.max_wspeed=best.max_wspeed
        rat.max_speed_inv=best.max_speed_inv
        rat.max_wspeed_inv=best.max_wspeed_inv
        rat.max_accel=best.max_accel
        rat.max_waccel=best.max_waccel

        local maxtime=best.maxtime
        local ang
        local scale

        local minr,maxr=best.radius_range[1],best.radius_range[2]
        local minscale,maxscale=best.scale_range[1],best.scale_range[2]
        local diapr=maxr-minr
        local diapscale=maxscale-minscale

        local ang=math.random()*6.28
        local scale=rnd()*diapscale+minscale
        circle={}
        
        circle.x,circle.y=x or scale*cos(ang),y or scale*sin(ang)
        circle.r=rnd()*diapr+minr
        circle.r2=circle.r*circle.r

        rat.circle=circle
        rat.min_d=100000000
        rat.x=0
        rat.y=0
        rat.vx=1
        rat.vy=0
        rat.speed=0
        rat.w=0
        rat.dt=best.dt

        local p
        path={}
        path.length=maxtime
        for t=1,maxtime do
            rat:step()
            p={}
            p.x=rat.x
            p.y=rat.y
            path[t]=p
            if rat.min_d<circle.r2 then
                path.length=t
                break
            end
        end
        frame:Refresh()
    end
    
    local function get_newbest()
        local new_best
        repeat
            new_best= linda:receive( 0, "best")
            if new_best then
                all_best_count=all_best_count+1
                all_best[all_best_count]=new_best
            end
        until new_best==nil
    end
    
    local function OnKeyDown(event)
        event:Skip()
        local keycode=event:GetKeyCode()
        if keycode==wx.WXK_LEFT or keycode==wx.WXK_DOWN then
            get_newbest()
            if all_best[all_best_pntr-1] then
                all_best_pntr=all_best_pntr-1
            elseif all_best[all_best_count] then
                all_best_pntr=all_best_count
            end
            best=all_best[all_best_pntr]
            if best then
                test()
            end
        end
        if keycode==wx.WXK_RIGHT or keycode==wx.WXK_UP then
            get_newbest()
            if all_best[all_best_pntr+1] then
                all_best_pntr=all_best_pntr+1
            elseif all_best[1] then
                all_best_pntr=1
            end
            best=all_best[all_best_pntr]
            if best then
                test()
            end
        end
        if keycode==wx.WXK_F5 then
            get_newbest()
            if best then
                test()
            else
                all_best_pntr=1
                best=all_best[all_best_pntr]
                if best then
                    test()
                end
            end
        end
    end
    
    local function OnMouseDown(event)
        event:Skip()
        local x=(event:GetX()-window_halfsizex)/window_scale
        local y=(event:GetY()-window_halfsizey)/window_scale
        get_newbest()
        if best then
            test(x,y)
        else
            all_best_pntr=1
            best=all_best[1]
            if best then
                all_best_pntr=1
                test(x,y)
            end
        end
    end
    
    local function OnPaint(event)
        event:Skip()
        if path then
            local dc = wx.wxPaintDC(panel)
            dc:DrawCircle(circle.x*window_scale+window_halfsizex, circle.y*window_scale+window_halfsizey, circle.r*window_scale);
            for i=2,path.length do
                dc:DrawLine(path[i].x*window_scale+window_halfsizex,path[i].y*window_scale+window_halfsizey,path[i-1].x*window_scale+window_halfsizex,path[i-1].y*window_scale+window_halfsizey)
            end
            dc:DrawText(all_best_pntr.."/"..all_best_count,0,0)
            dc:delete()
        end
    end

    -- Create a function to encapulate the code, not necessary, but it makes it
    --  easier to debug in some cases.
    local function main()

        frame = wx.wxFrame( wx.NULL,            -- no parent for toplevel windows
                            wx.wxID_ANY,          -- don't need a wxWindow ID
                            "Rats 0.2", -- caption on the frame
                            wx.wxDefaultPosition, -- let system place the frame
                            wx.wxSize(600, 600),  -- set the size of the frame
                            wx.wxDEFAULT_FRAME_STYLE ) -- use default frame styles

        panel = wx.wxPanel(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxWANTS_CHARS)

        panel:Connect(wx.wxEVT_PAINT, OnPaint)
        panel:Connect(wx.wxEVT_KEY_DOWN, OnKeyDown)
        panel:Connect(wx.wxEVT_LEFT_DOWN , OnMouseDown)


        frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
                      function (event) frame:Close(true) end )

        frame:Show(true)
    end
    
    main()
    wx.wxGetApp():MainLoop()
end


genetic_thread=lanes.gen( "*",{priority=-1}, genetic_loop )()
wx_thread=lanes.gen( "*",{priority=1}, wx_loop )()

local locker=wx_thread[1]
if genetic_thread.status=="error" then
    local v,err= genetic_thread:join()   -- no propagation
    if v==nil then
        error( "error in genetic_thread:"..tostring(err) )   -- manual propagation
    end
end