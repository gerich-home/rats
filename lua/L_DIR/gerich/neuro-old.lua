module("gerich.neuro", package.seeall)
if gerich==nil then
    local gerich=require"gerich"
end
if gerich.class==nil then
    gerich.class=require"gerich.class"
end

local class,new=gerich.class.lib()

local rnd=math.random
local atan=math.atan
local table_insert=table.insert

Link=class()
Link.weight=0
function Link:new(weight,inneuron,outneuron)
    self.weight=weight or 1
    self.neuron=inneuron
    table_insert(outneuron.links,self);
end

Neuron=class()
Neuron.value=0
Neuron.newvalue=0

function Neuron:new(value,bias)
    self.value=value or 0
    self.bias=bias or 0
    self.newvalue=0
    self.links={}
end

function Neuron:flush()
    self.value=self.newvalue
end

function Neuron:update()
    local k,v
    local w=0
    w=self.bias
    for k,v in pairs(self.links) do
        w=w+v.neuron.value*v.weight
    end
    self.newvalue=self:activation(w)
end

function Neuron:activation(value)
    return atan(value)
end


NeuroNet=class()

function NeuroNet:new(neurons)
    self.neurons=neurons or {}
end

function NeuroNet:step()
    local m,neuron
    self:input()
    for m,neuron in pairs(self.neurons) do
        neuron:update()
    end
    self:beforeflush()
    for m,neuron in pairs(self.neurons) do
        neuron:flush()
    end
    self:output()
end

function NeuroNet:input()
end

function NeuroNet:beforeflush()
end

function NeuroNet:output()
end



DNK=class()
DNK.keys={}

function DNK:new()
    self.weights={}
end

function DNK:ind(i,j)
    local ind
    local a,b,c
    if j then
        a,b=i,j
    else
        a,b=i[1],i[2]
    end
    if self.keys[a] then
      c=self.keys[a]
    else
      c={}
      self.keys[a]=c
    end
    ind=c[b]
    if ind==nil then
      ind={a,b}
      c[b]=ind
    end
    return ind
end

function DNK:set(i,j,weight)
    local w=weight or j
    local ind
    if weight then
        ind=self:ind(i,j)
    else
        ind=self:ind(i)
    end
    if w==0 then
        self.weights[ind]=nil
    else
        self.weights[ind]=w
    end
end

function DNK:get(i,j)
    if j then
        return self.weights[self:ind(i,j)] or 0
    else
        return self.weights[self:ind(i)] or 0
    end
end

function DNK:mutate(mutate_factor,size,in_neurons)
    local ind=self:ind(rnd(size-in_neurons)+in_neurons,rnd(size))
    self.weights[ind]=(self.weights[ind] or 0)+mutate_factor
end

Genetic=class()
Genetic.size=0
Genetic.best_size=0
Genetic.neuronet_size=0
Genetic.mutate_factor=0
Genetic.mutate_p=0
Genetic.in_neurons=0

function Genetic:new(size,best_size,in_neurons,neuronet_size,mutate_p,mutate_factor)
    self.population={}
    self.size=size or 0
    self.best_size=best_size or 0
    self.neuronet_size=neuronet_size or 0
    self.mutate_factor=mutate_factor or 0
    self.mutate_p=mutate_p or 0
    self.in_neurons=in_neurons or 0
end

function Genetic:start(max_weights,min,max)
    local i,j
    local n,s=self.neuronet_size,self.size
    self.population={}
    local population=self.population
    local d=max-min
    for i=1,s do
        local p=DNK:new()
        for j=1,max_weights do
            p:set(rnd(n),rnd(n-self.in_neurons)+self.in_neurons,rnd()*d+min)
        end
        population[i]=p
    end
end

function Genetic:step()
    self:input()
    local i,j,m,f1,f2
    local population=self.population
    local fitness=self.fitness
    local fitness_value={}
    local fitness_ind={}
    local n=table.getn(population)
    local s=self.neuronet_size
    local ins=self.in_neurons
    for i=1,n do
        fitness_value[i]=fitness(self,population[i])
        fitness_ind[i]=i
    end
    local compare_func=function(a,b)
      return fitness_value[a]<fitness_value[b]
    end
    table.sort(fitness_ind,compare_func)
    local best={}
    local k=self.best_size
    for i=1,k do
        best[i]=population[fitness_ind[i]]
    end
    population={}
    local crossover=self.crossover
    local p1,p2,p
    for i=1,n do
        j=rnd(k)
        m=rnd(k)
        p1=best[j]
        p2=best[m]
        f1=50+fitness_value[j]
        f2=100+f1+fitness_value[m]
        if f2~=0 then
            p=crossover(self,p1,p2,f1/f2)
        else
            p=crossover(self,p1,p2,0.5)
        end
        if rnd()<self.mutate_p then
            p:mutate((rnd()-0.5)*self.mutate_factor,s,ins)
        end
        population[i]=p
    end
    self.population=population
    self:output()
end

function Genetic:crossover(dnk1,dnk2,part)
    local p=DNK:new()
    local k,v
    local ipart=1-part
    for k,v in pairs(dnk1.weights) do
        p:set(k,v)--*part)
    end
    for k,v in pairs(dnk2.weights) do
        if p:get(k)==nil then
            p:set(k,v)--*ipart)
        else
            p:set(k,p:get(k,v)*part+v*ipart)
        end
    end
    return p
end

function Genetic:fitness(dnk)
end

function Genetic:input()
end

function Genetic:output()
end

function lib()
    return Link,Neuron,NeuroNet,DNK,Genetic
end