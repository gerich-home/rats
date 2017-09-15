module("gerich.ratneuro", package.seeall)
if gerich==nil then
    local gerich=require"gerich"
end
if gerich.class==nil then
    gerich.class=require"gerich.class"
end
if gerich.neuro==nil then
    gerich.neuro=require"gerich.neuro"
end

local class,new=gerich.class.lib()
local Synapse,Neuron,NeuroNet,DNK,Genetic=gerich.neuro.lib()

local rnd=math.random
local min=math.min
local max=math.max
local sqrt=math.sqrt
local sin=math.sin
local cos=math.cos
------------------------------------------------------
--RatDNK
RatDNK=class(DNK)
RatDNK.keys={}

function RatDNK.key(i,j)
    local ki=RatDNK.keys[i]
    local kij
    if ki then
        kij=ki[j]
        if kij then
            return kij
        else
            local newkey={i,j}
            ki[j]=newkey
            return newkey
        end
    else
        ki={}
        local newkey={i,j}
        ki[j]=newkey
        RatDNK.keys[i]=ki
        return newkey
    end
end

function RatDNK:new(num_neurons,num_inputs,neuronvalue_mutate_factor,bias_mutate_factor,weight_mutate_factor,blx_alpha,parents)
    self.ngens={}           --Гены нейронов
    self.sgens={}           --Гены синапсов
    self.blx_alpha=blx_alpha or 0.5
    self.parents=parents
    num_neurons=num_neurons or 0
    self.num_neurons=num_neurons
    num_inputs=num_inputs or 0
    self.num_inputs=num_inputs
    self.bias_mutate_factor=bias_mutate_factor or 0
    self.neuronvalue_mutate_factor=neuronvalue_mutate_factor or 0
    self.weight_mutate_factor=weight_mutate_factor or 0
    
    local i
    
    local ngens=self.ngens
    local n
    for i=1,num_neurons do
        n={}
        n.bias=0
        n.value=0
        n.is_input=i<=num_inputs
        ngens[i]=n
    end
end

function RatDNK:generate(num_synapses,weight_range,neuronvalue_range,bias_range)
    local i
    
    local weight_min,weight_max=0,0
    if weight_range then
        weight_min,weight_max=weight_range[1] or 0, weight_range[2] or 0
    end
    local weight_min_max=weight_max-weight_min
    
    local bias_min,bias_max=0,0
    if bias_range then
        bias_min,bias_max=bias_range[1] or 0, bias_range[2] or 0
    end
    local bias_min_max=bias_max-bias_min
    
    local neuronvalue_min,neuronvalue_max=0,0
    if neuronvalue_range then
        neuronvalue_min,neuronvalue_max=neuronvalue_range[1] or 0, neuronvalue_range[2] or 0
    end
    local neuronvalue_min_max=neuronvalue_max-neuronvalue_min
    
    local ngens=self.ngens
    local num_neurons=self.num_neurons
    local n
    for i=1,num_neurons do
        n=ngens[i]
        if not n.is_input then
            n.bias=rnd()*bias_min_max+bias_min
            n.value=rnd()*neuronvalue_min_max+neuronvalue_min
        end
    end
    
    local sgens=self.sgens
    num_synapses=min(num_synapses,num_neurons*num_neurons)
    local ni1,ni2
    local n2
    local s
    local b
    local key
    
    for i=1,num_synapses do
        repeat
            ni1=rnd(num_neurons)
            repeat
                ni2=rnd(num_neurons)
                n2=ngens[ni2]
            until not n2.is_input
            
            key=RatDNK.key(ni1,ni2)
            s=sgens[key]
            
            b=not s
            if b then
                sgens[key]=rnd()*weight_min_max+weight_min
            end
        until b
    end
end

function RatDNK:mutate()
    local ngens=self.ngens
    local sgens=self.sgens
    local num_neurons=self.num_neurons
    local weight_mutate_factor=self.weight_mutate_factor
    local bias_mutate_factor=self.bias_mutate_factor
    local neuronvalue_mutate_factor=self.neuronvalue_mutate_factor
    local mode=rnd(3)
    if mode==1 then
        local n
        repeat
            n=ngens[rnd(num_neurons)]
        until not n.is_input
        n.bias=n.bias+(rnd()-0.5)*bias_mutate_factor
    elseif mode==2 then
        local n
        repeat
            n=ngens[rnd(num_neurons)]
        until not n.is_input
        n.value=n.value+(rnd()-0.5)*neuronvalue_mutate_factor
    else
        local ni1,ni2
        local n2
        local s
        local skeysn=self.skeysn
        local skeys=self.skeys
        
        ni1=rnd(num_neurons)
        repeat
            ni2=rnd(num_neurons)
            n2=ngens[ni2]
        until not n2.is_input
        
        key=RatDNK.key(ni1,ni2)
        s=sgens[key] or 0
        sgens[key]=s+(rnd()-0.5)*weight_mutate_factor
    end
end

function RatDNK:crossover(dnk)
    
    local weight_mutate_factor=self.weight_mutate_factor
    local bias_mutate_factor=self.bias_mutate_factor
    local neuronvalue_mutate_factor=self.neuronvalue_mutate_factor
    local blx_alpha=self.blx_alpha
    
    local newdnk=RatDNK:new(self.num_neurons,self.num_inputs,neuronvalue_mutate_factor,bias_mutate_factor,weight_mutate_factor,blx_alpha,{self,dnk})
    local new_ngens=newdnk.ngens
    local ngens1=self.ngens
    local ngens2=dnk.ngens
    
    local c1,c2
    local cmin,cmax,l
    local blx_alpha_21=2*blx_alpha+1
    
    local k
    local n
    local newn
    
    for k,n in pairs(ngens1) do
        newn={}
        c1,c2=n.bias,ngens2[k].bias
        cmin,cmax=min(c1,c2),max(c1,c2)
        l=cmax-cmin
        newn.is_input=n.is_input
        newn.bias=l*(rnd()*blx_alpha_21-blx_alpha)+cmin
        
        c1,c2=n.value,ngens2[k].value
        cmin,cmax=min(c1,c2),max(c1,c2)
        l=cmax-cmin
        newn.is_input=n.is_input
        newn.value=l*(rnd()*blx_alpha_21-blx_alpha)+cmin
        
        new_ngens[k]=newn
    end
    
    
    local new_sgens=newdnk.sgens
    local sgens1=self.sgens
    local sgens2=dnk.sgens
    local s
    
    for k,n in pairs(sgens1) do
        s=sgens2[k]
        if s then
            cmin,cmax=min(n,s),max(n,s)
            l=cmax-cmin
            new_sgens[k]=l*(rnd()*blx_alpha_21-blx_alpha)+cmin
        else
            c1,c2=n,0
            cmin,cmax=min(n,0),max(n,0)
            l=cmax-cmin
            new_sgens[k]=l*(rnd()*blx_alpha_21-blx_alpha)+cmin
        end
    end
    
    for k,n in pairs(sgens2) do
        if not sgens1[k] then
            cmin,cmax=min(n,0),max(n,0)
            l=cmax-cmin
            new_sgens[k]=l*(rnd()*blx_alpha_21-blx_alpha)+cmin
        end
    end
    
    newdnk.ngens=new_ngens
    newdnk.sgens=new_sgens
    
    return newdnk
end

function RatDNK:print()
    local k,v
    print("==DNK structure:")
    print("=Biases")
    for k,v in pairs(self.ngens) do
        print(k..": "..v.bias..", "..v.value)
    end
    print("=Weights")
    for k,v in pairs(self.sgens) do
        print(k[1].."->"..k[2]..": "..v)
    end
    print("==")
end

function RatDNK:print_code()
    local k,v
    print("----------------------------")
    for k,v in pairs(self.ngens) do
        print("neurons["..k.."] = Neuron:new("..v.value..", "..v.bias..")")
    end
    print("")
    for k,v in pairs(self.sgens) do
        print("Synapse:new(neurons["..k[1].."],neurons["..k[2].."],"..v..")")
    end
    print("----------------------------")
end

function RatDNK:description()
    local k,v
    local sgens_description={}
    local i=1
    local res={}
    for k,v in pairs(self.sgens) do
        sgens_description[i]={k[1],k[2],v}
        i=i+1
    end
    res.ngens=self.ngens
    res.sgens=sgens_description
    return res
end

-----------------------------------
--RatNN
RatNN=class(NeuroNet)

function RatNN:input()
    local neurons=self.neurons
    local circle=self.circle

    local ax,ay=self.x-circle.x,self.y-circle.y
    local p,q=ax*self.vy-ay*self.vx,-(ax*self.vx+ay*self.vy)
    local d=circle.r2-p*p

    if d>0 then
        d=sqrt(d)
        d=min(q-d,q+d)
        if d>0 then
            neurons[1].value=1000/d
            neurons[2].value=1
        else
            neurons[1].value=0
            neurons[2].value=0
        end
    else
        neurons[1].value=0
        neurons[2].value=0
    end

    neurons[3].value=self.speed*self.max_speed_inv
    neurons[4].value=self.w*self.max_wspeed_inv
end

function RatNN:output()
    local neurons=self.neurons
    local dt=self.dt
    local w=self.w
    local speed=self.speed
    
    speed=max(min(speed+dt*neurons[5].value*self.max_accel,self.max_speed),0)
    w=max(min(w+dt*neurons[6].value*self.max_waccel,self.max_wspeed),-self.max_wspeed)

    local wdt=w*dt
    local speeddt=speed*dt
    local cosw,sinw=cos(wdt),sin(wdt)
    self.vx,self.vy=self.vx*cosw-self.vy*sinw,self.vx*sinw+self.vy*cosw
    self.x=self.x+self.vx*speeddt
    self.y=self.y+self.vy*speeddt
    
    self.w=w
    self.speed=speed
    
    local circle=self.circle
    local dx,dy=circle.x-self.x,circle.y-self.y
    local d=dx*dx+dy*dy
    self.min_d=min(d,self.min_d)
end

-----------------------------------------------------------
--RatGenetic
RatGenetic=class(Genetic)

function RatGenetic:new(size,mutate_p,crossover_p,best_size,max_accel,max_waccel,max_speed,max_wspeed,maxtime,dt,numtests,radius_range,scale_range)
    self.max_speed=max_speed or 1.57
    self.max_speed_inv=1.57/self.max_speed
    self.max_wspeed=max_wspeed or 0.2
    self.max_wspeed_inv=1.57/self.max_wspeed
    self.max_accel=max_accel/1.57
    self.max_waccel=max_waccel/1.57
    self.dt=dt or 0.1
    self.maxtime=maxtime or 600
    self.numtests=numtests or 4
    self.radius_range=radius_range or {10,20}
    self.scale_range=scale_range or {30,70}
    self.counter=0
end

function RatGenetic:input()
    local circles={}
    local numtests=self.numtests
    local minr,maxr=self.radius_range[1],self.radius_range[2]
    local minscale,maxscale=self.scale_range[1],self.scale_range[2]
    local diapr=maxr-minr
    local diapscale=maxscale-minscale
    local i
    local c
    local ang
    local scale
  
    for i=1,numtests do
        local c={}
        local ang=math.random()*6.28
        local scale=rnd()*diapscale+minscale
        c.r=rnd()*diapr+minr
        c.x,c.y=scale*cos(ang),scale*sin(ang)
        c.r2=c.r*c.r
        circles[i]=c
    end
    self.circles=circles
    
    self.best_ratdnk=nil
    self.best_score=10000000
    self.rats=0
    self.winners=0
    self.counter=self.counter+1
    print("==========================")
    print("Generation "..self.counter)
    
    local decades=math.floor(0.1*self.size)
    for i=1,decades do
        io.write("_")
    end
    print("")
    io.flush()
end

function RatGenetic:fitness(ind)
    local i,t
    local neurons={}
    local rat=RatNN:new()
    local dnk=self.population[ind]
    local n,k
    
    for k,n in pairs(dnk.ngens) do
        neurons[k]=Neuron:new(n.value,n.bias)
    end
    
    for k,n in pairs(dnk.sgens) do
        Synapse:new(neurons[k[1]],neurons[k[2]],n)
    end
  
    rat.neurons=neurons
    rat.max_speed=self.max_speed
    rat.max_wspeed=self.max_wspeed
    rat.max_speed_inv=self.max_speed_inv
    rat.max_wspeed_inv=self.max_wspeed_inv
    rat.max_accel=self.max_accel
    rat.max_waccel=self.max_waccel
    
    self.rats=self.rats+1
    
    local circles=self.circles
    local numtests=self.numtests
    local maxtime=self.maxtime
    local score=0
    local circle
    local winner
    for i=1,numtests do
        circle=circles[i]
        rat.circle=circle
        rat.min_d=100000000
        rat.x=0
        rat.y=0
        rat.vx=1
        rat.vy=0
        rat.speed=0
        rat.w=0
        rat.dt=self.dt
        for k,n in pairs(dnk.ngens) do
            neurons[k].value=n.value
        end
        winner=false
        for t=1,maxtime do
            rat:step()
            if rat.min_d<circle.r2 then
                score=score+t
                winner=true
                self.winners=self.winners+1
                break
            end
        end
        if not winner then
            local dx,dy=circle.x-rat.x,circle.y-rat.y
            local d=sqrt(dx*dx+dy*dy)
            score=score+maxtime*(1+d)
        end
    end
    if self.rats % 10==0 then
        io.write("|")
    end
    io.flush()
    if score<self.best_score then
        self.best_score=score
        self.best_ratdnk=dnk
    end
    return score
end

function RatGenetic:output()
    print("\n----")
    print("Winners: "..self.winners)
    print("Best score: "..self.best_score)
    --print("Best rat code:")
    --self.best_ratdnk:print_code()
    io.flush()
end

------------------------------------------------------
function lib()
    return RatDNK,RatGenetic,RatNN
end