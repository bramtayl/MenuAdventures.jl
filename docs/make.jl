using MenuAdventures
using Documenter: deploydocs, makedocs

makedocs(
    sitename = "MenuAdventures.jl", 
    modules = [MenuAdventures],
    doctest = false,
    pages = [
        "Exports" => "index.md",
        "Internals" => "internals.md",
        "ExtraDirections" => "ExtraDirections.md",
        "ExtraVerbs" => "ExtraVerbs.md",
        "Onto" => "Onto.md",
        "Outfits" => "Outfits.md",
        "Parts" => "Parts.md",
        "Talking" => "Talking.md",
        "Testing" => "Testing.md"
    ]
)
deploydocs(repo = "github.com/bramtayl/MenuAdventures.jl.git")
