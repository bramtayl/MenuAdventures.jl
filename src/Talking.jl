"""
    MenuAdventures.Talking

A sub-module that enables talking to other players.

```jldoctest
julia> using MenuAdventures

julia> using MenuAdventures.Testing

julia> using MenuAdventures.Talking

julia> import MenuAdventures: ever_possible

julia> @universe struct Universe <: AbstractUniverse
        end;

julia> @noun struct Room <: AbstractRoom
            already_lit::Bool = true
        end;

julia> @noun struct Person <: Noun
        end;

julia> @noun struct NPC <: Noun
            dialog::Dict{String, Answer} = Dict{String, Answer}()
        end;

julia> ever_possible(::Say, ::Visible, ::NPC) = true;

julia> cd(joinpath(pkgdir(MenuAdventures), "test", "Talking")) do
            check_choices() do interface
                you = Person(
                    "Brandon",
                    grammatical_person = second_person,
                    indefinite_article = "",
                )
                friend = NPC(
                    "your friend",
                    indefinite_article = "",
                    dialog = Dict("Hello" => Answer("Hello", (universe, person) -> nothing))
                )
                room = Room("room")
                universe = Universe(you, interface = interface)
                universe[room, you] = Containing()
                universe[room, friend] = Containing()
                universe
            end
        end
true
```
"""
module Talking

using MenuAdventures: Action, Answer, Domain, ever_possible, println_wrapped, Sentence, subject_to_verb, Verb, Visible
import MenuAdventures: argument_domains, find_in_domain, possible_now, print_sentence

"""
    Dialog()

Things a player might [`Say`](@ref).

A [`Domain`](@ref).
"""
struct Dialog <: Domain end

export Dialog

# TODO: why won't it let me use an _ for universe?
function find_in_domain(universe, sentence, ::Dialog; lit = true)
    [Answer(repr(text), text) for text in keys(sentence.argument_answers[1].object.dialog)]
end

"""
    Say()

Say, to someone [`Visible`](@ref), some [`Dialog`](@ref).

An [`Action`](@ref). 
Note the first argument is the addressee, and the second is the dialog.
If `possible(::Say, ::Dialog, addressee)`, then `addressee` must have a dialog field containing a dialog dictionary.
The keys of this dictionary should be text the player says, and the values should be [`Answer`](@ref)s containing a response from the `addressee` and a trigger.
After a dialog option is chosen, the response trigger will be called with two arguments: `universe` and `addressee`. 
Then the dialog option will be removed.
"""
struct Say <: Action end

export Say

function possible_now(_, sentence::Sentence{Say}, domain::Visible, person)
    ever_possible(sentence.action, domain, person) && !isempty(person.dialog)
end

function argument_domains(::Say)
    Visible(), Dialog()
end


const REPLY = Verb("reply"; third_person_singular_present = "replies")

function (::Say)(universe, person, text)
    interface = universe.interface
    dialog = person.dialog
    answer = dialog[text]
    delete!(dialog, text)
    buffer = IOBuffer()
    show(IOContext(buffer, :capitalize => true, :is_subject => true), person)
    print(buffer, ' ')
    print(buffer, subject_to_verb(person, REPLY))
    print(buffer, " \"")
    print(buffer, answer.text)
    print(buffer, '"')
    println_wrapped(interface, String(take!(buffer)))
    answer.object(universe, person)
    return false
end

function print_sentence(io, ::Say, person_answer, text_answer)
    print(io, "Say ")
    print(io, text_answer.text)
    print(io, " to ")
    print(io, person_answer.text)
end

end