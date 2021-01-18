using MenuAdventures
using Documenter: deploydocs, makedocs

makedocs(
    sitename = "MenuAdventures.jl", 
    modules = [MenuAdventures],
    doctest = false,
    pages = [
        "Basic Interface" => "index.md",
        "Internals" => "internals.md",
        "ExtraDirections extension" => "ExtraDirections.md",
        "ExtraActions extension" => "ExtraActions.md",
        "Onto extension" => "Onto.md",
        "Outfits extension" => "Outfits.md",
        "Parts extension" => "Parts.md",
        "Talking extension" => "Talking.md",
        "Testing extension" => "Testing.md"
    ]
)
deploydocs(repo = "github.com/bramtayl/MenuAdventures.jl.git")
