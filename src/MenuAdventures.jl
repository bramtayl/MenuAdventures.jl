"""
    MenuAdventures

A module for creating text adventures based on menus.

```jldoctest
julia> using MenuAdventures

julia> using MenuAdventures.Testing

julia> import MenuAdventures: ever_possible, is_transparent, is_vehicle

julia> @universe not_a_struct
ERROR: LoadError: ArgumentError: Cannot parse user struct definition
[...]

julia> @universe struct Universe <: AbstractUniverse
        end;

julia> @noun struct Room <: AbstractRoom
            already_lit::Bool = true
        end;

julia> @noun struct Person <: Noun
        end;

julia> @noun struct Key <: Noun
        end;

julia> ever_possible(::Take, ::Reachable, ::Key) = true;

julia> ever_possible(::UnlockOrLock, ::Inventory, ::Key) = true;

julia> @noun mutable struct LockableDoor <: AbstractDoor
            key::Noun
            closed::Bool = true
            locked::Bool = true
        end;

julia> ever_possible(::OpenOrClose, ::Reachable, ::LockableDoor) = true;

julia> ever_possible(::UnlockOrLock, ::Reachable, ::LockableDoor) = true;

julia> @noun mutable struct Chest <: Noun
            key::Noun
            closed::Bool = true
            locked::Bool = true
        end;

julia> ever_possible(::OpenOrClose, ::Reachable, ::Chest) = true;

julia> ever_possible(::UnlockOrLock, ::Reachable, ::Chest) = true;

julia> ever_possible(::PutInto, ::Reachable, ::Chest) = true;

julia> @noun struct Car <: Noun
        end;

julia> ever_possible(::GoInto, ::Immediate, ::Car) = true;

julia> is_transparent(::Car) = true;

julia> is_vehicle(::Car) = true;

julia> cd(joinpath(pkgdir(MenuAdventures), "test")) do
            check_choices() do interface
                you = Person(
                    "Brandon",
                    description = (universe, self) -> "What a dork!",
                    grammatical_person = second_person,
                    indefinite_article = "",
                )
                entrance = Room(
                    "the entrance",
                    description = (universe, self) -> "The entrance to the castle",
                    indefinite_article = ""
                )
                small_key = Key("small key")
                large_key = Key("large key")
                chest = Chest("chest", small_key)
                universe = Universe(
                    you,
                    introduction = "Welcome!",
                    interface = interface
                )
                universe[entrance, Room("the castle", indefinite_article = "")] = LockableDoor("door", large_key), West()
                universe[entrance, you] = Containing()
                universe[entrance, small_key] = Containing()
                universe[entrance, chest] = Containing()
                universe[chest, large_key] = Containing()
                universe[entrance, Car("car")] = Containing()
                universe
            end
        end
true
```
"""
module MenuAdventures

using Base: disable_text_style, text_colors
import Base: setindex!, show
using FunctionWrappers: FunctionWrapper
using OrderedCollections: OrderedDict
using InteractiveUtils: subtypes
using LightGraphs: DiGraph, inneighbors, outneighbors
using MacroTools: @capture
using MetaGraphsNext: code_for, label_for, MetaGraph
using REPL.Terminals: TTYTerminal
using REPL.TerminalMenus: RadioMenu, request, TerminalMenus, terminal
using TextWrap: println_wrapped

"""
    abstract type Domain end

A domain refers to a search space for a specific argument to an [`Action`](@ref).

Domains serve both as a way of distinguishing different arguments to an action, and also, categorizing the environment around the player.
For example, you are only able to look at things in the [`Visible`](@ref) domain.
To create a new domain, you must add a method for:

- [`MenuAdventures.find_in_domain`](@ref)
- [`MenuAdventures.indefinite`](@ref)
- [`MenuAdventures.interrogative`](@ref)
"""
abstract type Domain end

export Domain

"""
    ExitDirections()

Directions that a player, or the vehicle a player is in, might exit in.

A [`Domain`](@ref).
"""
struct ExitDirections <: Domain end

export ExitDirections

function indefinite(::ExitDirections)
    "some way"
end

function interrogative(::ExitDirections)
    "which way"
end

function blocking_thing_and_relationship(universe, ::ExitDirections)
    get_parent_relationship(universe, get_mover(universe))
end

function find_in_domain(universe, sentence, domain::ExitDirections; lit = true)
    blocking_thing, _ = blocking_thing_and_relationship(universe, domain)
    answers = Answer[]
    for (_, direction) in
        get_exit_directions(universe, blocking_thing)
        if possible_now(universe, sentence, domain, direction)
            push!(answers, make_answer(universe, direction))
        end
    end
    answers
end

"""
    Inventory()

Things the player is carrying.

A [`Domain`](@ref).
"""
struct Inventory <: Domain end

export Inventory

function find_in_domain(universe, sentence, domain::Inventory; lit = true)
    answers = Answer[]
    for (thing, relationship) in
        get_children_relationships(universe, universe.player)
        if relationship isa Carrying && possible_now(universe, sentence, domain, thing)
            push!(answers, make_answer(universe, thing))
        end
    end
    answers
end

"""
    Immediate()

Thing that are in/on the same place the player could move from.

A [`Domain`](@ref).
"""
struct Immediate <: Domain end

export Immediate

function find_in_domain(universe, sentence, domain::Immediate; lit = true)
    answers = Answer[]
    blocking_thing, blocked_relationship =
        blocking_thing_and_relationship(universe, ExitDirections())
    if lit
        for (thing, relationship) in
            get_children_relationships(universe, blocking_thing)
            if relationship === blocked_relationship &&
                possible_now(universe, sentence, domain, thing)
                push!(answers, make_answer(universe, thing))
            end
        end
    end
    answers
end

"""
    Reachable()

Anything the player can reach.

A [`Domain`](@ref). Players can't reach through closed containers by default.
"""
struct Reachable <: Domain end

export Reachable

function blocking(::Reachable, parent_thing, relationship, _)
    relationship isa Containing && is_closable_and_closed(parent_thing)
end

function blocking_thing_and_relationship(universe, ::Reachable)
    # you can't reach outside of the thing that you are in/on/etc.
    get_parent_relationship(universe, universe.player)
end

function find_in_domain(universe, sentence, domain::Reachable; lit = true)
    answers = Answer[]
    if lit
        add_siblings_and_doors!(answers, universe, sentence, domain, blocking_thing_and_relationship(universe, domain)...)
    else
        # you can only reach the things on your person
        for (thing, _) in
            get_children_relationships(universe, universe.player)
            add_thing_and_relations!(answers, universe, sentence, domain, thing)
        end
    end
    answers
end

"""
    Visible()

Anything the player can see.

A [`Domain`](@ref). By default, players can't see into closed, opaque containers.
"""
struct Visible <: Domain end

export Visible

function blocking(::Visible, parent_thing, relationship, thing)
    blocking(Reachable(), parent_thing, relationship, thing) &&
        !(is_transparent(parent_thing))
end

function blocking_thing_and_relationship(universe, domain::Visible)
    thing = universe.player
    blocking_thing, blocked_relationship = get_parent_relationship(universe, thing)
    # locations don't have a parent...
    while !(blocking_thing isa Location) &&
        !(blocking(domain, blocking_thing, blocked_relationship, thing))
        thing = blocking_thing
        blocking_thing, blocked_relationship = get_parent_relationship(universe, thing)
    end
    blocking_thing, blocked_relationship
end

function find_in_domain(universe, sentence, domain::Visible; lit = true)
    answers = Answer[]
    if lit
        blocking_thing, blocked_relationship = blocking_thing_and_relationship(universe, domain)
        # you can look around at the thing you are in/on
        if possible_now(universe, sentence, domain, blocking_thing)
            push!(answers, make_answer(universe, blocking_thing))
        end
        add_siblings_and_doors!(answers, universe, sentence, domain, blocking_thing, blocked_relationship)
    end
    answers
end

"""
    MenuAdventures.find_in_domain(universe, sentence, domain; lit = true)

Return a vector of [`Answer`](@ref)s for all things around the player in a certain [`Domain`](@ref).
"""
find_in_domain

"""
    MenuAdventures.indefinite(domain) = "something"

Placeholder for an object from the [`Domain`](@ref).

For example, the indefinite for [`ExitDirections`](@ref) is "some way".
"""
function indefinite(_)
    "something"
end

"""
    MenuAdventures.interrogative(domain) = "what"

Ask for an object from the [`Domain`](@ref).

For example, the interrogative for [`ExitDirections`](@ref) is "which way".
"""
function interrogative(_)
    "what"
end

"""
    abstract type Relationship end

Relationships show the relationships between [`Noun`](@ref)s. 

For example, something can be [`Containing`](@ref) something else.
"""
abstract type Relationship end

export Relationship

"""
    Carrying()

A is `carrying` B means B is carried by A.

A [`Relationship`](@ref).
"""
struct Carrying <: Relationship end

export Carrying

function string_relationship_to(thing_answer, ::Carrying, parent_thing)
    buffer = IOBuffer()
    print(buffer, thing_answer.text)
    print(buffer, " that ")
    show(buffer, parent_thing)
    print(buffer, ' ')
    print(buffer, subject_to_verb(parent_thing, BE))
    print(buffer, " carrying")
    String(take!(buffer))
end

verb_for(::Carrying) = Verb("carry"; third_person_singular_present = "carries")

"""
    Containing()

A is `containing` B means B is in A.

A [`Relationship`](@ref).
"""
struct Containing <: Relationship end

export Containing

function string_relationship_to(thing_answer, ::Containing, parent_thing)
    buffer = IOBuffer()
    print(buffer, thing_answer.text)
    print(buffer, ' ')
    print(buffer, "in ")
    show(IOContext(buffer, :is_subject => false, :subject => get_object(thing_answer)), parent_thing)
    String(take!(buffer))
end

verb_for(::Containing) = Verb("contain")

"""
    abstract type Direction end

`Direction`s show the relationships between [`Location`](@ref)s.

For example, a place can be [`North`](@ref) of another place.
To create a new `Direction`, you must add a method for

- `Base.show`
- the [`MenuAdventures.opposite`](@ref) of the direction.
"""
abstract type Direction end

export Direction

"""
    North()

A [`Direction`](@ref).
"""
struct North <: Direction end

export North

function show(io::IO, ::North)
    print(io, "north")
end

opposite(::North) = South()

"""
    West()

A [`Direction`](@ref).
"""
struct West <: Direction end

export West

function show(io::IO, ::West)
    print(io, "west")
end

opposite(::West) = East()

"""
    South()

A [`Direction`](@ref).
"""
struct South <: Direction end

export South

function show(io::IO, ::South)
    print(io, "south")
end

opposite(::South) = North()

"""
    East()

A [`Direction`](@ref).
"""
struct East <: Direction end

export East

function show(io::IO, ::East)
    print(io, "east")
end

opposite(::East) = West()

"""
    MenuAdventures.opposite(direction::Direction)

The opposite of a [`Direction`](@ref).
"""
opposite

"""
    abstract type Noun end

You must make your own custom `Noun` subtypes for almost everything in your game. 

See [`@noun`](@ref) for information about required fields.
Nouns are additionally characterized by the following traits and methods:

  - [`MenuAdventures.ever_possible`](@ref)
  - [`MenuAdventures.is_shining`](@ref)
  - [`MenuAdventures.is_transparent`](@ref)
  - [`MenuAdventures.is_vehicle`](@ref)

The following `IOContext` components will be respected when showing nouns:

- `:capitalize::Bool => false`
- `:known::Bool => true`, set to `false` to include the `indefinite article` if it exists.
- `:is_subject => true`, whether the noun is the subject of a clause. If this is set to `false`, you must also include
- `:subject::Noun`, the subject of the clause.
"""
abstract type Noun end

"""
    abstract type Location <: Noun end

A location (room or door)
"""
abstract type Location <: Noun end

export Location

"""
    abstract type AbstractRoom <: Location end

An abstract room.

In addition to the required fields for [`@noun`](@ref), you must also include an `already_lit::Bool` field for an `AbstractRoom`.
"""
abstract type AbstractRoom <: Location end

export AbstractRoom

"""
    abstract type AbstractDoor <: Location end

An abstract door
"""
abstract type AbstractDoor <: Location end

export AbstractDoor

"""
    abstract type Action end

An `Action` the player can take.

To create a new action, you will need to add methods for

- [`MenuAdventures.ever_possible`](@ref) for abstract possibilities
- [`MenuAdventures.possible_now`](@ref) for concrete possibilities
- [`MenuAdventures.argument_domains`](@ref) to specify the domain of the arguments
- [`MenuAdventures.print_sentence`](@ref) for printing the sentence
- [`MenuAdventures.mention_status`](@ref) for mentioning the status of a thing.

Note that the order arguments are printed in need not match the order they are listed.
However, the order of arguments for [`MenuAdventures.argument_domains`](@ref) must match the order of arguments for [`MenuAdventures.print_sentence`](@ref).

Most importantly, define:

```
function (::MyNewAction)(universe, arguments...) -> Bool
```

which will conduct the action based on user choices. 
Return `true` to end the game, or `false` to continue onto the next turn.
You can overload `Action` calls for a [`Noun`](@ref) subtype.
Use `Core.invoke` to avoid replicating the `Action` machinery.
"""
abstract type Action end

export Action

"""
    Answer(text::String, object::Any)

An answer has two fields: `text`, which will be how the option is displayed in a menu, and `object`.

`object` might be a noun, direction, trigger, or even a question.
"""
struct Answer{Object}
    text::String
    # could be an noun, a direction, or another question
    object::Object
end

export Answer

struct Sentence{Action}
    action::Action
    argument_answers::Vector{Answer}
end

export Sentence

"""
    Sentence(action::Action; argument_answers = Answer[])

A sentence has two fields: `action`, the [`Action`](@ref) to be taken, and `argument_answers`, the arguments to the action. 

Arguments will be returned as [`Answer`](@ref)s. The subject is implicitly `universe.player`.
"""
function Sentence(action::Action; argument_answers = Answer[])
    Sentence(action, argument_answers)
end

"""
    Drop()

`Drop` something in your [`Inventory`](@ref).
"""
struct Drop <: Action end

export Drop

function argument_domains(::Drop)
    (Inventory(),)
end

function ever_possible(::Drop, ::Inventory, _)
    true
end

function (::Drop)(universe, thing)
    PutInto()(universe, thing, get_parent(universe, universe.player))
end

function print_sentence(io, ::Drop, thing_answer)
    print(io, "Drop ")
    print(io, thing_answer.text)
end

"""
    Go()

`Go` in one of [`ExitDirections`](@ref).

An [`Action`](@ref).
"""
struct Go <: Action end

export Go

function possible_now(universe, ::Sentence{Go}, ::ExitDirections, direction)
    !(is_closable_and_closed(get_first_destination(universe, direction)))
end

function (::Go)(universe, direction)
    GoInto()(universe, get_final_destination(universe, direction))
    return false
end

function print_sentence(io, ::Go, direction_answer)
    print(io, "Go ")
    print(io, direction_answer.text)
end

function argument_domains(::Go)
    (ExitDirections(),)
end

"""
    GoInto()

Go into something [`Immediate`](@ref).

An [`Action`](@ref).
"""
struct GoInto <: Action end

export GoInto

function argument_domains(::GoInto)
    (Immediate(),)
end

function possible_now(universe, sentence::Sentence{GoInto}, domain::Immediate, thing)
    ever_possible(sentence.action, domain, thing) && 
    !(is_closable_and_closed(thing)) &&
    # you can't go into where you already are
    get_parent(universe, universe.player) !== thing
end

# add relations to player
function (::GoInto)(universe, place)
    PutInto()(universe, get_mover(universe), place)
    return false
end

function print_sentence(io, ::GoInto, place_answer)
    print(io, "Go into ")
    print(io, place_answer.text)
end

"""
    Leave()

Leave whatever the player is in/on.

An [`Action`](@ref).
"""
struct Leave <: Action end

function (::Leave)(universe)
    player = universe.player
    parent_thing = get_parent(universe, player)
    grandparent_thing, parent_relationship = get_parent_relationship(universe, parent_thing)
    universe[grandparent_thing, player] = parent_relationship
    return false
end

function argument_domains(::Leave)
    ()
end

function possible_now(universe, ::Leave)
    !(get_parent(universe, universe.player) isa Location)
end

function print_sentence(io, ::Leave)
    print(io, "Leave")
end

export Leave

"""
    ListInventory()

List the player's inventory.

An [`Action`](@ref).
"""
struct ListInventory <: Action end

export ListInventory

function (::ListInventory)(universe)
    player = universe.player
    interface = universe.interface
    relations = OrderedDict{Relationship, Vector{Answer}}()
    for (thing, relationship) in
        get_children_relationships(universe, player)
        # we automatically mention everything that is visible
        push!(get!(relations, relationship, Answer[]), make_answer(universe, thing))
    end
    println(interface)
    show(IOContext(interface, :known => false, :is_subject => true, :capitalize => true), player)
    print(interface, ':')
    println(interface)
    print_relations(universe, 0, Visible(), player, relations)
    return false
end

function print_sentence(io, ::ListInventory)
    print(io, "List inventory")
end

function argument_domains(::ListInventory)
    ()
end

function possible_now(universe, ::ListInventory)
    !isempty(get_children_relationships(universe, universe.player))
end

"""
    LookAt()

Look at something [`Visible`](@ref).

An [`Action`](@ref).
"""
struct LookAt <: Action end

export LookAt

function argument_domains(::LookAt)
    (Visible(),)
end

function possible_now(universe, ::Sentence{LookAt}, ::Visible, thing)
    get_description(universe, thing) != ""
end

function (::LookAt)(universe, thing)
    println_wrapped(
        universe.interface,
        get_description(universe, thing);
        replace_whitespace = false,
    )
    return false
end

function print_sentence(io, ::LookAt, thing_answer)
    print(io, "Look at ")
    print(io, thing_answer.text)
end

"""
    OpenOrClose()

Open or close something [`Reachable`](@ref).

An [`Action`](@ref).
"""
struct OpenOrClose <: Action end

export OpenOrClose

function is_closable_and_closed(thing)
    ever_possible(OpenOrClose(), Reachable(), thing) && thing.closed
end

function possible_now(_, ::Sentence{OpenOrClose}, ::Reachable, thing)
    ever_possible(OpenOrClose(), Reachable(), thing) && !(is_lockable_and_locked(thing))
end

function (::OpenOrClose)(_, thing)
    thing.closed = !(thing.closed)
    return false
end

function print_sentence(io, ::OpenOrClose, thing_answer)
    object = thing_answer.object
    if object isa Noun
        if object.closed
            print(io, "Open ")
        else
            print(io, "Close ")
        end
    else
        print(io, "Open or close ")
    end
    print(io, thing_answer.text)
end

function argument_domains(::OpenOrClose)
    (Reachable(),)
end

"""
    PutInto()

Put something from your [`Inventory`](@ref) into something [`Reachable`](@ref).

An [`Action`](@ref). By default,

    ever_possible(::PutInto, ::Inventory, anything) = true

that is, it is always possible to put something from your inventory into a container, and

    ever_possible(::PutInto, ::Reachable, ::AbstractRoom) = true

that is, all rooms act like containers.
"""
struct PutInto <: Action end

export PutInto

function argument_domains(::PutInto)
    Inventory(), Reachable()
end

ever_possible(::PutInto, ::Inventory, _) = true
ever_possible(::PutInto, ::Reachable, ::AbstractRoom) = true

function possible_now(_, sentence::Sentence{PutInto}, domain::Reachable, thing)
    ever_possible(sentence.action, domain, thing) &&
        !(is_closable_and_closed(thing)) &&
        # can't put something into itself
        thing !== sentence.argument_answers[1].object
end

function (::PutInto)(universe, thing, parent_thing)
    universe[parent_thing, thing] = Containing()
    return false
end

function print_sentence(io, ::PutInto, thing_answer, parent_thing_answer)
    print(io, "Put ")
    print(io, thing_answer.text)
    print(io, " into ")
    print(io, parent_thing_answer.text)
end

"""
    Take()

Take something [`Reachable`](@ref).

An [`Action`](@ref).
"""
struct Take <: Action end

export Take

function argument_domains(::Take)
    (Reachable(),)
end

function possible_now(universe, sentence::Sentence{Take}, domain::Reachable, thing)
    ever_possible(sentence.action, domain, thing) && 
    !(thing isa Location) &&
    begin
        parent_thing, relationship = get_parent_relationship(universe, thing)
        !(parent_thing === universe.player && relationship isa Carrying)
    end
end

function (::Take)(universe, thing)
    ExtraActions.Give()(universe, thing, universe.player)
end

function print_sentence(io, ::Take, thing_answer)
    print(io, "Take ")
    print(io, thing_answer.text)
end

"""
    Quit()

Quit

An [`Action`](@ref).
"""
struct Quit <: Action end

export Quit

function argument_domains(::Quit)
    ()
end

function (::Quit)(_)
    return true
end

function print_sentence(io, ::Quit)
    print(io, "Quit")
end

"""
    UnlockOrLock()

Unlock or lock something [`Reachable`](@ref) with something from your [`Inventory`](@ref).

An [`Action`](@ref).
"""
struct UnlockOrLock <: Action end

export UnlockOrLock

function is_lockable_and_locked(thing)
    ever_possible(UnlockOrLock(), Reachable(), thing) && thing.locked
end

function argument_domains(::UnlockOrLock)
    Reachable(), Inventory()
end

function possible_now(_, sentence::Sentence{UnlockOrLock}, domain::Reachable, thing)
    ever_possible(sentence.action, domain, thing) && is_closable_and_closed(thing)
end

function (::UnlockOrLock)(universe, door, key)
    if door.key === key
        door.locked = !(door.locked)
    else
        println_wrapped(
            universe.interface,
            string_in_color(
                :red,
                uppercasefirst(string(key)),
                ' ',
                subject_to_verb(key, DO),
                "n't fit!",
            ),
        )
    end
    return false
end

function print_sentence(io, ::UnlockOrLock, door_answer, key_answer)
    door_object = door_answer.object
    if door_object isa Noun
        if door_object.locked
            print(io, "Unlock ")
        else
            print(io, "Lock ")
        end
    else
        print(io, "Unlock or lock ")
    end
    print(io, door_answer.text)
    print(io, " with ")
    print(io, key_answer.text)
end

"""
    MenuAdventures.print_sentence(io, action::Action, argument_answers::Answer...)

Print a sentence to `io`.

This allows for inserting connectives like `with`. Arguments will be passed as [`Answer`](@ref)s.
"""
print_sentence

@enum GrammaticalPerson first_person second_person third_person

"""
    first_person
    
First person (e.g. I).

In games, the narrator is typically the first person.
"""
first_person

export first_person

"""
    second_person

Second person (e.g. you).

In games, the player is typically the second person.
"""
second_person

export second_person

"""
    third_person

Third person (e.g. he, she, it).

In games, everything is typically third person except for the player and narrator.
"""
third_person

export third_person

export Noun

get_description(universe, thing::Noun) = thing.description(universe, thing)

"""
    MenuAdventures.is_transparent(thing::Noun) = false

Whether you can see through a `thing` into its contents.
"""
is_transparent(::Noun) = false

"""
    MenuAdventures.is_vehicle(::Noun) = false

Whether something is a vehicle.
"""
is_vehicle(::Noun) = false

"""
    is_shining(::Noun) = false

Whether something provides light.
"""
is_shining(::Noun) = false

"""
    MenuAdventures.ever_possible(action::Action, domain::Domain, noun::Noun)

Whether it is abstractly possible to apply an [`Action`](@ref) to a [`Noun`](@ref) from a particular [`Domain`](@ref).

For whether it is concretely possible for the player in at a certain moment, see [`possible_now`](@ref).
Most possibilities default to `false`, with some exceptions, documented in specific actions.

Certain possibilities come with required fields:

- `ever_possible(::Open, ::Reachable, noun` requires that `noun` has a mutable `closed::Bool` field.
- `ever_possible(::Unlock, ::Reachable, noun)` requires that `noun` has a `key::Noun` field and a mutable `locked::Bool` field.
"""
ever_possible(_, __, ___) = false

struct Verb
    base::String
    third_person_singular_present::String
end

"""
    Verb(base; third_person_singular_present = string(base, "s"))

Create an English verb.

Use [`subject_to_verb`](@ref) to get the form of a verb to agree with a subject.
Unexported verbs include `MenuAdventures.DO` and `MenuAdventures.BE`.
"""
function Verb(base; third_person_singular_present = string(base, "s"))
    Verb(base, third_person_singular_present)
end

export Verb

const DO = Verb("do"; third_person_singular_present = "does")
const BE = Verb("are"; third_person_singular_present = "is")

"""
    subject_to_verb(subject, verb)

Find the [`Verb`](@ref) form to agree with a subject.
"""
function subject_to_verb(subject, verb)
    if subject.grammatical_person === third_person && !(subject.plural)
        verb.third_person_singular_present
    else
        verb.base
    end
end

export subject_to_verb

"""
    abstract type AbstractUniverse end

Contains all the information about the game universe.

You will need to create your own `AbstractUniverse` subtype. See [`@universe`](@ref) for an easy way to do this.

The universe is organized as an interlinking web of [`Location`](@ref)s connected by [`Direction`](@ref)s.
Each location is the root of a tree of [`Noun`](@ref)s connected by [`Relationship`](@ref)s.

You can add a new thing to the `universe`, or change the location of something, by specifying its relation to another thing:

    universe[parent_thing, thing] = relationship

You can add a connection between locations too, optionally interspersed by a door:

    universe[origin, destination, one_way = false] = direction
    universe[origin, destination, one_way = false] = door, direction

By default, this will create a way back in the [`MenuAdventures.opposite`](@ref) direction. To suppress this, set `one_way = true`
"""
abstract type AbstractUniverse end

export AbstractUniverse

show(io::IO, ::AbstractUniverse) = print(io, "A universe")

function get_parent(universe, thing)
    relationships_graph = universe.relationships_graph
    label_for(
        relationships_graph,
        only(inneighbors(relationships_graph, code_for(relationships_graph, thing))),
    )
end

"""
    get_parent_relationship(universe, thing)

Get the parent of a `thing` in the universe, and the parent's [`Relationship`](@ref) to it.
"""
function get_parent_relationship(universe, thing)
    relationships_graph = universe.relationships_graph
    parent = get_parent(universe, thing)
    parent, relationships_graph[parent, thing]
end

export get_parent_relationship

function over_out_neighbor_codes(a_function, meta_graph, parent_thing)
    Iterators.map(a_function, 
        if haskey(meta_graph, parent_thing)
            outneighbors(meta_graph, code_for(meta_graph, parent_thing))
        else
            eltype(meta_graph)[]
        end
    )
end

function out_neighbors_relationships(meta_graph, parent_thing)
    over_out_neighbor_codes(
        function (code)
            thing = label_for(meta_graph, code)
            thing, meta_graph[parent_thing, thing]
        end,
        meta_graph,
        parent_thing,
    )
end

"""
    get_children_relationships(universe, parent_thing)

Get the children of `parent_thing` in the universe, and the [`Relationship`](@ref)s of `parent_thing` to them.
"""
function get_children_relationships(universe, parent_thing)
    out_neighbors_relationships(universe.relationships_graph, parent_thing)
end

export get_children_relationships

"""
    get_exit_directions(universe, location)

Get the exits from a location, and the direction of those exits (if exits exist)
"""
function get_exit_directions(universe, location)
    out_neighbors_relationships(universe.directions_graph, location)
end

export get_exit_directions


function get_mover(universe)
    player = universe.player
    mover = get_parent(universe, player)
    if is_vehicle(mover)
        mover
    else
        player
    end
end

function get_first_destination(universe, blocking_thing, direction)
    only(Iterators.filter(
        function ((location, possible_direction),)
            possible_direction === direction
        end,
        get_exit_directions(universe, blocking_thing),
    ))[1]
end

function get_first_destination(universe, direction)
    blocking_thing, _ = blocking_thing_and_relationship(universe, ExitDirections())
    get_first_destination(universe, blocking_thing, direction)
end

function get_final_destination(universe, direction)
    blocking_thing, _ = blocking_thing_and_relationship(universe, ExitDirections())
    maybe_door = get_first_destination(universe, blocking_thing, direction)
    if maybe_door isa AbstractDoor
        get_first_destination(universe, maybe_door, direction)
    else
        maybe_door
    end
end

function setindex!(
    universe::AbstractUniverse,
    relationship::Relationship,
    parent_thing::Noun,
    thing::Noun;
)
    relationships_graph = universe.relationships_graph
    relationships_graph[parent_thing] = nothing
    if !(thing isa Location) && haskey(relationships_graph, thing)
        old_parent = get_parent(universe, thing)
        if haskey(relationships_graph, old_parent, thing)
            delete!(relationships_graph, old_parent, thing)
        end
    else
        relationships_graph[thing] = nothing
    end
    relationships_graph[parent_thing, thing] = relationship
    nothing
end

function one_way!(
    universe::AbstractUniverse,
    blocking_thing::Location,
    direction::Direction,
    destination::Location,
)
    relationships_graph = universe.relationships_graph
    relationships_graph[blocking_thing] = nothing
    relationships_graph[destination] = nothing
    directions_graph = universe.directions_graph
    directions_graph[blocking_thing] = nothing
    directions_graph[destination] = nothing
    directions_graph[blocking_thing, destination] = direction
    nothing
end

function one_way!(
    universe::AbstractUniverse,
    blocking_thing::Location,
    door::AbstractDoor,
    direction::Direction,
    destination::Location,
)
    one_way!(universe, blocking_thing, direction, door)
    one_way!(universe, door, direction, destination)
    nothing
end

function setindex!(
    universe::AbstractUniverse,
    direction::Direction,
    blocking_thing::Location,
    destination::Location;
    one_way = false,
)
    one_way!(universe, blocking_thing, direction, destination)
    if !one_way
        one_way!(universe, destination, opposite(direction), blocking_thing)
    end
end
function setindex!(
    universe::AbstractUniverse,
    (door, direction)::Tuple{AbstractDoor, Direction},
    blocking_thing::Location,
    destination::Location;
    one_way = false,
)
    one_way!(universe, blocking_thing, door, direction, destination)
    if !one_way
        one_way!(universe, destination, door, opposite(direction), blocking_thing)
    end
end

function maybe_capitalize(capitalize, thing)
    if capitalize
        uppercasefirst(thing)
    else
        thing
    end
end

function show(io::IO, thing::Noun)
    capitalize = get(io, :capitalize, false)
    grammatical_person = thing.grammatical_person
    if grammatical_person === third_person
        indefinite_article = thing.indefinite_article
        if isempty(indefinite_article)
            print(io, maybe_capitalize(capitalize, thing.name))
        else
            if get(io, :known, true)
                print(io, maybe_capitalize(capitalize, "the "))
                print(io, thing.name)
            else
                print(io, maybe_capitalize(capitalize, thing.indefinite_article))
                print(io, ' ')
                print(io, thing.name)
            end
        end
    else
        is_subject = get(io, :is_subject, true)
        print(
            io, 
            if grammatical_person === second_person
                if is_subject
                    maybe_capitalize(capitalize, "you")
                else
                    subject = get(io, :subject, nothing)
                    if subject === thing
                        # since the subject is the second person, use the reflexive pronoun instead
                        maybe_capitalize(capitalize, "yourself")
                    else
                        maybe_capitalize(capitalize, "you")
                    end
                end
            else
                error("Unsupported grammatical person")
            end
        )
    end
end

"""
    string_in_color(color::Symbol, arguments...)

Use ASCII escape codes to add a `color` to the `arguments` collected as a string.
"""
function string_in_color(color::Symbol, arguments...)
    string(text_colors[color], arguments..., text_colors[:default])
end

export string_in_color

function make_answer(universe, thing)
    buffer = IOBuffer()
    # things will have already been mentioned in the room descrption
    show(IOContext(buffer, :is_subject => false, :subject => universe.player), thing)
    Answer(String(take!(buffer)), thing)
end

"""
    mention_status(io, action, thing)

Print the status of `thing` corresponding to `action` into `io`.

For example, for the [`OpenOrClose`](@ref) action, will display whether `thing` is open or closed.
Called for all action subtypes when mentioning a thing.
Defaults to doing `nothing`.
"""
function mention_status(_, __, ___)
    nothing
end

function mention_status(io, action::OpenOrClose, thing)
    if ever_possible(action, Reachable(), thing)
        if thing.closed
            print(io, " (closed)")
        else
            print(io, " (open)")
        end
    end
end

function mention_status(io, action::UnlockOrLock, thing)
    if ever_possible(action, Reachable(), thing)
        if thing.locked
            print(io, " (locked)")
        else
            print(io, " (unlocked)")
        end
    end
end

function make_blurb(thing)
    buffer = IOBuffer()
    # things will have already been mentioned in the room descrption
    show(IOContext(buffer, :known => false, :is_subject => true), thing)
    for action_type in subtypes(Action)
        mention_status(buffer, action_type(), thing)
    end
    Answer(String(take!(buffer)), thing)
end

struct Question
    text::String
    answers::Vector{Answer}
end

function get_object(thing::Answer)
    thing.object
end
function get_object(::Question)
    nothing
end

function print_relationship_as_verb(io, parent_thing, relationship::Relationship)
    print(io, subject_to_verb(parent_thing, verb_for(relationship)))
end

function print_relationship_as_verb(io, _, direction::Direction)
    show(io, direction)
end

"""
    MenuAdventures.blocking(domain, parent_thing, relationship, thing)

`parent_thing` is blocked from accessing `thing` via the `relationship`.

By default, [`Reachable`](@ref) `parent_thing`s block `thing`s they are [`Containing`](@ref) if they are closed.
By default, [`Visible`](@ref) `parent_thing`s block `thing`s they are [`Containing`](@ref) if they are closed and not [`MenuAdventures.is_transparent`](@ref).
"""
blocking

"""
    MenuAdventures.possible_now(universe, sentence, domain, thing)

Whether it is currently possible to apply `sentence.action` to a `thing` in a `domain`.

See [`ever_possible`](@ref) for a more abstract possibilities. 
`sentence` will contain already chosen arguments, should you wish to access them.
"""
function possible_now(_, sentence, domain, thing)
    ever_possible(sentence.action, domain, thing)
end

function append_parent_relationship_to(_, noun::Noun, __, ___)
    noun
end

function append_parent_relationship_to(universe, answer::Answer, relationship, parent_thing)
    Answer(
        string_relationship_to(answer, relationship, parent_thing),
        append_parent_relationship_to(universe, answer.object, relationship, parent_thing),
    )
end

function append_parent_relationship_to(universe, question::Question, relationship, parent_thing)
    Question(
        string_relationship_to(question, relationship, parent_thing),
        map(
            function (answer)
                append_parent_relationship_to(universe, answer, relationship, parent_thing)
            end,
            question.answers,
        ),
    )
end

function add_thing_and_relations!(answers, universe, sentence, domain, parent_thing)
    if possible_now(universe, sentence, domain, parent_thing)
        push!(answers, make_answer(universe, parent_thing))
    end
    sub_relations = OrderedDict{Relationship, Vector{Answer}}()
    for (thing, relationship) in
        get_children_relationships(universe, parent_thing)
        if !(blocking(domain, parent_thing, relationship, thing))
            add_thing_and_relations!(
                get!(sub_relations, relationship, Answer[]),
                universe,
                sentence,
                domain,
                thing,
            )
            # we automatically mention everything that is visible
            # recur
        end
    end
    for (sub_relationship, sub_answers) in sub_relations
        if !isempty(sub_answers)
            push!(
                answers,
                append_parent_relationship_to(
                    universe,
                    if length(sub_answers) == 1
                        only(sub_answers)
                    else
                        Answer(
                            indefinite(domain),
                            Question(interrogative(domain), sub_answers),
                        )
                    end,
                    sub_relationship,
                    parent_thing,
                ),
            )
        end
    end
end

function add_siblings_and_doors!(answers, universe, sentence, domain, blocking_thing, blocked_relationship)
    for (thing, relationship) in
        get_children_relationships(universe, blocking_thing)
        if relationship === blocked_relationship
            add_thing_and_relations!(answers, universe, sentence, domain, thing)
        end
    end
    for (location, _) in
        get_exit_directions(universe, blocking_thing)
        if location isa AbstractDoor
            add_thing_and_relations!(answers, universe, sentence, domain, location)
        end
    end
end

function print_relations(universe, indent, domain, parent_thing, relations)
    interface = universe.interface
    relationship_indent = indent + 2
    sub_indent = relationship_indent + 2
    for (relationship, answers) in relations
        print(interface, ' '^relationship_indent)
        print_relationship_as_verb(interface, parent_thing, relationship)
        print(interface, ':')
        println(interface)
        for answer in answers
            # don't need the answer text, just the object itself
            thing = answer.object
            sub_relations = OrderedDict{Relationship, Vector{Answer}}()
            # we always stop at the player; inventory must be explicitly asked for
            if !(thing === universe.player)
                for (sub_thing, sub_relationship) in
                    get_children_relationships(universe, thing)
                    if !(blocking(domain, thing, sub_relationship, sub_thing))
                        # we automatically mention everything that is visible
                        push!(
                            get!(sub_relations, sub_relationship, Answer[]),
                            make_blurb(sub_thing),
                        )
                    end
                end
            end
            print(interface, ' '^sub_indent)
            print(interface, make_blurb(thing).text)
            if !isempty(sub_relations)
                print(interface, ':')
            end
            println(interface)
            print_relations(universe, sub_indent, domain, thing, sub_relations)
        end
    end
end

"""
    argument_domains(action::Action)

Return a tuple of the [`Domain`](@ref)s for each argument of an [`Action`](@ref).
"""
argument_domains

"""
    possible_now(universe, action)

Whether it is possible to conduct an action.
Defaults to `true`; you can set to `false` for some actions without arguments.
"""
function possible_now(_, __)
    true
end

function choose(universe, sentence, index, answer)
    interface = universe.interface
    object = answer.object
    if object isa Question
        answers = object.answers
        sort!(answers, by = answer -> answer.text)
        println(interface)
        # add an exta line to add space before the question
        # we need take it first to see if its empty or not
        choice = request(
            interface,
            sprint(
                show,
                replace_argument(sentence, index, Answer(object.text, nothing));
                context = :suffix => "?"
            ),
            RadioMenu(map(
                function (sub_answer)
                    sprint(show, replace_argument(sentence, index, sub_answer), context = :color => :green)
                end,
                answers
            ); charset = :ascii),
        )
        push!(universe.choices_log, choice)
        choose(universe, sentence, index, answers[choice])
    else
        answer
    end
end

function show(io::IO, sentence::Sentence)
    color = get(io, :color, :default)
    print(io, text_colors[color])
    print_sentence(
        io,
        sentence.action,
        sentence.argument_answers...
    )
    print(io, get(io, :suffix, ""))
    print(io, text_colors[:default])
end

function replace_argument(sentence, blank_index, replacement)
    argument_answers_copy = copy(sentence.argument_answers)
    argument_answers_copy[blank_index] = replacement
    Sentence(sentence.action, argument_answers_copy)
end

function is_player_lit(universe; domain = Visible())
    blocking_thing, blocked_relationship = blocking_thing_and_relationship(universe, domain)
    if blocking_thing isa AbstractRoom && blocking_thing.already_lit
        true
    else
        for (thing, relationship) in
            get_children_relationships(universe, blocking_thing)
            if relationship === blocked_relationship &&
                is_lit(universe, thing; domain = domain)
                return true
            end
        end
        false
    end
end

function is_lit(universe, parent_thing; domain = Visible())
    if is_shining(parent_thing)
        true
    else
        for (thing, relationship) in
            get_children_relationships(universe, parent_thing)
            if !(blocking(domain, parent_thing, relationship, thing))
                if is_lit(universe, thing; domain = domain)
                    return true
                end
            end
        end
        false
    end
end

"""
    MenuAdventures.look_around(universe, domain, blocking_thing, blocked_relationship)

Look around a lit location.

You can overload `look_around` for a [`Noun`](@ref) subtype.
Use `Core.invoke` to avoid replicating the `look_around` machinery.
"""
function look_around(universe, domain, blocking_thing, blocked_relationship)
    interface = universe.interface
    println(interface)
    indent = 0
    relations = OrderedDict{Union{Relationship, Direction}, Vector{Answer}}()
    for (thing, relationship) in
        get_children_relationships(universe, blocking_thing)
        if relationship === blocked_relationship
            # we automatically mention everything that is visible
            push!(get!(relations, relationship, Answer[]), make_blurb(thing))
        end
    end
    for (location, direction) in
        get_exit_directions(universe, blocking_thing)
        if location isa AbstractDoor
            push!(get!(relations, direction, Answer[]), make_blurb(location))
        end
    end
    print(interface, ' '^indent)
    show(IOContext(interface, :capitalize => true, :known => false, :is_subject => true), blocking_thing)
    if !isempty(relations)
        print(interface, ':')
    end
    println(interface)
    print_relations(universe, indent, domain, blocking_thing, relations)
end

"""
    turn!(universe; introduce = true)

Start a turn in the [`AbstractUniverse`](@ref), and keep going until an [`Action`](@ref) returns `true`.

You can overload `turn!` for an [`AbstractUniverse`](@ref).
Use `Core.invoke` to avoid replicating the `turn!` machinery.
"""
function turn!(universe; introduce = true)
    interface = universe.interface

    if introduce
        introduction = universe.introduction
        if introduction != ""
            println_wrapped(interface, introduction; replace_whitespace = false)
        end
    end

    # reintroduce the player to their surroundings if the end the turn in a new loaction
    lit = is_player_lit(universe)

    if !lit
        println_wrapped(interface, "In darkness")
    else
        visible = Visible()
        look_around(universe, visible, blocking_thing_and_relationship(universe, visible)...)
    end
    sentences = Sentence[]
    for verb_type in subtypes(Action)
        action = verb_type()
        sentence = Sentence(action)
        dead_end = false
        for domain in argument_domains(action)
            answers = find_in_domain(universe, sentence, domain; lit = lit)
            if isempty(answers)
                dead_end = true
                break
            else
                push!(
                    sentence.argument_answers,
                    if length(answers) == 1
                        only(answers)
                    else
                        Answer(
                            indefinite(domain),
                            Question(interrogative(domain), answers),
                        )
                    end,
                )
            end
        end
        if possible_now(universe, action) && !dead_end
            push!(sentences, sentence)
        end
    end
    choice = 
        if length(sentences) > 1
            sort!(sentences, by = repr)
            request(interface, "", RadioMenu(map(
                function (sentence)
                    sprint(show, sentence, context = :color => :green)
                end, 
                sentences
            ); charset = :ascii))
        else
            println(interface)
            print(interface, " > ")
            show(IOContext(interface, :color => :green), sentences[1])
            1
        end
    push!(universe.choices_log, choice)

    sentence = sentences[choice]
    argument_answers = sentence.argument_answers

    for (index, argument_answer) in enumerate(argument_answers)
        argument_answers[index] = choose(universe, sentence, index, argument_answer)
    end
    end_game = sentence.action(universe, Iterators.map(function (answer)
        answer.object
    end, argument_answers)...)
    if !end_game
        turn!(universe; introduce = false)
    end
    nothing
end

export turn!

function parse_lines!(positional_arguments, keyword_arguments, lines)
    for line in lines
        if @capture line fieldname_::fieldtype_
            push!(positional_arguments, (field_name = fieldname, field_type = fieldtype))
        elseif @capture line fieldname_::fieldtype_ = default_
            push!(keyword_arguments, (field_name = fieldname, field_type = fieldtype, default = default))
        else
            error("Cannot parse line")
        end
    end
end

function add_line!(struct_lines, constructor_call_arguments, argument, location)
    field_name = argument.field_name
    push!(struct_lines, location)
    push!(struct_lines, Expr(:(::), field_name, argument.field_type))
    push!(constructor_call_arguments, field_name)
end

function add_defaults(user_definition, defaults, location)
    if @capture user_definition (
        struct nounname_ <: thesupertype_
            userfields__
        end
    )
        is_mutable = false
    elseif @capture user_definition (
        mutable struct nounname_ <: thesupertype_
            userfields__
        end
    )
        is_mutable = true
    else
        throw(ArgumentError("Cannot parse user struct definition"))
    end
    positional_arguments = []
    keyword_arguments = []
    parse_lines!(positional_arguments, keyword_arguments, defaults)
    parse_lines!(positional_arguments, keyword_arguments, userfields)
    sort!(keyword_arguments, by = argument -> argument.field_name)
    struct_lines = []
    constructor_positionals = []
    constructor_keywords = []
    constructor_call_arguments = []

    for argument in positional_arguments
        add_line!(struct_lines, constructor_call_arguments, argument, location)
        push!(constructor_positionals, argument.field_name)
    end
    for argument in keyword_arguments
        add_line!(struct_lines, constructor_call_arguments, argument, location)
        push!(constructor_keywords, Expr(:kw, argument.field_name, argument.default))
    end
    Expr(:block,
        location,
        Expr(:struct, 
            is_mutable, 
            Expr(:(<:), nounname, thesupertype),
            Expr(:block, struct_lines...)
        ),
        location,
        Expr(:function, 
            Expr(:call, nounname, Expr(:parameters, constructor_keywords...), constructor_positionals...), 
            Expr(:block, location, Expr(:call, nounname, constructor_call_arguments...))
        )
    )
end

"""
    const NOUN_FIELDS = [
        :(name::String), 
        :(grammatical_person::GrammaticalPerson = third_person),
        :(indefinite_article::String = "a"),
        :(plural::Bool = false),
        :(description = (_, __) -> "")
    ]

A list of expressions, the fields added by the [`@noun`](@ref) macro. 

You can add new noun fields by `push!`ing to this list. 
Because the expressions will be escaped, you might want to interpolate in everything except for the field name.
Be careful; obviously changing `NOUN_FIELDS` will change the behavior of the [`@noun`](@ref) macro.
"""
const NOUN_FIELDS = [
    :(name::$String), 
    :(grammatical_person::$GrammaticalPerson = $third_person),
    :(indefinite_article::$String = "a"),
    :(plural::$Bool = false),
    :(description::$FunctionWrapper{$String, $Tuple{$AbstractUniverse, $Noun}} = (_, __) -> "")
]

"""
    @noun user_definition

Automatically add [`MenuAdventures.NOUN_FIELDS`](@ref) to a [`Noun`](@ref) struct definition, including sane defaults.

Adds the following fields and defaults:

- `name::String`
- `plural::Bool = false`
- `grammatical_person::GrammaticalPerson = third_person`, see [`third_person`](@ref)
- `indefinite_article::String = "a"`
- `description = (universe, self) -> ""`

Set `indefinite_article` to `""` for proper nouns.
`description` should be a function which takes two arguments, the `universe` and the `thing` itself, and returns a description.
"""
macro noun(user_definition)
    esc(add_defaults(user_definition, NOUN_FIELDS, __source__))
end

export @noun

const UNIVERSE_FIELDS = [
    :(player::$Noun),
    :(interface::$TTYTerminal = ($TerminalMenus).terminal),
    :(introduction::$String = ""),
    :(relationships_graph::$(typeof(MetaGraph(DiGraph(), Label = Noun, EdgeMeta = Relationship))) = 
        $MetaGraph($DiGraph(), Label = $Noun, EdgeMeta = $Relationship)),
    :(directions_graph::$(typeof(MetaGraph(DiGraph(), Label = Location, EdgeMeta = Direction))) = 
        $MetaGraph($DiGraph(), Label = $Location, EdgeMeta = $Direction)),
    :(choices_log::$(Vector{Int}) = $Int[])
]

"""
    @universe user_definition

Automatically add the required fields to an [`AbstractUniverse`](@ref) struct definition, including sane defaults.

Adds the following fields and defaults:

- `player::Noun`. The player will typically be in [`second_person`](@ref).
- `interface::TTYTerminal = terminal`
- `introduction::String = ""`
- `relationships_graph = MetaGraph(DiGraph(), Label = Noun, EdgeMeta = Relationship))`, the [`Relationship`](@ref)s between [`Noun`](@ref)s.
- `directions_graph = MetaGraph(DiGraph(), Label = Location, EdgeMeta = Direction))`, the [`Direction`](@ref)s between [`Location`](@ref)s.
- `choices_log::Vector{Int} = Int[]` saves all choices the user makes

See [`AbstractUniverse`](@ref) for more information.
"""
macro universe(user_definition)
    esc(add_defaults(user_definition, UNIVERSE_FIELDS, __source__))
end

export @universe

include("ExtraDirections.jl")
include("ExtraActions.jl")
include("Onto.jl")
include("Outfits.jl")
include("Parts.jl")
include("Talking.jl")
include("Testing.jl")

end

