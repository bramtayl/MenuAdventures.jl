module MenuAdventures

using Base: disable_text_style, @kwdef, text_colors
import Base: setindex!, show
using OrderedCollections: OrderedDict
using InteractiveUtils: subtypes
using LightGraphs: DiGraph, inneighbors, outneighbors
using MacroTools: @capture
using MetaGraphsNext: code_for, MetaGraph, label_for
using REPL.Terminals: TTYTerminal
using REPL.TerminalMenus: RadioMenu, request, terminal
using TextWrap: println_wrapped

"""
    abstract type Domain end

A domain refers to a search space for a specific argument to an [`Action`](@ref).

For example, you are only able to look at things in the `Visible` domain.
Domains serve both as a way of distinguishing different arguments to an action, and also, categorizing the environment around the player.
Users could theoretically add a new domain.
"""
abstract type Domain end

"""
    struct Reachable <: Domain end

Anything the player can reach.

Players can't reach through closed containers by default.
"""
struct Reachable <: Domain end

"""
    struct Visible <: Domain end

Anything the player can see.

By default, players can't see into closed, opaque containers.
"""
struct Visible <: Domain end

"""
    struct Inventory <: Domain end

Things the player is carrying.
"""
struct Inventory <: Domain end

"""
    struct MoveSiblings <: Domain end

Thing that are in/on the same place the player could more from.
"""
struct MoveSiblings <: Domain end

"""
    struct ExitDirections <: Domain end

Directions that a player, or the vehicle a player is in, might exit in.
"""
struct ExitDirections <: Domain end

"""
    @enum Relationship carrying containing incorporating supporting wearing

Relationships show the relationshp of a `thing` to its `parent_thing`.

- A is `carrying` B means B is carried by AbstractDoor
- A is `containing` B means B is in A 
- A is `incorporating` B means B is part of A 
- A is `supporting` B means B is on top of A
- A is `wearing` B means B is worn by A
"""
@enum Relationship carrying containing incorporating supporting wearing

"""
    @enum Direction north south west east north_west north_east south_west south_east up down inside outside

Directions show the relationships between [`Location`](@ref)s.

You can use [`opposite`](@ref) to find the opposite of a direction.
"""
@enum Direction north south west east north_west north_east south_west south_east up down inside outside

"""
    function opposite(direction::Direction)

The opposite of a direction.
"""
function opposite(direction::Direction)
    if direction === north
        south
    elseif direction === south
        north
    elseif direction === west
        east
    elseif direction === east
        west
    elseif direction === north_west
        south_east
    elseif direction === south_east
        north_west
    elseif direction === north_east
        south_west
    elseif direction === south_west
        north_east
    elseif direction === up
        down
    elseif direction === down
        up
    elseif direction === inside
        outside
    elseif direction === outside
        inside
    else
        error("$direction has no opposite")
    end
end

"""
    abstract type Action end

A action is an action the player can take.

It should be fairly easy to create new verbs:
you will need to define [`ever_possible`](@ref) for abstract possibilities,
[`possible_now`](@ref) for concrete possibilities,
[`argument_domains`](@ref) to specify the domain of the arguments, and
[`print_sentence`](@ref) for printing the sentence.

Most importantly, define:

```
function (::MyNewAction)(universe, arguments...) -> Bool
```

Which will conduct the action based on user choices. 
Return `true` to end the game.
"""
abstract type Action end

"""
    struct Attach <: Action end

`Attach` something to something else.
"""
struct Attach <: Action end

"""
    struct Close <: Action end

`Close` something.
"""
struct Close <: Action end

"""
    struct Dress <: Action end

`Dress` someone in something.
"""
struct Dress <: Action end

"""
    struct Drop <: Action end

`Drop` something.
"""
struct Drop <: Action end

"""
    struct Eat <: Action end

`Eat` something.
"""
struct Eat <: Action end

"""
    struct Give <: Action end

`Give` something to someone.
"""
struct Give <: Action end

"""
    struct Go <: Action end

`Go` some way.
"""
struct Go <: Action end

"""
    struct GoInto <: Action end

Go into something.
"""
struct GoInto <: Action end

"""
    struct GoOnto <: Action end

Go onto something.
"""
struct GoOnto <: Action end

"""
    struct Leave <: Action end

Leave something.
"""
struct Leave <: Action end

"""
    struct ListInventory <: Action end

List your inventory.
"""
struct ListInventory <: Action end

"""
    struct Lock <: Action end

Lock something with something.
"""
struct Lock <: Action end

"""
    struct LookAt <: Action end

Look at something.
"""
struct LookAt <: Action end

"""
    struct Open <: Action end

Open something.
"""
struct Open <: Action end

"""
    struct Push <: Action end

Push something some way.
"""
struct Push <: Action end

"""
    struct PutInto <: Action end

Put something into something.
"""
struct PutInto <: Action end

"""
    struct PutOnto <: Action end

Put something onto something
"""
struct PutOnto <: Action end

"""
    struct Quit <: Action end

Quit
"""
struct Quit <: Action end

"""
    struct Take <: Action end

Take something
"""
struct Take <: Action end

"""
    struct TurnOn <: Action end

Turn something on
"""
struct TurnOn <: Action end

"""
    struct TurnOff <: Action end

Turn something off
"""
struct TurnOff <: Action end

"""
    struct Unlock <: Action end

Unlock something
"""
struct Unlock <: Action end

"""
    struct Wear <: Action end

Wear something.
"""
struct Wear <: Action end

"""
    @enum GrammaticalPerson first_person second_person third_person

Grammatical person
"""
@enum GrammaticalPerson first_person second_person third_person

"""
    abstract type Noun end

Nouns must have the following fields:

- `name::String`
- `plural::Bool`
- `grammatical_person::GrammaticalPerson`
- `indefinite_article::String`

They are characterized by the following traits and methods:

  - [`ever_possible`](@ref)
  - [`get_description`](@ref),
  - [`is_providing_light`](@ref),
  - [`is_transparent`](@ref),
  - [`is_vehicle`](@ref).

Set `indefinite_article` to `""` for proper nouns.
"""
abstract type Noun end

"""
    get_description(universe, thing::Noun) = thing.description

Get the description of a thing.

Unless you overload `get_description`, nouns are required to have a description field.
"""
get_description(_, thing::Noun) = thing.description

"""
    is_transparent(thing::Noun) = false

Whether you can see through `thing` into its contents.
"""
is_transparent(::Noun) = false

"""
    is_vehicle(::Noun) = false

Whether something is a vehicle.
"""
is_vehicle(::Noun) = false

"""
    is_providing_light(::Noun) = false

Whether something provides its own light. Naturally lit locations and light sources both are providing light.
"""
is_providing_light(::Noun) = false

"""
    ever_possible(action::Action, domain::Domain, noun::Noun)

Whether is is abstractly possible to apply an [`Action`](@ref) to a [`Noun`](@ref) from a particular [`Domain`](@ref).

For whether it is concretely possible for the player in at a certain moment, see [`possible_now`](@ref).
Most possibilities default to `false`, with some exceptions:

```
ever_possible(::PutInto, ::Inventory, _) = true
ever_possible(::Drop, ::Inventory, _) = true
ever_possible(::PutOnto, ::Inventory, _) = true
ever_possible(action::TurnOff, domain::Reachable, noun) = 
    ever_possible(TurnOn(), domain, noun)
ever_possible(action::Close, domain::Reachable, noun) = 
    ever_possible(Open(), domain, noun)
ever_possible(action::Lock, domain::Reachable, noun) = 
    ever_possible(Unlock(), domain, noun)
ever_possible(::Lock, domain::Inventory, noun) = 
    ever_possible(Unlock(), domain, noun)
```

Certain possibilities come with required fields:

- `ever_possible(::TurnOn, ::Reachable, noun)` requires that `noun` has a mutable `on::Bool` field.
- `ever_possible(::Open, ::Reachable, noun` requires that `noun` has a mutable `closed::Bool` field.
- `ever_possible(::Unlock, ::Reachable, noun)` requires that `noun` has a `key::Noun` field and a mutable `locked::Bool` field.
- `ever_possible(::Take, ::Reachable, noun)` requires that `noun` has a mutable `handled::Bool` field.
"""
ever_possible(_, __, ___) = false

# you possible_now put or drop anything in your inventory
ever_possible(::PutInto, ::Inventory, _) = true
ever_possible(::Drop, ::Inventory, _) = true
ever_possible(::PutOnto, ::Inventory, _) = true
ever_possible(::TurnOff, domain::Reachable, noun) = ever_possible(TurnOn(), domain, noun)
ever_possible(::Close, domain::Reachable, noun) = ever_possible(Open(), domain, noun)
ever_possible(::Lock, domain::Reachable, noun) = ever_possible(Unlock(), domain, noun)
ever_possible(::Lock, domain::Inventory, noun) = ever_possible(Unlock(), domain, noun)

struct Verb
    base::String
    third_person_singular_present::String
end

"""
    function Verb(base; third_person_singular_present = string(base, "s"))

Create an English verb.

Use [`subject_to_verb`](@ref) to get the form of a verb to agree with a subject.
"""
function Verb(base; third_person_singular_present = string(base, "s"))
    Verb(base, third_person_singular_present)
end

"""
    const VERB_FOR = Dict{Relationship, Verb}

Get the verb form of a [`Relationship`](@ref), or roughly, remove the `ing`.
"""
const VERB_FOR = Dict{Relationship, Verb}(
    carrying => Verb("carry"; third_person_singular_present = "carries"),
    containing => Verb("contain"),
    incorporating => Verb("incorporate"),
    supporting => Verb("support"),
    wearing => Verb("wear"),
)

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

"""
    abstract type Location <: Noun end

A location (room or door)
"""
abstract type Location <: Noun end

"""
    abstract type AbstractRoom <: Location end

Must have a mutable `visited` field.
"""
abstract type AbstractRoom <: Location end

"""
An abstract door
"""
abstract type AbstractDoor <: Location end

struct Universe
    player::Noun
    interface::TTYTerminal
    introduction::String
    relationships_graph::typeof(MetaGraph(DiGraph(), Label = Noun, EdgeMeta = Relationship))
    directions_graph::typeof(MetaGraph(DiGraph(), Label = Location, EdgeMeta = Direction))
    choices_log::Vector{Int}
end

"""
    function Universe(
        player;
        interface = terminal,
        introduction = "",
        relationships_graph = MetaGraph(DiGraph(), Label = Noun, EdgeMeta = Relationship),
        directions_graph = MetaGraph(DiGraph(), Label = Location, EdgeMeta = Direction),
        choices_log::Vector{Int}
    )

The universe contains a player, a text interface, an introduction, and the relationships between [`Noun`](@ref)s and [`Location`]s(@ref).

The universe is organized as interlinking web of locations connected by [`Direction`](@ref)s.
Each location is the root of a [`Relationship`](@ref) tree. 
Every noun should have one and only one parent (except for [`Location`]s(@ref)), which are at the root of trees and have no parent.

You can add a new thing to the `universe`, or change the location of something, by specifying its relation to another thing:

    universe[parent_thing, thing, silent = false] = relationship

Set `silent = true` to suppress the "Ok" message.

You possible_now add a connection between locations too, optionally interspersed by a door:

    universe[parent_thing, destination, one_way = false] = direction
    universe[parent_thing, destination, one_way = false] = door, direction

By default, this will create a way back in the [`opposite`](@ref) direction. To suppress this, set `one_way = true`
"""
function Universe(
    player;
    interface = terminal,
    introduction = "",
    relationships_graph = MetaGraph(DiGraph(), Label = Noun, EdgeMeta = Relationship),
    directions_graph = MetaGraph(DiGraph(), Label = Location, EdgeMeta = Direction),
    choices_log = Int[],
)
    Universe(
        player,
        interface,
        introduction,
        relationships_graph,
        directions_graph,
        choices_log,
    )
end

function get_parent(universe, thing)
    relationships_graph = universe.relationships_graph
    label_for(
        relationships_graph,
        only(inneighbors(relationships_graph, code_for(relationships_graph, thing))),
    )
end

function get_parent_relationship(universe, thing)
    relationships_graph = universe.relationships_graph
    parent = get_parent(universe, thing)
    parent, relationships_graph[parent, thing]
end

function over_out_neighbor_codes(a_function, meta_graph, parent_thing)
    Iterators.map(a_function, outneighbors(meta_graph, code_for(meta_graph, parent_thing)))
end

function out_neighbors(meta_graph, parent_thing)
    over_out_neighbor_codes(function (code)
        label_for(meta_graph, code)
    end, meta_graph, parent_thing)
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

function blocking_thing_and_relationship(universe, ::Reachable)
    # you can't reach outside of the thing that you are in/on/etc.
    get_parent_relationship(universe, universe.player)
end

function blocking_thing_and_relationship(universe, domain::Visible)
    relationships_graph = universe.relationships_graph
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

function mover(universe)
    player = universe.player
    relationships_graph = universe.relationships_graph
    blocking_thing, blocked_relationship = get_parent_relationship(universe, player)
    if is_vehicle(blocking_thing)
        blocking_thing
    else
        player
    end
end

function blocking_thing_and_relationship(universe, ::ExitDirections)
    relationships_graph = universe.relationships_graph
    get_parent_relationship(universe, mover(universe))
end

function get_first_destination(universe, blocking_thing, direction)
    only(Iterators.filter(
        function ((location, possible_direction),)
            possible_direction === direction
        end,
        out_neighbors_relationships(universe.directions_graph, blocking_thing),
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
    universe::Universe,
    relationship::Relationship,
    parent_thing::Noun,
    thing::Noun;
    silent = false,
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
    if !silent
        success(universe)
    end
    nothing
end

function one_way!(
    universe::Universe,
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
    universe::Universe,
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
    universe::Universe,
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
    universe::Universe,
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

function show(io::IO, relationship_or_direction::Union{Relationship, Direction})
    print(io, replace(string(relationship_or_direction), '_' => '-'))
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
            elseif grammmatical_person === first_person
                if is_subject
                    maybe_capitalize(capitalize, "I")
                else
                    subject = get(io, :subject, nothing)
                    if subject === thing
                        maybe_capitalize(capitalize, "myself")
                    else
                        maybe_capitalize(capitalize, "me")
                    end
                end
            else
                error("Unsupported grammatical person")
            end
        )
    end
end

function string_in_color(color, arguments...)
    string(text_colors[color], arguments..., text_colors[:default])
end

function success(universe)
    println(universe.interface, "Ok")
end

function (::Attach)(universe, thing, parent_thing)
    universe[parent_thing, thing] = incorporating
    return false
end

"""
    function print_sentence(io, action::Action, argument_texts...)

Print a sentence to `io`. This allows for adding connectives like `with`.
"""
function print_sentence(io, ::Attach, thing_text, parent_thing_text)
    print(io, "Attach ")
    print(io, thing_text)
    print(io, " to ")
    print(io, parent_thing_text)
end

function (::Dress)(universe, parent_thing, thing)
    universe[parent_thing, thing] = wearing
    return false
end

function print_sentence(io, ::Dress, parent_thing_text, thing_text)
    print(io, "Dress ")
    print(io, parent_thing_text)
    print(io, " in ")
    print(io, thing_text)
end

function (::Give)(universe, thing, parent_thing)
    universe[parent_thing, thing] = carrying
    return false
end

function print_sentence(io, ::Give, thing_text, parent_thing_text)
    print(io, "Give ")
    print(io, thing_text)
    print(io, " to ")
    print(io, parent_thing_text)
end

function (::PutOnto)(universe, thing, parent_thing)
    universe[parent_thing, thing] = supporting
    return false
end

function print_sentence(io, ::PutOnto, thing_text, parent_thing_text)
    print(io, "Put ")
    print(io, thing_text)
    print(io, " onto ")
    print(io, parent_thing_text)
end

function (::PutInto)(universe, thing, parent_thing; silent = false)
    universe[parent_thing, thing, silent = silent] = containing
    return false
end

function print_sentence(io, ::PutInto, thing_text, parent_thing_text)
    print(io, "Put ")
    print(io, thing_text)
    print(io, " into ")
    print(io, parent_thing_text)
end

# add relations to player
function (::GoInto)(universe, place)
    PutInto()(universe, mover(universe), place)
    return false
end

function print_sentence(io, ::GoInto, place_text)
    print(io, "Go into ")
    print(io, place_text)
end

function (::GoOnto)(universe, place)
    PutOnto()(universe, mover(universe), place)
    return false
end

function print_sentence(io, ::GoOnto, place_text)
    print(io, "Go onto ")
    print(io, place_text)
end

function (::Take)(universe, thing)
    Give()(universe, thing, universe.player)
    thing.handled = true
    false
end

function print_sentence(io, ::Take, thing_text)
    print(io, "Take ")
    print(io, thing_text)
end

function (::Wear)(universe, thing)
    Dress()(universe, universe.player, thing)
end

function print_sentence(io, ::Wear, thing_text)
    print(io, "Wear ")
    print(io, thing_text)
end

# miscellaneous
function (::Close)(universe, thing)
    thing.closed = true
    success(universe)
    return false
end

function print_sentence(io, ::Close, thing_text)
    print(io, "Close ")
    print(io, thing_text)
end

function (::Drop)(universe, thing)
    universe[get_parent(universe, universe.player), thing] = containing
    return false
end

function print_sentence(io, ::Drop, thing_text)
    print(io, "Drop ")
    print(io, thing_text)
end

function (::Eat)(universe, thing)
    delete!(universe.relationships_graph, get_parent(universe, thing), thing)
    success(universe)
    return false
end

function print_sentence(io, ::Eat, thing_text)
    print(io, "Eat ")
    print(io, thing_text)
end

function (::Go)(universe, direction)
    GoInto()(universe, get_final_destination(universe, direction))
end

function print_sentence(io, ::Go, direction_text)
    print(io, "Go ")
    print(io, direction_text)
end

function (::Lock)(universe, door, key)
    if door.key === key
        door.locked = true
        success(universe)
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

function print_sentence(io, ::Lock, door_text, key_text)
    print(io, "Lock ")
    print(io, door_text)
    print(io, " with ")
    print(io, key_text)
end

function (::Leave)(universe)
    player = universe.player
    relationships_graph = universe.relationships_graph
    parent_thing = get_parent(universe, player)
    grandparent_thing, parent_relationship = get_parent_relationship(universe, parent_thing)
    universe[grandparent_thing, player] = parent_relationship
    return false
end

function print_sentence(io, ::Leave)
    print(io, "Leave")
end

function (::ListInventory)(universe)
    player = universe.player
    interface = universe.interface
    relations = OrderedDict{Relationship, Vector{Answer}}()
    for (thing, relationship) in
        out_neighbors_relationships(universe.relationships_graph, player)
        # we automatically mention everything that is visible
        push!(get!(relations, relationship, Answer[]), make_answer(player, thing))
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

function (::LookAt)(universe, thing)
    println_wrapped(
        universe.interface,
        get_description(universe, thing);
        replace_whitespace = false,
    )
    return false
end

function print_sentence(io, ::LookAt, thing_text)
    print(io, "Look at ")
    print(io, thing_text)
end

function (action::Open)(universe, parent_thing)
    parent_thing.closed = false
    success(universe)
    if !(parent_thing isa Location)
        interface = universe.interface
        relations = OrderedDict{Relationship, Vector{Answer}}()
        for (thing, relationship) in
            out_neighbors_relationships(universe.relationships_graph, parent_thing)
            if relationship === containing
                # we automatically mention everything that is visible
                push!(get!(relations, relationship, Answer[]), make_answer(universe.player, thing))
            end
        end

        println(interface)
        show(IOContext(interface, :capitalize => true, :is_subject => true), parent_thing)
        if isempty(relations)
            print(interface, ' ')
            print(interface, subject_to_verb(parent_thing, BE))
            print(interface, " empty")
        else
            print(interface, ':')
            println(interface)
            print_relations(universe, 0, Visible(), parent_thing, relations)
        end
    end
    return false
end

function print_sentence(io, ::Open, thing_text)
    print(io, "Open ")
    print(io, thing_text)
end

function (::Push)(universe, thing, direction)
    final_destination = get_final_destination(universe, direction)
    PutInto()(universe, thing, final_destination; silent = true)
    Go()(universe, final_destination)
end

function print_sentence(io, ::Push, thing_text, direction_text)
    print(io, "Push ")
    print(io, thing_text)
    print(io, direction_text)
end

function (::Quit)(_)
    return true
end

function print_sentence(io, ::Quit)
    print(io, "Quit")
end

function (::TurnOff)(universe, thing)
    thing.on = false
    success(universe)
    return false
end

function print_sentence(io, ::TurnOff, thing_text)
    print(io, "Turn off ")
    print(io, thing_text)
end

function (::TurnOn)(universe, thing)
    thing.on = true
    success(universe)
    return false
end

function print_sentence(io, ::TurnOn, thing_text)
    print(io, "Turn on ")
    print(io, thing_text)
end

function (::Unlock)(universe, door, key)
    if door.key === key
        door.locked = false
        success(universe)
    else
        println_wrapped(
            universe.interface,
            string_in_color(:red, uppercasefirst(string(key)), " doesn't fit!"),
        )
    end
    return false
end

function print_sentence(io, ::Unlock, door_text, key_text)
    print(io, "Unlock ")
    print(io, door_text)
    print(io, " with ")
    print(io, key_text)
end

mutable struct Answer
    text::String
    # could be an noun, a direction, or another question
    object::Any
end

function make_answer(subject, thing)
    buffer = IOBuffer()
    # things will have already been mentioned in the room descrption
    show(IOContext(buffer, :known => true, :is_subject => false, :subject => subject), thing)
    Answer(String(take!(buffer)), thing)
end

mutable struct Question
    text::String
    answers::Vector{Answer}
end

struct Sentence{Action}
    action::Action
    arguments::Vector{Answer}
end

function Sentence(action::Action; arguments = Answer[])
    Sentence(action, arguments)
end

function string_relationship_to(subject, thing_text, relationship, parent_thing)
    buffer = IOBuffer()
    io = IOContext(buffer, :known => true, :is_subject => false, :subject => subject)
    if relationship === carrying
        print(io, thing_text)
        print(io, ' ')
        print(io, "that ")
        show(IOContext(io, :is_subject => true), parent_thing)
        print(io, ' ')
        print(io, subject_to_verb(parent_thing, BE))
        print(io, " carrying")
    elseif relationship === containing
        print(io, thing_text)
        print(io, ' ')
        print(io, "in ")
        show(io, parent_thing)
    elseif relationship === incorporating
        print(io, thing_text)
        print(io, ' ')
        print(io, "attached to ")
        show(io, parent_thing)
    elseif relationship === supporting
        print(io, thing_text)
        print(io, ' ')
        print(io, "on ")
        show(io, parent_thing)
    elseif relationship === wearing
        print(io, thing_text)
        print(io, ' ')
        print(io, "that ")
        show(IOContext(io, :known => true, :is_subject => true), parent_thing)
        print(io, ' ')
        print(io, subject_to_verb(parent_thing, BE))
        print(io, " wearing")
    else
        print(io, thing_text)
        print(io, ' ')
        print(io, "to the ")
        show(io, relationship)
        print(io, " of ")
        show(io, parent_thing)
    end
    String(take!(buffer))
end

function print_relationship_as_verb(io, parent_thing, relationship::Relationship)
    print(io, subject_to_verb(parent_thing, VERB_FOR[relationship]))
end

function print_relationship_as_verb(io, _, direction::Direction)
    show(io, direction)
end

function is_closable_and_closed(thing)
    ever_possible(Close(), Reachable(), thing) && thing.closed
end

function is_lockable_and_locked(thing)
    ever_possible(Lock(), Reachable(), thing) && thing.locked
end

"""
    blocking(domain, parent_thing, relationship, thing)

`parent_thing` is blocked from accessing `thing` via the `relationship`.

By default, [`Reachable`](@ref) `parent_thing`s block `thing`s they are `containing` if they are closed.
By default, [`Visible`](@ref) `parent_thing`s block `thing`s they are `containing` if they are closed and not [`is_transparent`](@ref).
"""
function blocking(::Reachable, parent_thing, relationship, _)
    relationship === containing && is_closable_and_closed(parent_thing)
end

function blocking(::Visible, parent_thing, relationship, thing)
    blocking(Reachable(), parent_thing, relationship, thing) &&
        !(is_transparent(parent_thing))
end

"""
    possible_now(universe, sentence, domain, thing)

Whether it is currently possible to apply `sentence.action` to a `thing` in a `domain`.

See [`ever_possible`](@ref) for a more abstract possibility. `sentence` will contain already chosen
arguments, should you wish to access them.
"""
function possible_now(_, sentence, domain, thing)
    ever_possible(sentence.action, domain, thing)
end

function possible_now(_, sentence::Sentence{Close}, domain::Reachable, thing)
    ever_possible(sentence.action, domain, thing) && !(thing.closed)
end

function possible_now(universe, ::Sentence{<:Union{Go, Push}}, ::ExitDirections, direction)
    !(is_closable_and_closed(get_first_destination(universe, direction)))
end

function possible_now(universe, sentence::Sentence{GoInto}, domain::MoveSiblings, thing)
    get_parent(universe, universe.player) !== thing && ever_possible(sentence.action, domain, thing) && !(is_closable_and_closed(thing))
end

function possible_now(universe, sentence::Sentence{PutOnto}, domain::MoveSiblings, thing)
    get_parent(universe, universe.player) !== thing && ever_possible(sentence.action, domain, thing)
end
function possible_now(_, sentence::Sentence{Lock}, domain::Reachable, thing)
    MenuAdventures.is_closable_and_closed(thing) &&
        MenuAdventures.ever_possible(sentence.action, domain, thing) &&
        !(thing.locked)
end

function possible_now(universe, ::Sentence{LookAt}, ::Visible, thing)
    get_description(universe, thing) != ""
end

function possible_now(_, ::Sentence{Open}, ::Reachable, thing)
    is_closable_and_closed(thing) && !(is_lockable_and_locked(thing))
end

function possible_now(_, sentence::Sentence{PutInto}, domain::Reachable, thing)
    ever_possible(sentence.action, domain, thing) &&
        !(is_closable_and_closed(thing)) &&
        # possible_now't put something into itself
        thing !== sentence.arguments[1].object
end

function possible_now(universe, sentence::Sentence{Take}, domain::Reachable, thing)
    if thing isa Location
        false
    else
        parent_thing, relationship = get_parent_relationship(universe, thing)
        ever_possible(sentence.action, domain, thing) &&
            !(parent_thing === universe.player && relationship === carrying)
    end
end

function possible_now(_, sentence::Sentence{TurnOff}, domain::Reachable, thing)
    ever_possible(sentence.action, domain, thing) && thing.on
end

function possible_now(_, sentence::Sentence{TurnOn}, domain::Reachable, thing)
    ever_possible(sentence.action, domain, thing) && !(thing.on)
end

function possible_now(_, sentence::Sentence{Unlock}, domain::Reachable, thing)
    is_closable_and_closed(thing) &&
        ever_possible(sentence.action, domain, thing) &&
        thing.locked
end

function possible_now(universe, sentence::Sentence{Wear}, domain::Inventory, thing)
    _, relationship = get_parent_relationship(universe, thing)
    ever_possible(sentence.action, domain, thing) && !(relationship == wearing)
end

function append_parent_relationship_to(_, noun::Noun, __, ___)
    noun
end

function append_parent_relationship_to(subject, answer::Answer, relationship, parent_thing)
    Answer(
        string_relationship_to(subject, answer.text, relationship, parent_thing),
        append_parent_relationship_to(subject, answer.object, relationship, parent_thing),
    )
end

function append_parent_relationship_to(subject, question::Question, relationship, parent_thing)
    Question(
        string_relationship_to(subject, question.text, relationship, parent_thing),
        map(
            function (answer)
                append_parent_relationship_to(subject, answer, relationship, parent_thing)
            end,
            question.answers,
        ),
    )
end

function indefinite_for(__)
    "something"
end
function interrogative_for(__)
    "what"
end
function indefinite_for(::ExitDirections)
    "some way"
end
function interrogative_for(::ExitDirections)
    "which way"
end

function add_thing_and_relations!(answers, universe, sentence, domain, parent_thing)
    action = sentence.action
    if possible_now(universe, sentence, domain, parent_thing)
        push!(answers, make_answer(universe.player, parent_thing))
    end
    sub_relations = OrderedDict{Relationship, Vector{Answer}}()
    for (thing, relationship) in
        out_neighbors_relationships(universe.relationships_graph, parent_thing)
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
                    universe.player,
                    if length(sub_answers) == 1
                        only(sub_answers)
                    else
                        Answer(
                            MenuAdventures.indefinite_for(domain),
                            Question(interrogative_for(domain), sub_answers),
                        )
                    end,
                    sub_relationship,
                    parent_thing,
                ),
            )
        end
    end
end

function add_siblings_and_doors!(answers, universe, sentence, domain)
    blocking_thing, blocked_relationship = blocking_thing_and_relationship(universe, domain)
    for (thing, relationship) in
        out_neighbors_relationships(universe.relationships_graph, blocking_thing)
        if relationship === blocked_relationship
            add_thing_and_relations!(answers, universe, sentence, domain, thing)
        end
    end
    directions_graph = universe.directions_graph
    if haskey(directions_graph, blocking_thing)
        for (location, direction) in
            out_neighbors_relationships(directions_graph, blocking_thing)
            if location isa AbstractDoor
                add_thing_and_relations!(answers, universe, sentence, domain, location)
            end
        end
    end
end

function find_in_domain(universe, sentence, domain::Visible; lit = true)
    answers = Answer[]
    if lit
        add_siblings_and_doors!(answers, universe, sentence, domain)
    end
    answers
end

function find_in_domain(universe, sentence, domain::Reachable; lit = true)
    answers = Answer[]
    if lit
        add_siblings_and_doors!(answers, universe, sentence, domain)
    else
        for (thing, relationship) in
            out_neighbors_relationships(universe.relationships_graph, universe.player)
            add_thing_and_relations!(answers, universe, sentence, domain, thing)
        end
    end
    answers
end

function find_in_domain(universe, sentence, domain::ExitDirections; lit = true)
    blocking_thing, _ = blocking_thing_and_relationship(universe, domain)
    answers = Answer[]
    directions_graph = universe.directions_graph
    if haskey(directions_graph, blocking_thing)
        for (location, direction) in
            out_neighbors_relationships(universe.directions_graph, blocking_thing)
            if possible_now(universe, sentence, domain, direction)
                push!(answers, make_answer(universe.player, direction))
            end
        end
    end
    answers
end

function find_in_domain(universe, sentence, domain::MoveSiblings; lit = true)
    answers = Answer[]
    blocking_thing, blocked_relationship =
        blocking_thing_and_relationship(universe, ExitDirections())
    if lit
        for (thing, relationship) in
            out_neighbors_relationships(universe.relationships_graph, blocking_thing)
            if relationship === blocked_relationship &&
               possible_now(universe, sentence, domain, thing)
                push!(answers, make_answer(universe.player, thing))
            end
        end
    end
    answers
end

function find_in_domain(universe, sentence, domain::Inventory; lit = true)
    answers = Answer[]
    for (thing, relationship) in
        out_neighbors_relationships(universe.relationships_graph, universe.player)
        if relationship === carrying && possible_now(universe, sentence, domain, thing)
            push!(answers, make_answer(universe.player, thing))
        end
    end
    answers
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
                    out_neighbors_relationships(universe.relationships_graph, thing)
                    if !(blocking(domain, thing, sub_relationship, sub_thing))
                        # we automatically mention everything that is visible
                        push!(
                            get!(sub_relations, sub_relationship, Answer[]),
                            make_answer(universe.player, sub_thing),
                        )
                    end
                end
            end
            print(interface, ' '^sub_indent)
            show(IOContext(interface, :known => false, :is_subject => false, :subject => parent_thing), thing)
            if !isempty(sub_relations)
                print(interface, ':')
            end
            println(interface)
            print_relations(universe, sub_indent, domain, thing, sub_relations)
        end
    end
end

function print_environment(universe; indent = 0, domain = Visible())
    interface = universe.interface
    blocking_thing, blocked_relationship = blocking_thing_and_relationship(universe, domain)
    relations = OrderedDict{Union{Relationship, Direction}, Vector{Answer}}()
    for (thing, relationship) in
        out_neighbors_relationships(universe.relationships_graph, blocking_thing)
        if relationship === blocked_relationship
            # we automatically mention everything that is visible
            push!(get!(relations, relationship, Answer[]), make_answer(universe.player, thing))
        end
    end
    directions_graph = universe.directions_graph
    if haskey(directions_graph, blocking_thing)
        for (location, direction) in
            out_neighbors_relationships(directions_graph, blocking_thing)
            if location isa AbstractDoor
                push!(get!(relations, direction, Answer[]), make_answer(universe.player, location))
            end
        end
    end
    print(interface, ' '^indent)
    show(IOContext(interface, :known => false, :is_subject => true), blocking_thing)
    if !isempty(relations)
        print(interface, ':')
    end
    println(interface)
    print_relations(universe, indent, domain, blocking_thing, relations)
    description = get_description(universe, blocking_thing)
    if !isempty(description)
        println(interface)
        println_wrapped(interface, description)
    end
end

"""
    function argument_domains(action::Action)

A tuple of the [`Domain`](@ref)s for each argument of an [`Action`](@ref).
"""
function argument_domains(::Union{Attach, Give})
    Inventory(), Reachable()
end
function argument_domains(::Union{Close, Eat, Open, Take, TurnOn, TurnOff})
    (Reachable(),)
end
function argument_domains(::Union{Drop, Wear})
    (Inventory(),)
end
function argument_domains(::Go)
    (ExitDirections(),)
end
function argument_domains(::Union{GoInto, GoOnto})
    (MoveSiblings(),)
end
function argument_domains(::Union{ListInventory, Quit})
    ()
end
function argument_domains(::PutOnto)
    Inventory(), Reachable()
end
function argument_domains(::Leave)
    ()
end
function argument_domains(::Union{Dress, Lock, Unlock})
    Reachable(), Inventory()
end
function argument_domains(::LookAt)
    (Visible(),)
end
function argument_domains(::Push)
    MoveSiblings(), ExitDirections()
end
function argument_domains(::PutInto)
    Inventory(), Reachable()
end

"""
    possible_now(universe, action)

Whether it is possible to conduct an action.
Defaults to `true`; you can set to `false` for some actions without arguments.
"""
function possible_now(_, __)
    true
end
function possible_now(universe, ::Leave)
    !(get_parent(universe, universe.player) isa Location)
end
function possible_now(universe, ::ListInventory)
    !isempty(out_neighbors_relationships(universe.relationships_graph, universe.player))
end

function choose(universe, sentence, index, answer)
    interface = universe.interface
    object = answer.object
    if object isa Question
        answers = object.answers
        println(interface)
        # add an exta line to add space before the question
        # we need take it first to see if its empty or not
        choice = request(
            interface,
            sprint(
                show,
                replace_argument(sentence, index, object.text);
                context = :suffix => "?"
            ),
            RadioMenu(map(
                function (sub_answer)
                    string(replace_argument(sentence, index, sub_answer.text))
                end,
                answers,
            )),
        )
        push!(universe.choices_log, choice)
        choose(universe, sentence, index, answers[choice])
    else
        answer
    end
end

function show(io::IO, sentence::Sentence)
    print(io, text_colors[:green])
    print_sentence(
        io,
        sentence.action,
        Iterators.map(function (answer)
            answer.text
        end, sentence.arguments)...,
    )
    print(io, get(io, :suffix, ""))
    print(io, text_colors[:default])
end

function replace_argument(sentence, blank_index, replacement)
    arguments_copy = copy(sentence.arguments)
    arguments_copy[blank_index] = Answer(replacement, nothing)
    Sentence(sentence.action, arguments_copy)
end

function is_player_lit(universe; domain = Visible())
    blocking_thing, blocked_relationship = blocking_thing_and_relationship(universe, domain)
    if is_providing_light(blocking_thing)
        true
    else
        for (thing, relationship) in
            out_neighbors_relationships(universe.relationships_graph, blocking_thing)
            if relationship === blocked_relationship &&
               is_lit(universe, thing; domain = domain)
                return true
            end
        end
        false
    end
end

function is_lit(universe, parent_thing; domain = Visible())
    if is_providing_light(parent_thing)
        true
    else
        for (thing, relationship) in
            out_neighbors_relationships(universe.relationships_graph, parent_thing)
            if !(blocking(domain, parent_thing, relationship, thing))
                if is_lit(universe, thing)
                    return true
                end
            end
        end
        false
    end
end

"""
    turn!(universe; introduce = false, should_look_around = false)

Start a turn in the [`Universe`](@ref), and keep going until the user wins or quits.
"""
function turn!(universe; introduce = false, should_look_around = false)
    interface = universe.interface
    relationships_graph = universe.relationships_graph
    player = universe.player

    if introduce
        introduction = universe.introduction
        if introduction != ""
            println_wrapped(interface, introduction; replace_whitespace = false)
        end
    end

    # reintroduce the player to their surroundings if the end the turn in a new loaction
    lit = is_player_lit(universe)

    if should_look_around
        println(interface)
        if lit
            print_environment(universe)
        else
            println_wrapped(interface, "In darkness")
        end
    end

    immediate_location = get_parent(universe, universe.player)
    if !immediate_location.visited
        immediate_location.visited = true
    end
    sentences = Sentence[]
    for verb_type in subtypes(Action)
        action = verb_type()
        sentence = Sentence(action)
        dead_end = false
        for domain in argument_domains(action)
            # returns true for impossible arguments
            answers = find_in_domain(universe, sentence, domain; lit = lit)
            if isempty(answers)
                dead_end = true
                break
            else
                push!(
                    sentence.arguments,
                    if length(answers) == 1
                        only(answers)
                    else
                        Answer(
                            indefinite_for(domain),
                            Question(interrogative_for(domain), answers),
                        )
                    end,
                )
            end
        end
        if possible_now(universe, action) && !dead_end
            push!(sentences, sentence)
        end
    end

    choice = request(interface, "", RadioMenu(map(string, sentences)))
    push!(universe.choices_log, choice)

    sentence = sentences[choice]
    arguments = sentence.arguments

    for (index, argument) in enumerate(arguments)
        arguments[index] = choose(universe, sentence, index, argument)
    end
    end_game = sentence.action(universe, Iterators.map(function (answer)
        answer.object
    end, arguments)...)
    if !end_game
        turn!(
            universe;
            should_look_around = (get_parent(universe, universe.player) !==
                                 immediate_location) || (is_player_lit(universe) != lit)
        )
    end
    nothing
end

@kwdef mutable struct Door <: AbstractDoor
    name::String
    key::Noun
    closed::Bool = true
    description::String = ""
    grammatical_person::GrammaticalPerson = third_person
    indefinite_article::String = "a"
    locked::Bool = true
    plural::Bool = false
end

ever_possible(::Open, ::Reachable, ::Door) = true
ever_possible(::Unlock, ::Reachable, ::Door) = true

@kwdef struct Person <: Noun
    name::String
    description::String = ""
    grammatical_person::GrammaticalPerson = third_person
    indefinite_article::String = "a"
    plural::Bool = false
end

@kwdef mutable struct Key <: Noun
    name::String
    description::String = ""
    grammatical_person::GrammaticalPerson = third_person
    handled::Bool = false
    indefinite_article::String = "a"
    plural::Bool = false
end

ever_possible(::Unlock, ::Inventory, ::Key) = true
ever_possible(::Take, ::Reachable, ::Key) = true

@kwdef mutable struct Lamp <: Noun
    name::String
    description::String = ""
    grammatical_person::GrammaticalPerson = third_person
    handled::Bool = false
    indefinite_article::String = "a"
    on::Bool = false
    plural::Bool = false
end

ever_possible(::Take, ::Reachable, ::Lamp) = true
ever_possible(::TurnOn, ::Reachable, ::Lamp) = true
is_providing_light(noun::Lamp) = noun.on

@kwdef mutable struct Box <: Noun
    name::String
    closed::Bool = true
    description::String = ""
    grammatical_person::GrammaticalPerson = third_person
    handled::Bool = false
    indefinite_article::String = "a"
    plural::Bool = false
end

ever_possible(::Open, ::Reachable, ::Box) = true
ever_possible(::Take, ::Reachable, ::Box) = true
ever_possible(::PutInto, ::Reachable, ::Box) = true

@kwdef mutable struct Car <: Noun
    name::String
    description::String = ""
    grammatical_person::GrammaticalPerson = third_person
    indefinite_article::String = "a"
    plural::Bool = false
    visited::Bool = false
end

ever_possible(::GoInto, ::MoveSiblings, ::Car) = true
is_vehicle(::Car) = true
is_transparent(::Car) = true

@kwdef struct Table <: Noun
    name::String
    description::String = ""
    grammatical_person::GrammaticalPerson = third_person
    indefinite_article::String = "a"
    plural::Bool = false
end

ever_possible(::PutOnto, ::Reachable, ::Table) = true

@kwdef mutable struct Clothes <: Noun
    name::String
    description::String = ""
    grammatical_person::GrammaticalPerson = third_person
    handled::Bool = false
    indefinite_article::String = "a"
    plural::Bool = false
end

ever_possible(::Wear, ::Inventory, ::Clothes) = true
ever_possible(::Take, ::Reachable, ::Clothes) = true

@kwdef mutable struct Food <: Noun
    name::String
    description::String = ""
    grammatical_person::GrammaticalPerson = third_person
    handled = false
    indefinite_article::String = "a"
    plural::Bool = false
end

ever_possible(::Eat, ::Reachable, ::Food) = true
ever_possible(::Take, ::Reachable, ::Food) = true

@kwdef mutable struct Room <: AbstractRoom
    name::String
    description::String = ""
    grammatical_person::GrammaticalPerson = third_person
    indefinite_article::String = "a"
    plural::Bool = false
    providing_light::Bool = true
    visited::Bool = false
end

is_providing_light(room::Room) = room.providing_light

# TODO: try out porting Bronze to see what happens
# TODO: tests
# TODO: backdrops
# TODO: visible and reachable tests
# TODO: tell whether things are locked or closed
# TODO: take off?
# TODO: reshow environment when driving
# TODO: fix extra OKs

end
