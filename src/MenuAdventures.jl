module MenuAdventures

using LightGraphs: DiGraph, inneighbors, outneighbors
using MacroTools: @capture
using MetaGraphsNext: code_for, MetaGraph, label_for
using Base: disable_text_style, @kwdef, text_colors
import Base: setindex!, show
using REPL.Terminals: TTYTerminal
using REPL.TerminalMenus: RadioMenu, request, terminal
using TextWrap: println_wrapped

"""
    abstract type Domain end

A domain refers to a search space for a specific argument to a verb. 
    
For example, you are only able to look at things in the `Visible` domain.
Domains serve both as a way of distinguishing different arguments to a verb, and also, categorizing the environment around the player. 
Users could theoretically add a new domain. 
"""
abstract type Domain end

"""
    struct Reachable <: Domain end

Anything the player concretely_possible reach. 

Players concretely_possible't reach through closed containers by default.
"""
struct Reachable <: Domain end

"""
    struct Visible <: Domain end

Anything the player concretely_possible see. 

Players concretely_possible't see into closed, opaque containers.
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
    @enum Relationship carrying wearing containing incorporating supporting
    
Relationships show the relationshp of a `thing` to its `parent_thing`.
"""
@enum Relationship carrying wearing containing incorporating supporting

"""
    @enum Direction north south west east north_west north_east south_west south_east up down inside outside
    
Directions show the relationships between [`Location`](@ref)s. 

You concretely_possible use [`opposite`](@ref) to find the opposite of a direction.
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
    abstract type Verb end

A verb is an action the player concretely_possible take. 

It should be fairly easy to create new verbs: 
you will need to define [`abstractly_possible`](@ref) for abstract possibilities, 
[`concretely_possible`](@ref) for concrete possibilities,
[`argument_domains`](@ref) to specify the domain of the arguments, and 
[`print_sentence`](@ref) for printing the sentence. 

Most importantly, define:

```
function (::MyNewVerb)(universe, arguments...) -> Tuple{Bool, Bool}
```

Which will conduct the verb based on user choices. 
Must return tuple of bools. If the first one is true, on the next turn, the game will describe the player's environment again.
If the second one is true, the game will end at the end of the turn.
"""
abstract type Verb end

struct Attach <: Verb end
struct Close <: Verb end
struct Dress <: Verb end
struct Drop <: Verb end
struct Eat <: Verb end
struct Give <: Verb end
struct Go <: Verb end
struct GoInto <: Verb end
struct GoOnto <: Verb end
struct Leave <: Verb end
struct ListInventory <: Verb end
struct Lock <: Verb end
struct LookAt <: Verb end
struct Open <: Verb end
struct Push <: Verb end
struct Put <: Verb end
struct Lay <: Verb end
struct Quit <: Verb end
struct Take <: Verb end
struct TurnOn <: Verb end
struct TurnOff <: Verb end
struct Unlock <: Verb end
struct Wear <: Verb end

"""
    @enum GrammaticalPerson first_person second_person third_person

Grammatical person
"""
@enum GrammaticalPerson first_person second_person third_person

"""
    abstract type Noun end

Nouns must have the following fields:

name::String
plural::Bool
grammatical_person::GrammaticalPerson
indefinite_article::String

They are governed by the following traits and methods: 
[`get_description`](@ref), 
[`is_providing_light`](@ref), 
[`is_transparent`](@ref), 
[`abstractly_possible`](@ref), and 
[`is_vehicle`](@ref).

Set `indefinite_article` to `""` to make a proper noun.
"""
abstract type Noun end

"""
    get_description(universe, thing::Noun) = thing.description

Get the description of a thing.

Unless you overload `get_description`, nouns are required to have a description field.
"""
get_description(universe, thing::Noun) = thing.description

"""
    is_transparent(thing::Noun) = false

Whether you concretely_possible see through `thing` into its contents.
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
    abstractly_possible(verb::Verb, domain::Domain, noun::Noun)

Whether is is abstractly possible to apply a verb to a `noun` from a particular `domain`.

For whether it is concretely possible for the player in at a certain moment, see [`concretely_possible`](@ref). 
Most possibilities default to `false`, with some exceptions:

```
abstractly_possible(::Put, ::Inventory, _) = true
abstractly_possible(::Drop, ::Inventory, _) = true
abstractly_possible(::Lay, ::Inventory, _) = true
abstractly_possible(verb::TurnOff, domain::Reachable, noun) = 
    abstractly_possible(TurnOn(), domain, noun)
abstractly_possible(verb::Close, domain::Reachable, noun) = 
    abstractly_possible(Open(), domain, noun)
abstractly_possible(verb::Lock, domain::Reachable, noun) = 
    abstractly_possible(Unlock(), domain, noun)
```

Certain possibilities come with required fields:

`abstractly_possible(::TurnOn, ::Reachable, noun)` requires that `noun` has a mutable `on::Bool` field.
`abstractly_possible(::Open, ::Reachable, noun` requires that `noun` has a mutable `closed::Bool` field.
`abstractly_possible(::Unlock, ::Reachable, noun)` requires that `noun` has a  `key::Noun` field and a mutable `locked::Bool` field.
`abstractly_possible(::Take, ::Reachable, noun)` requires that `noun` has a `handled::Bool` field.
"""
abstractly_possible(_, __, ___) = false

# you concretely_possible put or drop anything in your inventory
abstractly_possible(::Put, ::Inventory, _) = true
abstractly_possible(::Drop, ::Inventory, _) = true
abstractly_possible(::Lay, ::Inventory, _) = true
abstractly_possible(verb::TurnOff, domain::Reachable, noun) = abstractly_possible(TurnOn(), domain, noun)
abstractly_possible(verb::Close, domain::Reachable, noun) = abstractly_possible(Open(), domain, noun)
abstractly_possible(verb::Lock, domain::Reachable, noun) = abstractly_possible(Unlock(), domain, noun)

struct VerbWord
    base::String
    third_person_singular_present::String
end

function VerbWord(act; third_person_singular_present = string(act, "s"))
    VerbWord(act, third_person_singular_present)
end

const VERB_FOR = Dict{Relationship, VerbWord}(
    carrying => VerbWord("carry"; third_person_singular_present = "carries"),
    containing => VerbWord("contain"),
    incorporating => VerbWord("incorporate"),
    supporting => VerbWord("support"),
    wearing => VerbWord("wear")
)

const DO = VerbWord("do"; third_person_singular_present = "does")
const BE = VerbWord("are"; third_person_singular_present = "is")

function match_verb_to_noun(subject, verb)
    if subject.grammatical_person === third_person && !(subject.plural)
        verb.third_person_singular_present
    else
        verb.base
    end
end

# all commands have the subject as "you", so is_argument usually means use the non-subject form
function pronoun_for(thing; is_argument = false)
    grammatical_person = thing.grammatical_person
    plural = thing.plural
    if grammatical_person === first_person
        if plural
            if is_argument
                "us"
            else
                "we"
            end
        else
            if is_argument
                "me"
            else
                "I"
            end
        end
    elseif grammatical_person === second_person
        if is_argument
            # since the subject is the second person, use the reflexive pronoun instead
            "yourself"
        else
            "you"
        end
    elseif grammatical_person === third_person
        if plural
            if is_argument
                "them"
            else
                "they"
            end
        else
            "it"
        end
    else
        error("No pronoun for $grammtical_person")
    end
end

"A location (room or door)"
abstract type Location <: Noun end

"""
    abstract type AbstractRoom <: Location end

Must have a mutable `visited` field.
"""
abstract type AbstractRoom <: Location end

"An abstract door"
abstract type AbstractDoor <: Location end

struct Universe
    player::Noun
    interface::TTYTerminal
    introduction::String
    relationships_graph::typeof(MetaGraph(DiGraph(), Label = Noun, EdgeMeta = Relationship))
    directions_graph::typeof(MetaGraph(DiGraph(), Label = Location, EdgeMeta = Direction))
end

"""
    function Universe(
        player;
        interface = terminal,
        introduction = "",
        relationships_graph = MetaGraph(DiGraph(), Label = Noun, EdgeMeta = Relationship),
        directions_graph = MetaGraph(DiGraph(), Label = Location, EdgeMeta = Direction)
    )

The universe contains a player, a text interface, and an introduction. 
The universe is organized as interlinking web of locations connected by [`Direction`](@ref)s. For any origin and
destination, there should be no more than one connection of a particular direction.
Each location is the root of a [`Relationship`](@ref) tree. Every noun should half one and only one parent, 
except for locations, which are at the root of trees.

You concretely_possible add a new thing to the universe, or change its location, by specifying relation to another thing:

    universe[parent_thing, thing, silent = false] = relationship

Set `silent = true` to suppress the "Ok" message.

You concretely_possible add a connection between locations too, optionally interspersed by a door:

    universe[origin, destination, one_way = false] = direction
    universe[origin, destination, one_way = false] = door, direction

By default, this will create a way back in the [`opposite`](@ref) direction. To suppress this, set `one_way = true`
"""
function Universe(
    player;
    interface = terminal,
    introduction = "",
    relationships_graph = MetaGraph(DiGraph(), Label = Noun, EdgeMeta = Relationship),
    directions_graph = MetaGraph(DiGraph(), Label = Location, EdgeMeta = Direction)
)
    Universe(player, interface, introduction, relationships_graph, directions_graph)
end

function get_parent(universe, thing)
    relationships_graph = universe.relationships_graph
    label_for(relationships_graph, only(inneighbors(relationships_graph, code_for(relationships_graph, thing))))
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
    over_out_neighbor_codes(
        function (code)
            label_for(meta_graph, code)
        end,
        meta_graph, parent_thing
    )
end

function out_neighbors_relationships(meta_graph, parent_thing)
    over_out_neighbor_codes(
        function (code)
            thing = label_for(meta_graph, code)
            thing, meta_graph[parent_thing, thing]
        end,
        meta_graph, parent_thing
    )
end

function get_origin_relationship(universe, ::Reachable)
    # you concretely_possible't reach outside of the thing that you are in/on/etc.
    get_parent_relationship(universe, universe.player)
end

function get_origin_relationship(universe, domain::Visible)
    relationships_graph = universe.relationships_graph
    thing = universe.player
    parent_thing, relationship = get_parent_relationship(universe, thing)
    # locations don't have a parent...
    while !(parent_thing isa Location) && !(blocking(domain, parent_thing, relationship, thing))
        thing = parent_thing
        parent_thing, relationship =
            get_parent_relationship(universe, thing)
    end
    parent_thing, relationship
end

function player_proxy(universe)
    player = universe.player
    relationships_graph = universe.relationships_graph
    parent_thing, relationship = get_parent_relationship(universe, player)
    if is_vehicle(parent_thing)
        parent_thing
    else
        player
    end
end

function get_origin_relationship(universe, domain::ExitDirections)
    relationships_graph = universe.relationships_graph
    get_parent_relationship(universe, player_proxy(universe))
end

function get_destination(universe, origin, direction)
    only(Iterators.filter(
        function ((location, possible_direction),)
            possible_direction === direction
        end,
        out_neighbors_relationships(universe.directions_graph, origin),
    ))[1]
end

function get_destination(universe, direction)
    origin, _ = get_origin_relationship(universe, ExitDirections())
    get_destination(universe, origin, direction)
end

function get_final_destination(universe, direction)
    origin, _ = get_origin_relationship(universe, ExitDirections())
    maybe_door = get_destination(universe, origin, direction)
    if maybe_door isa AbstractDoor
        get_destination(universe, maybe_door, direction)
    else
        maybe_door
    end
end

function setindex!(universe::Universe, relationship::Relationship, parent_thing::Noun, thing::Noun; silent = false)
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

function one_way!(universe::Universe, origin::Location, direction::Direction, destination::Location)
    relationships_graph = universe.relationships_graph
    relationships_graph[origin] = nothing
    relationships_graph[destination] = nothing
    directions_graph = universe.directions_graph
    directions_graph[origin] = nothing
    directions_graph[destination] = nothing
    directions_graph[origin, destination] = direction
    nothing
end

function one_way!(universe::Universe, origin::Location, door::AbstractDoor, direction::Direction, destination::Location)
    one_way!(universe, origin, direction, door)
    one_way!(universe, door, direction, destination)
    nothing
end

function setindex!(universe::Universe, direction::Direction, origin::Location, destination::Location; one_way = false)
    one_way!(universe, origin, direction, destination)
    if !one_way
        one_way!(universe, destination, opposite(direction), origin)
    end
end
function setindex!(universe::Universe, (door, direction)::Tuple{AbstractDoor, Direction}, origin::Location, destination::Location; one_way = false)
    one_way!(universe, origin, door, direction, destination)
    if !one_way
        one_way!(universe, destination, door, opposite(direction), origin)
    end
end

function show(io::IO, relationship_or_direction::Union{Relationship, Direction})
    print(io, replace(string(relationship_or_direction), '_' => '-'))
end

function show(io::IO, thing::Noun)
    if thing.grammatical_person === third_person
        indefinite_article = thing.indefinite_article
        if !isempty(indefinite_article)
            print(io, thing.name)
        else
            if get(io, :known, true)
                print(io, "the ")
                print(io, thing.name)
            else
                print(io, thing.indefinite_article)
                print(io, ' ')
                print(io, thing.name)
            end
        end
    else
        print(io, pronoun_for(thing; is_argument = get(io, :is_argument, false)))
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
    return false, false
end

"""
    function print_sentence(io, verb::Verb, argument_texts...)

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
    return false, false
end

function print_sentence(io, ::Dress, parent_thing_text, thing_text)
    print(io, "Dress ")
    print(io, parent_thing_text)
    print(io, " in ")
    print(io, thing_text)
end

function (::Give)(universe, thing, parent_thing)
    universe[parent_thing, thing] = carrying
    return false, false
end

function print_sentence(io, ::Give, thing_text, parent_thing_text)
    print(io, "Give ")
    print(io, thing_text)
    print(io, " to ")
    print(io, parent_thing_text)
end

function (::Lay)(universe, thing, parent_thing)
    universe[parent_thing, thing] = supporting
    return false, false
end

function print_sentence(io, ::Lay, thing_text, parent_thing_text)
    print(io, "Lay ")
    print(io, thing_text)
    print(io, " onto ")
    print(io, parent_thing_text)
end

function (::Put)(universe, thing, parent_thing; silent = false)
    universe[parent_thing, thing, silent = silent] = containing
    return false, false
end

function print_sentence(io, ::Put, thing_text, parent_thing_text)
    print(io, "Put ")
    print(io, thing_text)
    print(io, " into ")
    print(io, parent_thing_text)
end

# add relations to player
function (::GoInto)(universe, place)
    Put()(universe, player_proxy(universe), place)
    return true, false
end

function print_sentence(io, ::GoInto, place_text)
    print(io, "Go into ")
    print(io, place_text)
end

function (::GoOnto)(universe, place)
    Lay()(universe, player_proxy(universe), place)
    return true, false
end

function print_sentence(io, ::GoOnto, place_text)
    print(io, "Go onto ")
    print(io, place_text)
end

function (::Take)(universe, thing)
    Give()(universe, thing, universe.player)
    thing.handled = true
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
    return false, false
end

function print_sentence(io, ::Close, thing_text)
    print(io, "Close ")
    print(io, thing_text)
end

function (::Drop)(universe, thing)
    universe[get_parent(universe, universe.player), thing] = containing
    return false, false
end

function print_sentence(io, ::Drop, thing_text)
    print(io, "Drop ")
    print(io, thing_text)
end

function (::Eat)(universe, thing)
    delete!(universe.relationships_graph, get_parent(universe, thing), thing)
    success(universe)
    return false, false
end

function print_sentence(io, ::Eat, thing_text)
    print(io, "Eat ")
    print(io, thing_text)
end

function (verb::Go)(universe, direction)
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
            string_in_color(:red, 
                uppercasefirst(pronoun_for(key)),
                ' ',
                match_verb_to_noun(key, DO),
                "n't fit!"
            )
        )
    end
    return false, false
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
    grandparent_thing, parent_relationship =
        get_parent_relationship(universe, parent_thing)
    universe[grandparent_thing, player] = parent_relationship
    return true, false
end

function print_sentence(io, ::Leave)
    print(io, "Leave")
end

function (::ListInventory)(universe)
    parent_thing = universe.player
    interface = universe.interface
    relations = Dict{Relationship,Vector{Answer}}()
    for (thing, relationship) in out_neighbors_relationships(universe.relationships_graph, parent_thing)
            # we automatically mention everything that is visible
        push!(get!(relations, relationship, Answer[]), Answer(thing))
    end
    println(interface)
    print(interface, uppercasefirst(sprint(show, parent_thing)))
    print(interface, ':')
    println(interface)
    print_relations(universe, 0, Visible(), parent_thing, relations)
    return false, false
end

function print_sentence(io, ::ListInventory)
    print(io, "List inventory")
end

function (::LookAt)(universe, thing)
    println_wrapped(universe.interface, get_description(universe, thing); replace_whitespace = false)
    return false, false
end

function print_sentence(io, ::LookAt, thing_text)
    print(io, "Look at ")
    print(io, thing_text)
end

function (verb::Open)(universe, parent_thing)
    parent_thing.closed = false
    success(universe)
    if !(parent_thing isa Location)
        interface = universe.interface
        relations = Dict{Relationship,Vector{Answer}}()
        for (thing, relationship) in out_neighbors_relationships(universe.relationships_graph, parent_thing)
            if relationship === containing
                # we automatically mention everything that is visible
                push!(get!(relations, relationship, Answer[]), Answer(thing))
            end
        end

        println(interface)
        print(interface, uppercasefirst(sprint(show, parent_thing)))
        if isempty(relations)
            print(interface, ' ')
            print(interface, match_verb_to_noun(parent_thing, BE))
            print(interface, " empty")
        else
            print(interface, ':')
            println(interface)
            print_relations(universe, 0, Visible(), parent_thing, relations)
        end
    end
    return false, false
end

function print_sentence(io, ::Open, thing_text)
    print(io, "Open ")
    print(io, thing_text)
end

function (::Push)(universe, thing, destination)
    final_destination = get_final_destination(universe, direction)
    Put()(universe, thing, final_destination; silent = true)
    Go()(universe, final_destination)
end

function print_sentence(io, ::Push, thing_text, direction_text)
    print(io, "Push ")
    print(io, thing_text)
    print(io, direction_text)
end

function (::Quit)(universe)
    return false, true
end

function print_sentence(io, ::Quit)
    print(io, "Quit")
end

function (::TurnOff)(universe, thing)
    thing.on = false
    success(universe)
    return false, false
end

function print_sentence(io, ::TurnOff, thing_text)
    print(io, "Turn off ")
    print(io, thing_text)
end

function (::TurnOn)(universe, thing)
    thing.on = true
    success(universe)
    return false, false
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
            string_in_color(:red, 
                uppercasefirst(pronoun_for(key)),
                " doesn't fit!"
            )
        )
    end
    return false, false
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

# things will have already been mentioned in the room descrption
function Answer(thing)
    buffer = IOBuffer()
    show(IOContext(buffer, :is_argument => true), thing)
    Answer(String(take!(buffer)), thing)
end

mutable struct Question
    text::String
    answers::Vector{Answer}
end

struct Sentence{Verb}
    verb::Verb
    arguments::Vector{Answer}
end

function Sentence(verb::Verb; arguments = Answer[])
    Sentence(verb, arguments)
end

function print_relationship_to(io, thing_text, relationship, parent_thing)
    if relationship === carrying
        print(io, thing_text)
        print(io, ' ')
        print(io, "that ")
        show(io, parent_thing)
        print(io, ' ')
        print(io, match_verb_to_noun(parent_thing, BE))
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
        show(io, parent_thing)
        print(io, ' ')
        print(io, match_verb_to_noun(parent_thing, BE))
        print(io, " wearing")
    else
        print(io, thing_text)
        print(io, ' ')
        print(io, "to the ")
        show(io, relationship)
        print(io, " of ")
        show(io, parent_thing)
    end
end

function print_relationship_as_verb(io, parent_thing, relationship::Relationship)
    print(io, match_verb_to_noun(parent_thing, VERB_FOR[relationship]))
end

function print_relationship_as_verb(io, parent_thing, direction::Direction)
    show(io, direction)
end

function is_closable_and_closed(thing)
    abstractly_possible(Close(), Reachable(), thing) && thing.closed
end

function is_lockable_and_locked(thing)
    abstractly_possible(Lock(), Reachable(), thing) && thing.locked
end

"""
    blocking(domain, parent_thing, relationship, thing)

`parent_thing` is blocked from accessing `thing` via the `relationship`. 

By default, [`Reachable`](@ref) `parent_thing`s block `thing`s they are `containing` if they are closed.
By default, [`Visible`](@ref) `parent_thing`s block `thing`s they are `containing` if they are closed and not [`is_transparent`](@ref).
"""
function blocking(domain::Reachable, parent_thing, relationship, thing)
    relationship === containing && is_closable_and_closed(parent_thing)
end

function blocking(::Visible, parent_thing, relationship, thing)
    blocking(Reachable(), parent_thing, relationship, thing) && !(is_transparent(parent_thing))
end

"""
    concretely_possible(universe, sentence, domain, thing)

Whether it is currently abstractly_possible to apply `sentence.verb` to a `thing` in a `domain`. 

See [`abstractly_possible`](@ref) for a more abstract possibility. `sentence` will contain already chosen
arguments should you wish to access them.
"""
function concretely_possible(_, sentence, domain, thing)
    abstractly_possible(sentence.verb, domain, thing)
end

function concretely_possible(_, sentence::Sentence{Close}, domain::Reachable, thing)
    abstractly_possible(sentence.verb, domain, thing) && !(thing.closed)
end

function concretely_possible(universe, ::Sentence{<: Union{Go,Push}}, ::ExitDirections, direction)
    !(is_closable_and_closed(get_destination(universe, direction)))
end

function concretely_possible(universe, sentence::Sentence{GoInto}, domain::MoveSiblings, thing)
    abstractly_possible(sentence.verb, domain, thing) && !(is_closable_and_closed(thing))
end

function concretely_possible(_, sentence::Sentence{Lock}, domain::Reachable, thing)
    is_closable_and_closed(thing) && abstractly_possible(sentence.verb, domain, thing) && !(thing.locked)
end

function concretely_possible(universe, ::Sentence{LookAt}, ::Visible, thing)
    get_description(universe, thing) != ""
end

function concretely_possible(_, ::Sentence{Open}, domain::Reachable, thing)
    is_closable_and_closed(thing) && !(is_lockable_and_locked(thing))
end

function concretely_possible(_, sentence::Sentence{Put}, domain::Reachable, thing)
    abstractly_possible(sentence.verb, domain, thing) && 
    !(is_closable_and_closed(thing)) &&
    # concretely_possible't put something into itself
    thing !== sentence.arguments[1].object
end

function concretely_possible(universe, sentence::Sentence{Take}, domain::Reachable, thing)
    if thing isa Location
        false
    else
        parent_thing, relationship =
            get_parent_relationship(universe, thing)
        abstractly_possible(sentence.verb, domain, thing) &&
            !(parent_thing === universe.player && relationship === carrying)
    end
end

function concretely_possible(_, sentence::Sentence{TurnOff}, domain::Reachable, thing)
    abstractly_possible(sentence.verb, domain, thing) && thing.on
end

function concretely_possible(_, sentence::Sentence{TurnOn}, domain::Reachable, thing)
    abstractly_possible(sentence.verb, domain, thing) && !(thing.on)
end

function concretely_possible(_, sentence::Sentence{Unlock}, domain::Reachable, thing)
    is_closable_and_closed(thing) && abstractly_possible(sentence.verb, domain, thing) && thing.locked
end

function concretely_possible(universe, sentence::Sentence{Wear}, domain::Inventory, thing)
    _, relationship = get_parent_relationship(universe, thing)
    abstractly_possible(sentence.verb, domain, thing) && !(relationship == wearing)
end

function append_parent_relationship_to(noun::Noun, _, __)
    noun
end

function append_parent_relationship_to(answer::Answer, relationship, parent_thing)
    buffer = IOBuffer()
    print_relationship_to(buffer, answer.text, relationship, parent_thing)
    Answer(String(take!(buffer)), append_parent_relationship_to(answer.object, relationship, parent_thing))
end

function append_parent_relationship_to(question::Question, relationship, parent_thing)
    buffer = IOBuffer()
    print_relationship_to(buffer, question.text, relationship, parent_thing)
    Question(String(take!(buffer)), map(
        function (answer)
            append_parent_relationship_to(answer, relationship, parent_thing)
        end,
        question.answers
    ))
end

function some_word(verb, domain)
    "something"
end
function what_word(verb, domain)
    "what"
end
function some_word(verb, ::ExitDirections)
    "some way"
end
function what_word(verb, ::ExitDirections)
    "which way"
end

function add_thing_and_relations!(
    answers,
    universe,
    sentence,
    domain,
    parent_thing
)
    verb = sentence.verb
    if concretely_possible(universe, sentence, domain, parent_thing)
        push!(answers, Answer(parent_thing))
    end
    sub_relations = Dict{Relationship,Vector{Answer}}()
    for (thing, relationship) in out_neighbors_relationships(universe.relationships_graph, parent_thing)
        if !(blocking(domain, parent_thing, relationship, thing))
            add_thing_and_relations!(
                get!(sub_relations, relationship, Answer[]),
                universe,
                sentence,
                domain,
                thing
            )
            # we automatically mention everything that is visible
            # recur
        end
    end
    for (sub_relationship, sub_answers) in sub_relations
        if !isempty(sub_answers)
            push!(answers, append_parent_relationship_to(
                if length(sub_answers) == 1
                    only(sub_answers)
                else
                    Answer(some_word(verb, domain), Question(what_word(verb, domain), sub_answers))
                end, 
                sub_relationship, 
                parent_thing
            ))
        end
    end
end

function add_from_domain!(answers, universe, sentence, domain)
    parent_thing, sibling_relationship = get_origin_relationship(universe, domain)
    for (thing, relationship) in out_neighbors_relationships(universe.relationships_graph, parent_thing)
        if relationship === sibling_relationship
            add_thing_and_relations!(
                answers,
                universe,
                sentence,
                domain,
                thing
            )
        end
    end
    directions_graph = universe.directions_graph
    if haskey(directions_graph, parent_thing)
        for (location, direction) in out_neighbors_relationships(directions_graph, parent_thing)
            if location isa AbstractDoor
                add_thing_and_relations!(
                    answers,
                    universe,
                    sentence,
                    domain,
                    location
                )
            end
        end
    end
end


function find_in_domain(universe, sentence, domain::Visible; lit = true)
    answers = Answer[]
    if lit
        add_from_domain!(answers, universe, sentence, domain)
    end
    answers
end

function find_in_domain(universe, sentence, domain::Reachable; lit = true)
    answers = Answer[]
    if lit
        add_from_domain!(answers, universe, sentence, domain)
    else
        for (thing, relationship) in out_neighbors_relationships(universe.relationships_graph, universe.player)
            add_thing_and_relations!(
                answers,
                universe,
                sentence,
                domain,
                thing
            )
        end
    end
    answers
end

function find_in_domain(universe, sentence, domain::ExitDirections; lit = true)
    origin, _ = get_origin_relationship(universe, domain)
    answers = Answer[]
    directions_graph = universe.directions_graph
    if haskey(directions_graph, origin)
        for (location, direction) in out_neighbors_relationships(universe.directions_graph, origin)
            if concretely_possible(universe, sentence, domain, direction)
                push!(answers, Answer(direction))
            end
        end
    end
    answers
end

function find_in_domain(universe, sentence, domain::MoveSiblings; lit = true)
    answers = Answer[]
    origin, sibling_relationship = get_origin_relationship(universe, ExitDirections())
    if lit
        for (thing, relationship) in out_neighbors_relationships(universe.relationships_graph, origin)
            if relationship === sibling_relationship && concretely_possible(universe, sentence, domain, thing)
                push!(answers, Answer(thing))
            end
        end
    end
    answers
end

function find_in_domain(universe, sentence, domain::Inventory; lit = true)
    answers = Answer[]
    for (thing, relationship) in out_neighbors_relationships(universe.relationships_graph, universe.player)
        if relationship === carrying && concretely_possible(universe, sentence, domain, thing)
            push!(answers, Answer(thing))
        end
    end
    answers
end

function print_relations(universe, indent, domain, parent_thing, relations)
    interface = universe.interface
    relationship_indent = indent + 2
    sub_indent = relationship_indent + 2
    for (relationship, answers) in relations
        print(interface, ' ' ^ relationship_indent)
        print_relationship_as_verb(interface, parent_thing, relationship)
        print(interface, ':')
        println(interface)
        for answer in answers
            # don't need the answer text, just the object itself
            thing = answer.object
            sub_relations = Dict{Relationship,Vector{Answer}}()
            # we always stop at the player; inventory must be explicitly asked for
            if !(thing === universe.player)
                for (sub_thing, sub_relationship) in out_neighbors_relationships(universe.relationships_graph, thing)
                    if !(blocking(domain, thing, sub_relationship, sub_thing))
                        # we automatically mention everything that is visible
                        push!(get!(sub_relations, sub_relationship, Answer[]), Answer(sub_thing))
                    end
                end
            end
            print(interface, ' ' ^ sub_indent)
            show(IOContext(interface, :known => false), thing)
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
    parent_thing, sibling_relationship = get_origin_relationship(universe, domain)
    description = get_description(universe, parent_thing)
    if !isempty(description)
        println_wrapped(interface, description)
        println(interface)
    end
    relations = Dict{Union{Relationship,Direction},Vector{Answer}}()
    for (thing, relationship) in out_neighbors_relationships(universe.relationships_graph, parent_thing)
        if relationship === sibling_relationship
            # we automatically mention everything that is visible
            push!(get!(relations, relationship, Answer[]), Answer(thing))
        end
    end
    directions_graph = universe.directions_graph
    if haskey(directions_graph, parent_thing)
        for (location, direction) in out_neighbors_relationships(directions_graph, parent_thing)
            if location isa AbstractDoor
                push!(get!(relations, direction, Answer[]), Answer(location))
            end
        end
    end
    print(interface, ' ' ^ indent)
    show(IOContext(interface, :known => false), parent_thing)
    if !isempty(relations)
        print(interface, ':')
    end
    println(interface)
    print_relations(universe, indent, domain, parent_thing, relations)
end

"""
    function argument_domains(verb::Verb)

List the [`Domain`](@ref)s to take the arguments to `verb` from as a tuple.
"""
function argument_domains(verb::Union{Attach,Give})
    Inventory(), Reachable()
end
function argument_domains(verb::Union{Close,Eat,Open,Take,TurnOn,TurnOff})
    (Reachable(),)
end
function argument_domains(verb::Union{Drop, Wear})
    (Inventory(),)
end
function argument_domains(verb::Go)
    (ExitDirections(),)
end
function argument_domains(verb::Union{GoInto,GoOnto})
    (MoveSiblings(),)
end
function argument_domains(verb::Union{ListInventory, Quit})
    ()
end
function argument_domains(verb::Lay)
    Inventory(), Reachable()
end
function argument_domains(verb::Leave)
    ()
end
function argument_domains(verb::Union{Dress, Lock,Unlock})
    Reachable(), Inventory()
end
function argument_domains(verb::LookAt)
    (Visible(),)
end
function argument_domains(verb::Push)
    MoveSiblings(), ExitDirections()
end
function argument_domains(verb::Put)
    Inventory(), Reachable()
end

"""
    concretely_possible(universe, verb)

Whether it is abstractly_possible to conduct a verb. Defaults to `true`.
"""
function concretely_possible(_, __)
    true
end
function concretely_possible(universe, ::Leave)
    !(get_parent(universe, universe.player) isa Location)
end
function concretely_possible(universe, verb::ListInventory)
    !isempty(out_neighbors_relationships(universe.relationships_graph, universe.player))
end

function choose(interface, sentence, index, answer)
    object = answer.object
    if object isa Question
        answers = object.answers
        println(interface)
        # add an exta line to add space before the question
        # we need take it first to see if its empty or not
        choose(interface, sentence, index, answers[request(
            interface,
            sprint(show, fill_in_the_blank(sentence, index, object.text); context = :suffix => "?"),
            RadioMenu(map(function (sub_answer)
                string(fill_in_the_blank(sentence, index, sub_answer.text))
            end, answers)),
        )])
    else 
        answer
    end
end

function show(io::IO, sentence::Sentence)
    print(io, text_colors[:green])
    print_sentence(io, sentence.verb, Iterators.map(
        function (answer)
            answer.text
        end,
        sentence.arguments
    )...)
    print(io, get(io, :suffix, ""))
    print(io, text_colors[:default])
end

function fill_in_the_blank(sentence, blank_index, replacement)
    arguments_copy = copy(sentence.arguments)
    arguments_copy[blank_index] = Answer(replacement, nothing)
    Sentence(sentence.verb, arguments_copy)
end

function is_lit(universe; domain = Visible())
    parent_thing, sibling_relationship = get_origin_relationship(universe, domain)
    if is_providing_light(parent_thing)
        true
    else
        for (thing, relationship) in out_neighbors_relationships(universe.relationships_graph, parent_thing)
            if relationship === sibling_relationship && is_lit(universe, thing; domain = domain)
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
        for (thing, relationship) in out_neighbors_relationships(universe.relationships_graph, parent_thing)
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
    turn!(universe; introduce = false, should_look_around = false, lit_before = false)

Start a turn in the [`Universe`](@ref), and keep going until the user wins or quits.
"""
function turn!(universe; introduce = false, should_look_around = false, lit_before = false)
    interface = universe.interface
    relationships_graph = universe.relationships_graph
    player = universe.player

    if introduce
        introduction = universe.introduction
        if introduction != ""
            println_wrapped(interface, introduction; replace_whitespace = false)
            println(interface)
        end
    else
        println(interface)
    end

    # reintroduce the player to their surroundings if the end the turn in a new loaction
    lit = is_lit(universe)

    if should_look_around || lit != lit_before
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
    for verb_type in subtypes(Verb)
        verb = verb_type()
        sentence = Sentence(verb)
        dead_end = false
        for domain in argument_domains(verb)
            # returns true for impossible arguments
            answers = find_in_domain(universe, sentence, domain; lit = lit)
            if isempty(answers)
                dead_end = true
                break
            else
                push!(sentence.arguments, 
                    if length(answers) == 1
                        only(answers)
                    else
                        Answer(some_word(verb, domain), Question(what_word(verb, domain), answers))
                    end
                )
            end
        end
        if concretely_possible(universe, verb) && !dead_end
            push!(sentences, sentence)
        end
    end

    sentence = sentences[request(
        interface,
        "",
        RadioMenu(map(
            string,
            sentences,
        )),
    )]
    arguments = sentence.arguments

    for (index, argument) in enumerate(arguments)
        arguments[index] = choose(interface, sentence, index, argument)
    end
    should_look_around, end_game = 
        sentence.verb(universe, Iterators.map(
            function (answer)
                answer.object
            end, 
            arguments
        )...)
    if !end_game
        turn!(universe; should_look_around = should_look_around, lit_before = lit)
    end
    nothing
end

function fill_out(location, user_definition)
    constructor_in_positionals = Any[]
    constructor_in_keywords = Any[]
    constructor_out_arguments = Any[]
    struct_lines = Any[]

    if @capture user_definition (mutable struct typename_ <: thesupertype_
        userlines__
    end)
        is_mutable = true
    elseif @capture user_definition (struct typename_ <: thesupertype_
        userlines__
    end)
        is_mutable = false
    else
        error("Can't parse the user definition")
    end
    for line in userlines
        if @capture line field_::atype_ = default_
            push!(constructor_in_keywords, Expr(:kw, field, default))
        elseif @capture line field_::atype_
            push!(constructor_in_positionals, field)    
        else
            error("Can't parse field")
        end
        push!(struct_lines, location)
        push!(struct_lines, Expr(:(::), field, atype))
        push!(constructor_out_arguments, field)
    end
    (
        typename,
        Expr(:struct, is_mutable, Expr(:<:, typename, thesupertype), Expr(:block, struct_lines...)),
        Expr(:function, 
            Expr(:call, typename, Expr(:parameters, constructor_in_keywords...), constructor_in_positionals...),
            Expr(:block, location, Expr(:call, typename, constructor_out_arguments...))
        )
    )
end

macro proper_noun(user_definition)
    esc(proper_noun(__source__, user_definition))
end

"A door"
@kwdef mutable struct Door <: AbstractDoor
    name::String
    key::Noun
    grammatical_person::GrammaticalPerson = third_person
    indefinite_article::String = "a"
    plural::Bool = false
    closed::Bool = true
    description::String = ""
    locked::Bool = true
end

abstractly_possible(::Open, ::Reachable, ::Door) = true
abstractly_possible(::Unlock, ::Reachable, ::Door) = true

@kwdef struct Person <: Noun
    name::String
    grammatical_person::GrammaticalPerson = third_person
    indefinite_article::String = "a"
    plural::Bool = false
    description::String = ""
end

@kwdef mutable struct Key <: Noun
    name::String
    grammatical_person::GrammaticalPerson = third_person
    indefinite_article::String = "a"
    plural::Bool = false
    description::String = ""
    handled::Bool = false
end

abstractly_possible(::Unlock, ::Inventory, ::Key) = true
abstractly_possible(::Take, ::Reachable, ::Key) = true

@kwdef mutable struct Lamp <: Noun
    name::String
    grammatical_person::GrammaticalPerson = third_person
    indefinite_article::String = "a"
    plural::Bool = false
    on::Bool = false
    description::String = ""
    handled::Bool = false
end

abstractly_possible(::Take, ::Reachable, ::Lamp) = true
abstractly_possible(::TurnOn, ::Reachable, ::Lamp) = true
is_providing_light(noun::Lamp) = noun.on

@kwdef mutable struct Box <: Noun
    name::String
    grammatical_person::GrammaticalPerson = third_person
    indefinite_article::String = "a"
    plural::Bool = false
    closed::Bool = true
    description::String = ""
    handled::Bool = false
end

abstractly_possible(::Open, ::Reachable, ::Box) = true
abstractly_possible(::Take, ::Reachable, ::Box) = true
abstractly_possible(::Put, ::Reachable, ::Box) = true

@kwdef struct Car <: Noun
    name::String
    grammatical_person::GrammaticalPerson = third_person
    indefinite_article::String = "a"
    plural::Bool = false
    description::String = ""
end

abstractly_possible(::GoInto, ::MoveSiblings, ::Car) = true
is_vehicle(::Car) = true
is_transparent(::Car) = true

@kwdef struct Table <: Noun
    name::String
    grammatical_person::GrammaticalPerson = third_person
    indefinite_article::String = "a"
    plural::Bool = false
    description::String = ""
end

abstractly_possible(::Lay, ::Reachable, ::Table) = true

@kwdef mutable struct Clothes <: Noun
    name::String
    grammatical_person::GrammaticalPerson = third_person
    indefinite_article::String = "a"
    plural::Bool = false
    description::String = ""
    handled::Bool = false
end

abstractly_possible(::Wear, ::Inventory, ::Clothes) = true
abstractly_possible(::Take, ::Reachable, ::Clothes) = true

@kwdef struct Food <: Noun
    name::String
    grammatical_person::GrammaticalPerson = third_person
    indefinite_article::String = "a"
    plural::Bool = false
    description::String = ""
end

abstractly_possible(::Eat, ::Reachable, ::Food) = true

@kwdef mutable struct Room <: AbstractRoom
    name::String
    grammatical_person::GrammaticalPerson = third_person
    indefinite_article::String = "a"
    plural::Bool = false
    description::String = ""
    providing_light::Bool = true
    visited::Bool = false
end

is_providing_light(room::Room) = room.providing_light

A = Room(name = "A", description = "A non-descript room", indefinite_article = "")
B = Room(name = "B"; providing_light = false)
C = Room(name = "C")
you = Person(name = "matilda", grammatical_person = second_person, description = "a little worse for the wear")
yellow_key = Key(name = "yellow key", description = "It's yellow, duh!")
yellow_box = Box(name = "yellow box")
red_key = Key(name = "red key")
lamp = Lamp(name = "lamp")
yellow_door =
    Door(name = "yellow door", key = yellow_key, description = "What color do you thing this is?")
yellow_car = Car(name = "car")
table = Table(name = "blue table")
hat = Clothes(name = "hat")
apple = Food(name = "apple")
universe = Universe(you, introduction = "Welcome!")
universe[A, you] = containing
universe[A, yellow_car] = containing
universe[A, table] = containing
universe[A, hat] = containing
universe[A, apple] = containing
universe[B, yellow_box] = containing
universe[yellow_box, yellow_key] = containing
universe[yellow_box, red_key] = containing
universe[A, lamp] = containing
universe[A, B] = north
universe[A, C] = yellow_door, west

turn!(universe; introduce = true, should_look_around = true)

# TODO: try out porting Bronze to see what happens
# TODO: tests
# TODO: backdrops
# TODO: visible and reachable tests

end
