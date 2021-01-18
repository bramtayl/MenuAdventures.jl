using MenuAdventures
using Documenter: deploydocs, makedocs

makedocs(
    sitename = "MenuAdventures.jl", 
    modules = [MenuAdventures],
    doctest = false,
    pages = [
        "Exports" => "index.md",
        "Internals" => "internals.md",
        "ExtraDirections" => "ExtraDirections.md"
    ]
)
deploydocs(repo = "github.com/bramtayl/MenuAdventures.jl.git")
