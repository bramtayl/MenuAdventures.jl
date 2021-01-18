"""
    MenuAdventures.Outfits

A sub-module that enables the player to wear clothes.

```jldoctest
julia> using MenuAdventures

julia> using MenuAdventures.Testing

julia> using MenuAdventures.Outfits

julia> import MenuAdventures: ever_possible

julia> @universe struct Universe <: AbstractUniverse
        end;

julia> @noun struct Room <: AbstractRoom
            already_lit::Bool = true
        end;

julia> @noun struct Person <: Noun
        end;

julia> @noun struct Clothes <: Noun
        end;

julia> ever_possible(::Dress, ::Inventory, ::Clothes) = true;

julia> ever_possible(::Take, ::Reachable, ::Clothes) = true;

julia> ever_possible(::Dress, ::Reachable, ::Person) = true;

julia> cd(joinpath(pkgdir(MenuAdventures), "test", "Outfits")) do
            check_choices() do interface
                you = Person(
                    "Brandon",
                    grammatical_person = second_person,
                    indefinite_article = "",
                )
                room = Room("room")
                coat = Clothes("coat")
                universe = Universe(you, interface = interface)
                universe[room, you] = Containing()
                universe[room, Clothes("coat")] = Containing()
                universe
            end
        end
true
```
"""
module Outfits

using MenuAdventures: Action, BE, get_parent, Inventory, Location, Reachable, Relationship, Sentence, subject_to_verb, Verb
import MenuAdventures: argument_domains, print_sentence, string_relationship_to, verb_for

"""
    Wearing()

A is `Wearing` B means B is worn by A.

A [`Relationship`](@ref)
"""
struct Wearing <: Relationship end
export Wearing

verb_for(::Wearing) = Verb("wear")

function string_relationship_to(thing_answer, ::Wearing, parent_thing)
    buffer = IOBuffer()
    print(buffer, thing_answer.text)
    print(buffer, ' ')
    print(buffer, "that ")
    show(buffer, parent_thing)
    print(buffer, ' ')
    print(buffer, subject_to_verb(parent_thing, BE))
    print(buffer, " wearing")
    String(take!(buffer))
end

"""
    Dress()

`Dress` someone [`Reachable`](@ref) in something from your [`Inventory`](@ref).

An [`Action`](@ref).
"""
struct Dress <: Action end

export Dress

function argument_domains(::Dress)
    Reachable(), Inventory()
end

function (::Dress)(universe, parent_thing, thing)
    universe[parent_thing, thing] = Wearing()
    return false
end

function print_sentence(io, ::Dress, parent_thing_answer, thing_answer)
    print(io, "Dress ")
    print(io, parent_thing_answer.text)
    print(io, " in ")
    print(io, thing_answer.text)
end

end