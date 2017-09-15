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

------------------------------------------------------
--Synapse
Synapse=class()
Synapse.weight=0

function Synapse:new(inneuron,outneuron,weight)
    self.weight=weight or 1
    self.neuron=inneuron
    table_insert(outneuron.synapses,self)
end

function Synapse:out()
    return self.neuron.value*self.weight
end

------------------------------------------------------
--Neuron
Neuron=class()
Neuron.value=0
Neuron.newvalue=0

function Neuron:new(value,bias)
    self.value=value or 0
    self.bias=bias or 0
    self.newvalue=0
    self.synapses={}
end

function Neuron:flush()
    self.value=self.newvalue
end

function Neuron:update()
    local k,v
    local w=self.bias
    for k,v in pairs(self.synapses) do
        w=w+v:out()
    end
    self.newvalue=self:activation(w)
end

function Neuron:activation(value)
    return atan(value)
end


------------------------------------------------------
--NeuroNet
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



------------------------------------------------------
--DNK
DNK=class()

function DNK:new()
end

function DNK:generate()
end

function DNK:mutate(mutate_factor)
end

function DNK:crossover(dnk)
end

function DNK:fitness()
end

------------------------------------------------------
--Genetic
Genetic=class()

function Genetic:new(size,mutate_p,crossover_p,best_size)
    self.size=size or 0
    self.best_size=best_size or self.size
    self.crossover_p=crossover_p or 0.5
    if self.size>0 then
        self.mutate_p=(mutate_p or 0)/self.size
    else
        self.mutate_p=0
    end
    self.population={}
end

function Genetic:first_population(creator)
    local size=self.size
    local i
    local population={}
    for i=1,size do
        population[i]=creator()
    end
    self.population=population
end

function Genetic:step()
    self:input()
    self:select_best()
    self:crossover()
    self:mutate()
    self:output()
end

function Genetic:input()
end

function Genetic:select_best()
    local population=self.population
    local fitness_value={}
    local fitness_ind={}
    local sorted={}
    local best={}
    local size=self.size
    local best_size=self.best_size
    local i,j
    local roulette_pntr
    local winner
    local roulette_slots=size*(size+1)*0.5
    for i=1,size do
        fitness_value[i]=self:fitness(i)
        fitness_ind[i]=i
    end
    local compare_func=function(a,b)
      return fitness_value[a]<fitness_value[b]
    end
    table.sort(fitness_ind,compare_func)
    for i=1,size do
        sorted[size-i]=population[fitness_ind[i]]
    end
    for i=1,best_size do
        repeat
            roulette_pntr=rnd(roulette_slots)
            for j=1,size do
                roulette_pntr=roulette_pntr-j
                if roulette_pntr<1 then
                    roulette_pntr=j
                    break
                end
            end
            winner=sorted[roulette_pntr]
        until winner~=nil
        best[i]=winner
    end
    self.best=best
end

function Genetic:crossover()
    local population={}
    local best_size=self.best_size
    local best=self.best
    local size=self.size
    local i
    local father
    local mother
    for i=1,size do
        father=rnd(best_size)
        if rnd()>self.crossover_p then
            repeat
                mother=rnd(best_size)
            until mother~=father
            population[i]=best[father]:crossover(best[mother])
        else
            population[i]=best[father]
        end
    end
    self.population=population
end

function Genetic:mutate()
    local population=self.population
    local size=self.size
    local i
    for i=1,size do
        if rnd()<self.mutate_p then
            population[i]:mutate()
        end
    end
end

function Genetic:fitness(ind)
    return population[ind]:fitness()
end


function Genetic:output()
end

------------------------------------------------------
--GeneticElite
GeneticElite=class(Genetic)

function GeneticElite:select_best()
    local population=self.population
    local fitness_value={}
    local fitness_ind={}
    local best={}
    local size=self.size
    local best_size=self.best_size
    local i
    for i=1,size do
        fitness_value[i]=population[i]:fitness()
        fitness_ind[i]=i
    end
    local compare_func=function(a,b)
      return fitness_value[a]<fitness_value[b]
    end
    table.sort(fitness_ind,compare_func)
    for i=1,best_size do
        best[i]=population[fitness_ind[i]]
    end
    self.best=best
end

------------------------------------------------------
function lib()
    return Synapse,Neuron,NeuroNet,DNK,Genetic,GeneticElite
end