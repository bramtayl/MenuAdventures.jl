"""
    MenuAdventures.Parts

A sub-module that allows things to be part of other things.

```jldoctest
julia> using MenuAdventures

julia> using MenuAdventures.Testing

julia> using MenuAdventures.Parts

julia> import MenuAdventures: ever_possible

julia> @universe struct Universe <: AbstractUniverse
        end;

julia> @noun struct Room <: AbstractRoom
            already_lit::Bool = true
        end;

julia> @noun struct Person <: Noun
        end;

julia> @noun struct StickyThing <: Noun
        end;

julia> ever_possible(::Take, ::Reachable, ::StickyThing) = true;

julia> ever_possible(::Attach, ::Inventory, ::StickyThing) = true;

julia> cd(joinpath(pkgdir(MenuAdventures), "test", "Parts")) do
            check_choices() do interface
                you = Person(
                    "Brandon",
                    grammatical_person = second_person,
                    indefinite_article = "",
                )
                room = Room("room")
                universe = Universe(you, interface = interface)
                universe[room, you] = Containing()
                universe[room, StickyThing("sticky thing")] = Containing()
                universe
            end
        end
true
```
"""
module Parts

using MenuAdventures: Action, get_object, Inventory, Reachable, Relationship, Sentence, Verb
import MenuAdventures: argument_domains, ever_possible, possible_now, print_sentence, string_relationship_to, verb_for

"""
    Incorporating()

A is `Incorporating` B means B is part of A.

A [`Relationship`](@ref)
"""
struct Incorporating <: Relationship end
export Incorporating

verb_for(::Incorporating) = Verb("incorporate")

function string_relationship_to(thing_answer, ::Incorporating, parent_thing)
    buffer = IOBuffer()
    print(buffer, thing_answer.text)
    print(buffer, ' ')
    print(buffer, "attached to ")
    show(IOContext(buffer, :is_subject => false, :subject => get_object(thing_answer)), parent_thing)
    String(take!(buffer))
end

"""
    Attach()

`Attach` something from your [`Inventory`](@ref) to something else [`Reachable`](@ref).

An [`Action`](@ref). 
By default, `ever_possible(::Attach, ::Reachable, _) = true`, that is, you can attach something sticky to anything.
"""
struct Attach <: Action end

export Attach

ever_possible(::Attach, ::Reachable, _) = true

function possible_now(_, sentence::Sentence{Attach}, domain::Reachable, thing)
    ever_possible(sentence.action, domain, thing) &&
    # can't attach something to itself
    sentence.argument_answers[1].object !== thing
end

function argument_domains(::Attach)
    Inventory(), Reachable()
end

function (::Attach)(universe, thing, parent_thing)
    universe[parent_thing, thing] = Incorporating()
    return false
end

function print_sentence(io, ::Attach, thing_answer, parent_thing_answer)
    print(io, "Attach ")
    print(io, thing_answer.text)
    print(io, " to ")
    print(io, parent_thing_answer.text)
end

end