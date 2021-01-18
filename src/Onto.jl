"""
    MenuAdventures.Onto

A sub-module with the supporting relationship.

```jldoctest
julia> using MenuAdventures

julia> using MenuAdventures.Testing

julia> using MenuAdventures.Onto

julia> import MenuAdventures: ever_possible

julia> @universe struct Universe <: AbstractUniverse
        end;

julia> @noun struct Room <: AbstractRoom
            already_lit::Bool = true
        end;

julia> @noun struct Person <: Noun
        end;

julia> @noun struct Thing <: Noun
        end;

julia> @noun struct Table <: Noun
        end;

julia> ever_possible(::Take, ::Reachable, ::Thing) = true;

julia> ever_possible(::PutOnto, ::Reachable, ::Table) = true;

julia> ever_possible(::GoOnto, ::Immediate, ::Table) = true;

julia> cd(joinpath(pkgdir(MenuAdventures), "test", "Onto")) do
            check_choices() do interface
                you = Person(
                    "Brandon",
                    grammatical_person = second_person,
                    indefinite_article = "",
                )
                room = Room("room")
                universe = Universe(you, interface = interface)
                universe[room, you] = Containing()
                universe[room, Table("table")] = Containing()
                universe[room, Thing("thing")] = Containing()
                universe
            end
        end
true
```
"""
module Onto

using MenuAdventures: Action, get_object, get_mover, Immediate, Inventory, Reachable, Relationship, Verb
import MenuAdventures: argument_domains, ever_possible, print_sentence, string_relationship_to, verb_for

"""
    Supporting()

A is `Supporting` B means B is on top of A.

A [`Relationship`](@ref)
"""
struct Supporting <: Relationship end

export Supporting

verb_for(::Supporting) = Verb("support")

function string_relationship_to(thing_answer, ::Supporting, parent_thing)
    buffer = IOBuffer()
    print(buffer, thing_answer.text)
    print(buffer, ' ')
    print(buffer, "on ")
    show(IOContext(buffer, :is_subject => false, :subject => get_object(thing_answer)), parent_thing)
    String(take!(buffer))
end

"""
    PutOnto()

Put something from your [`Inventory`](@ref) onto something [`Reachable`](@ref).

An [`Action`](@ref).
By default, `ever_possible(::PutOnto, ::Inventory, _) = true`, that is, you can always put something
from your inventory onto a surface.
"""
struct PutOnto <: Action end

export PutOnto

ever_possible(::PutOnto, ::Inventory, _) = true

function argument_domains(::PutOnto)
    Inventory(), Reachable()
end

function (::PutOnto)(universe, thing, parent_thing)
    universe[parent_thing, thing] = Supporting()
    return false
end

function print_sentence(io, ::PutOnto, thing_answer, parent_thing_answer)
    print(io, "Put ")
    print(io, thing_answer.text)
    print(io, " onto ")
    print(io, parent_thing_answer.text)
end

"""
    GoOnto()

Go onto something [`Immediate`](@ref).

An [`Action`](@ref).
"""
struct GoOnto <: Action end

export GoOnto

function argument_domains(::GoOnto)
    (Immediate(),)
end

function (::GoOnto)(universe, place)
    PutOnto()(universe, get_mover(universe), place)
    return false
end

function print_sentence(io, ::GoOnto, place_answer)
    print(io, "Go onto ")
    print(io, place_answer.text)
end

end