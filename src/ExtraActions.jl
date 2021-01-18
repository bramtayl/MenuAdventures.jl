"""
    MenuAdventures.ExtraActions

A sub-module with miscellaneous extra actions.

```jldoctest
julia> using MenuAdventures

julia> using MenuAdventures.Testing

julia> using MenuAdventures.ExtraActions

julia> import MenuAdventures: ever_possible, is_shining

julia> @universe struct Universe <: AbstractUniverse
        end;

julia> @noun struct Room <: AbstractRoom
            already_lit::Bool = true
        end;

julia> @noun struct Person <: Noun
        end;

julia> ever_possible(::Give, ::Reachable, ::Person) = true;

julia> @noun struct Food <: Noun
        end;

julia> ever_possible(::Eat, ::Reachable, ::Food) = true;

julia> @noun mutable struct Lamp <: Noun
            on::Bool = false
        end;

julia> ever_possible(::Take, ::Reachable, ::Lamp) = true;

julia> ever_possible(::TurnOnOrOff, ::Reachable, ::Lamp) = true;

julia> is_shining(thing::Lamp) = thing.on;

julia> @noun struct Anvil <: Noun
        end;

julia> ever_possible(::PushBetweenRooms, ::Immediate, ::Anvil) = true;

julia> cd(joinpath(pkgdir(MenuAdventures), "test", "ExtraActions")) do
            check_choices() do interface
                you = Person(
                    "Brandon",
                    grammatical_person = second_person,
                    indefinite_article = "",
                )
                light_room = Room("light room")
                dark_room = Room("dark room", already_lit = false)
                universe = Universe(you, interface = interface)
                universe[light_room, dark_room] = North()
                universe[light_room, you] = Containing()
                universe[light_room, Person("your friend", indefinite_article = "")] = Containing()
                universe[light_room, Lamp("lamp")] = Containing()
                universe[light_room, Lamp("other lamp")] = Containing()
                universe[light_room, Food("food", indefinite_article = "some")] = Containing()
                universe[light_room, Anvil("anvil")] = Containing()
                universe
            end
        end
true
```
"""
module ExtraActions

using MenuAdventures: Action, Carrying, Containing, ExitDirections, get_final_destination, get_first_destination, get_parent, Go, Immediate, Inventory, is_closable_and_closed, Noun, PutInto, Reachable, Sentence
import MenuAdventures: argument_domains, ever_possible, mention_status, possible_now, print_sentence

"""
    Eat()

`Eat` something [`Reachable`](@ref).

An [`Action`](@ref).
"""
struct Eat <: Action end

export Eat

function argument_domains(::Eat)
    (Reachable(),)
end

function (::Eat)(universe, thing)
    delete!(universe.relationships_graph, get_parent(universe, thing), thing)
    return false
end

function print_sentence(io, ::Eat, thing_answer)
    print(io, "Eat ")
    print(io, thing_answer.text)
end

"""
    Give()

`Give` something from your [`Inventory`](@ref) to someone [`Reachable`](@ref).

An [`Action`](@ref). By default, `ever_possible(::Give, ::Inventory, _) = true`,
that is, you can give someone anything in your inventory.
"""
struct Give <: Action end

export Give

function argument_domains(::Give)
    Inventory(), Reachable()
end

ever_possible(::Give, ::Inventory, _) = true

# you can't give yourself something you are already carrying
function possible_now(universe, sentence::Sentence{Give}, domain::Reachable, thing)
    ever_possible(sentence.action, domain, thing) && thing !== universe.player
end

function (::Give)(universe, thing, parent_thing)
    universe[parent_thing, thing] = Carrying()
    return false
end

function print_sentence(io, ::Give, thing_answer, parent_thing_answer)
    print(io, "Give ")
    print(io, thing_answer.text)
    print(io, " to ")
    print(io, parent_thing_answer.text)
end

"""
    PushBetweenRooms()

Push something [`Immediate`](@ref) in one of [`ExitDirections`](@ref).

An [`Action`](@ref).
"""
struct PushBetweenRooms <: Action end

export PushBetweenRooms

function argument_domains(::PushBetweenRooms)
    Immediate(), ExitDirections()
end

# can push in any direction
ever_possible(::PushBetweenRooms, ::ExitDirections, _) = true

function possible_now(universe, ::Sentence{PushBetweenRooms}, ::ExitDirections, direction)
    !(is_closable_and_closed(get_first_destination(universe, direction)))
end

function (::PushBetweenRooms)(universe, thing, direction)
    universe[get_final_destination(universe, direction), thing] = Containing()
    Go()(universe, direction)
end

function print_sentence(io, ::PushBetweenRooms, thing_answer, direction_answer)
    print(io, "Push ")
    print(io, thing_answer.text)
    print(io, ' ')
    print(io, direction_answer.text)
end

"""
    TurnOnOrOff()

Turn on or off something [`Reachable`](@ref).

An [`Action`](@ref).
"""
struct TurnOnOrOff <: Action end

export TurnOnOrOff

function mention_status(buffer, action::TurnOnOrOff, thing)
    if ever_possible(action, Reachable(), thing)
        if thing.on
            print(buffer, " (on)")
        else
            print(buffer, " (off)")
        end
    end
end

function argument_domains(::TurnOnOrOff)
    (Reachable(),)
end

function (::TurnOnOrOff)(_, thing)
    thing.on = !(thing.on)
    return false
end

function print_sentence(io, ::TurnOnOrOff, thing_answer)
    object = thing_answer.object
    print(io, "Turn ")
    if object isa Noun
        if object.on
            print(io, "off ")
        else
            print(io, "on ")
        end
    else
        print(io, "on or off ")
    end
    print(io, thing_answer.text)
end

end