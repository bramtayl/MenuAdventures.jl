using MenuAdventures
using MenuAdventures: look_around_default, Person, println_wrap
import MenuAdventures: get_description, look_around

@noun mutable struct VisitedRoom <: AbstractRoom
    already_lit::Bool = true
    visited::Bool = false
end

function look_around(universe, domain, blocking_thing::VisitedRoom, blocked_relationship)
    blocking_thing.visited = true
    look_around_default(universe, domain, blocking_thing, blocked_relationship)
end

@noun struct Person

end

belle = Person(
    "Belle",
    description = "You are nontrivially the worse for your journey -- hungry, dirty, and tired. But all that can be seen to later",
    grammatical_person = second_person,
    indefinite_article = ""
)

universe = Universe(belle, introduction = "When the seventh day comes and it is time for you to return to the castle in the forest, your sisters cling to your sleeves. 
	
'Don't go back,' they say, and 'When will we ever see you again?' But you imagine they will find consolation somewhere.
	
Your father hangs back, silent and moody. He has spent the week as far from you as possible, working until late at night. Now he speaks only to ask whether the Beast treated you 'properly.' Since he obviously has his own ideas about what must have taken place over the past few years, you do not reply beyond a shrug.
	
You breathe more easily once you're back in the forest, alone.

Bronze is a puzzle-oriented adaptation of Beauty and the Beast with an expansive geography for the inveterate explorer. 

Features help for novice players, a detailed adaptive hint system to assist players who get lost, and a number of features to make navigating a large space more pleasant.")

@noun mutable struct VisitedSwitchRoom <: AbstractRoom
    providing_light::Bool = true
    visited::Bool = false
    visited_descrpition::String = ""
    unvisited_description::String = ""
end

function get_description(_, room::VisitedSwitchRoom)
    if room.visited
        room.visited_description
    else
        room.unvisted_description
    end
end

drawbridge = VisitedSwitchRoom(
    "the Drawbridge",
    indefinite_article = "",
    visited_description = "There is little enough purpose in loitering outside: He and his servants never come out here, and whatever you must do, you will have to do within",
    unvisited_description = "Even in your short absence, the castle has come to look strange to you again. When you came here first, you stood a long while on the drawbridge, unready to cross the moat, for fear of the spells that might bind you if you did. This time it is too late to worry about such things"
)

@noun mutable struct Scenery <: Noun
    description::String = ""
end

castle_exterior = Scenery(
    "the castle exterior",
    description = "The drawbridge looks longer than it actually is; the towers are so high that the tops are lost in cloud, and looking east or west, you cannot see the furthest extent of the walls. An optical illusion: it is smaller inside.

Probably.",
    indefinite_article = ""
)

universe[drawbridge, castle_exterior] = containing

@noun mutable struct OpenTextDoor <: AbstractDoor
    closed::Bool = true
    description::String = ""
    open_text::String = ""
end

function (::Open)(universe, door::OpenTextDoor)
    door.closed = false
    println_wrap(universe.interface, door.open_text)
    return false
end

ever_possible(::Open, ::Reachable, ::OpenTextDoor) = true