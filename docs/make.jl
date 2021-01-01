using MenuAdventures
using Documenter: deploydocs, makedocs

makedocs(sitename = "MenuAdventures.jl", modules = [MenuAdventures], doctest = false)
deploydocs(repo = "github.com/bramtayl/MenuAdventures.jl.git")
