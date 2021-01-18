"""
    MenuAdventures.ExtraDirections

A sub-module with a bunch of extra directions

```jldoctest
julia> using MenuAdventures

julia> using MenuAdventures.Testing

julia> using MenuAdventures.ExtraDirections

julia> @universe struct Universe <: AbstractUniverse
        end;

julia> @noun struct Room <: AbstractRoom
            already_lit::Bool = true
        end;

julia> @noun struct Person <: Noun
        end;

julia> cd(joinpath(pkgdir(MenuAdventures), "test", "ExtraDirections")) do
            check_choices() do interface
                you = Person(
                    "Brandon",
                    grammatical_person = second_person,
                    indefinite_article = "",
                )
                center_room = Room("central room")
                universe = Universe(you, interface = interface)
                universe[center_room, you] = Containing()
                universe[center_room, Room("room")] = West()
                universe[center_room, Room("room")] = NorthWest()
                universe[center_room, Room("room")] = North()
                universe[center_room, Room("room")] = NorthEast()
                universe[center_room, Room("room")] = East()
                universe[center_room, Room("room")] = SouthEast()
                universe[center_room, Room("room")] = South()
                universe[center_room, Room("room")] = SouthWest()
                universe[center_room, Room("room")] = Up()
                universe[center_room, Room("room")] = Down()
                universe[center_room, Room("room")] = Inside()
                universe[center_room, Room("room")] = Outside()
                universe
            end
        end
true
```
"""
module ExtraDirections

import Base: show
using MenuAdventures: Direction
import MenuAdventures: opposite

"""
    NorthWest()

A [`Direction`](@ref).
"""
struct NorthWest <: Direction end

export NorthWest

function show(io::IO, ::NorthWest)
    print(io, "north-west")
end

opposite(::NorthWest) = SouthEast()

"""
    SouthWest()

A [`Direction`](@ref).
"""
struct SouthWest <: Direction end

export SouthWest

function show(io::IO, ::SouthWest)
    print(io, "south-west")
end

opposite(::SouthWest) = NorthEast()

"""
    SouthEast()

A [`Direction`](@ref).
"""
struct SouthEast <: Direction end

export SouthEast

function show(io::IO, ::SouthEast)
    print(io, "south-east")
end

opposite(::SouthEast) = NorthWest()

"""
    NorthEast()

A [`Direction`](@ref).
"""
struct NorthEast <: Direction end

export NorthEast

function show(io::IO, ::NorthEast)
    print(io, "north-east")
end

opposite(::NorthEast) = SouthWest()

"""
    Up()

A [`Direction`](@ref).
"""
struct Up <: Direction end

export Up

function show(io::IO, ::Up)
    print(io, "up")
end

opposite(::Up) = Down()

"""
    Down()

A [`Direction`](@ref).
"""
struct Down <: Direction end

export Down

function show(io::IO, ::Down)
    print(io, "down")
end

opposite(::Down) = Up()

"""
    Inside()

A [`Direction`](@ref).
"""
struct Inside <: Direction end

export Inside

function show(io::IO, ::Inside)
    print(io, "inside")
end

opposite(::Inside) = Outside()

"""
    Outside()

A [`Direction`](@ref).
"""
struct Outside <: Direction end

export Outside

function show(io::IO, ::Outside)
    print(io, "outside")
end

opposite(::Outside) = Inside()

end