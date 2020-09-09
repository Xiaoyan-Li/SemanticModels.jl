# -*- coding: utf-8 -*-
using Catlab
using ModelingToolkit
import ModelingToolkit: Constant
using Test
using Petri
using SemanticModels.PetriModels

using Catlab.WiringDiagrams
using Catlab.Doctrines
import Catlab.Doctrines.⊗
import Catlab.Graphics: to_graphviz, to_tikz
import Catlab.Graphics.Graphviz: run_graphviz
⊗(a::WiringDiagram, b::WiringDiagram) = otimes(a,b)
import Base: ∘
∘(a::WiringDiagram, b::WiringDiagram) = compose(b, a)
⊚(a,b) = b ∘ a

# Generators
S, E, I, R, D = Ob(FreeSymmetricMonoidalCategory, :S, :E, :I, :R, :D)

# +
infecting = Hom(:infection, S ⊗ I, I⊗I)

# -
# +
inf  = to_wiring_diagram(infecting)
expo = to_wiring_diagram(Hom(:exposure, S⊗I, E⊗I))
rec  = to_wiring_diagram(Hom(:recovery, I,   R))
wan  = to_wiring_diagram(Hom(:waning,   R,   S))

# -
# +
si    = to_wiring_diagram(Hom(:infection,   S⊗I, I⊗I))
se    = to_wiring_diagram(Hom(:exposure,    S⊗I, E⊗I))
prog  = to_wiring_diagram(Hom(:progression, E,   I))
fatal = to_wiring_diagram(Hom(:die,  I, D))
rip   = to_wiring_diagram(Hom(:rest, D, D))

sir    = si    ⊚ (rec   ⊗ rec)
seir   = se    ⊚ (prog  ⊗ rec)
seirs  = seir  ⊚ (wan   ⊗ wan)
seird  = seir  ⊚ (fatal ⊗ to_wiring_diagram(Hom(:id, R, R)))
seirds = seird ⊚ (rip   ⊗ wan)


model(PetriModel, sir)


models = [sir, seir, seirs, seird, seirds]
nets   = model.(PetriModel, models)

modelnames = ["sir",
         "seir",
         "seirs",
         "seird",
         "seirds",
         ]
map(zip(nets, modelnames)) do (net, name)
    Δ = reverse(net.model.Δ)
    println("Model: $name\n  Connections:")
    println("    $Δ\n")
    Δ
end

function writesvg(f::Union{IO,AbstractString}, d::WiringDiagram)
    write(f, to_graphviz(d, labels=true)
          |>g->run_graphviz(g, format="svg")
          )
end

writesvg(x) = writesvg(x...)


try
    mkpath("img")
    writesvg.(zip(["img/$f.svg"
                   for f in modelnames],
                  models))
catch e
    error("Could not write images, does ./img exist?\n $e")
end
println("Model Drawings are in ./img")
