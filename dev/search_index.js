var documenterSearchIndex = {"docs":
[{"location":"#Interface","page":"Interface","title":"Interface","text":"","category":"section"},{"location":"","page":"Interface","title":"Interface","text":"Modules = [MenuAdventures]","category":"page"},{"location":"","page":"Interface","title":"Interface","text":"Modules = [MenuAdventures]","category":"page"},{"location":"#MenuAdventures.VERB_FOR","page":"Interface","title":"MenuAdventures.VERB_FOR","text":"const VERB_FOR = Dict{Relationship, Verb}\n\nGet the verb form of a Relationship, or roughly, remove the ing.\n\n\n\n\n\n","category":"constant"},{"location":"#MenuAdventures.AbstractDoor","page":"Interface","title":"MenuAdventures.AbstractDoor","text":"An abstract door\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.AbstractRoom","page":"Interface","title":"MenuAdventures.AbstractRoom","text":"abstract type AbstractRoom <: Location end\n\nMust have a mutable visited field.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Action","page":"Interface","title":"MenuAdventures.Action","text":"abstract type Action end\n\nA action is an action the player can take.\n\nIt should be fairly easy to create new verbs: you will need to define ever_possible for abstract possibilities, possible_now for concrete possibilities, argument_domains to specify the domain of the arguments, and print_sentence for printing the sentence.\n\nMost importantly, define:\n\nfunction (::MyNewAction)(universe, arguments...) -> Bool\n\nWhich will conduct the action based on user choices.  Return true to end the game.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Attach","page":"Interface","title":"MenuAdventures.Attach","text":"struct Attach <: Action end\n\nAttach something to something else.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Close","page":"Interface","title":"MenuAdventures.Close","text":"struct Close <: Action end\n\nClose something.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Direction","page":"Interface","title":"MenuAdventures.Direction","text":"@enum Direction north south west east north_west north_east south_west south_east up down inside outside\n\nDirections show the relationships between Locations.\n\nYou can use opposite to find the opposite of a direction.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Domain","page":"Interface","title":"MenuAdventures.Domain","text":"abstract type Domain end\n\nA domain refers to a search space for a specific argument to a action.\n\nFor example, you are only able to look at things in the Visible domain. Domains serve both as a way of distinguishing different arguments to a action, and also, categorizing the environment around the player. Users could theoretically add a new domain.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Door","page":"Interface","title":"MenuAdventures.Door","text":"A door\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Dress","page":"Interface","title":"MenuAdventures.Dress","text":"struct Dress <: Action end\n\nDress someone in something.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Drop","page":"Interface","title":"MenuAdventures.Drop","text":"struct Drop <: Action end\n\nDrop something.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Eat","page":"Interface","title":"MenuAdventures.Eat","text":"struct Eat <: Action end\n\nEat something.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.ExitDirections","page":"Interface","title":"MenuAdventures.ExitDirections","text":"struct ExitDirections <: Domain end\n\nDirections that a player, or the vehicle a player is in, might exit in.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Give","page":"Interface","title":"MenuAdventures.Give","text":"struct Give <: Action end\n\nGive something to someone.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Go","page":"Interface","title":"MenuAdventures.Go","text":"struct Go <: Action end\n\nGo some way.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.GoInto","page":"Interface","title":"MenuAdventures.GoInto","text":"struct GoInto <: Action end\n\nGo into something.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.GoOnto","page":"Interface","title":"MenuAdventures.GoOnto","text":"struct GoOnto <: Action end\n\nGo onto something.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.GrammaticalPerson","page":"Interface","title":"MenuAdventures.GrammaticalPerson","text":"@enum GrammaticalPerson first_person second_person third_person\n\nGrammatical person\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Inventory","page":"Interface","title":"MenuAdventures.Inventory","text":"struct Inventory <: Domain end\n\nThings the player is carrying.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Leave","page":"Interface","title":"MenuAdventures.Leave","text":"struct Leave <: Action end\n\nLeave something.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.ListInventory","page":"Interface","title":"MenuAdventures.ListInventory","text":"struct ListInventory <: Action end\n\nList your inventory.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Location","page":"Interface","title":"MenuAdventures.Location","text":"abstract type Location <: Noun end\n\nA location (room or door)\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Lock","page":"Interface","title":"MenuAdventures.Lock","text":"struct Lock <: Action end\n\nLock something with something.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.LookAt","page":"Interface","title":"MenuAdventures.LookAt","text":"struct LookAt <: Action end\n\nLook at something.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.MoveSiblings","page":"Interface","title":"MenuAdventures.MoveSiblings","text":"struct MoveSiblings <: Domain end\n\nThing that are in/on the same place the player could more from.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Noun","page":"Interface","title":"MenuAdventures.Noun","text":"abstract type Noun end\n\nNouns must have the following fields:\n\nname::String plural::Bool grammaticalperson::GrammaticalPerson indefinitearticle::String\n\nThey are characterized by the following traits and methods:\n\never_possible\nget_description,\nis_providing_light,\nis_transparent,\nis_vehicle.\n\nSet indefinite_article to \"\" for proper nouns.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Open","page":"Interface","title":"MenuAdventures.Open","text":"struct Open <: Action end\n\nOpen something.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Push","page":"Interface","title":"MenuAdventures.Push","text":"struct Push <: Action end\n\nPush something some way.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.PutInto","page":"Interface","title":"MenuAdventures.PutInto","text":"struct PutInto <: Action end\n\nPut something into something.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.PutOnto","page":"Interface","title":"MenuAdventures.PutOnto","text":"struct PutOnto <: Action end\n\nPutOnto something onto something\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Quit","page":"Interface","title":"MenuAdventures.Quit","text":"struct Quit <: Action end\n\nQuit\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Reachable","page":"Interface","title":"MenuAdventures.Reachable","text":"struct Reachable <: Domain end\n\nAnything the player possible_now reach.\n\nPlayers possible_now't reach through closed containers by default.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Relationship","page":"Interface","title":"MenuAdventures.Relationship","text":"@enum Relationship carrying containing incorporating supporting wearing\n\nRelationships show the relationshp of a thing to its parent_thing.\n\nA is containing B means B is in A  A is incorporating B means B is part of A  A is supporting B means B is on top of A\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Take","page":"Interface","title":"MenuAdventures.Take","text":"struct Take <: Action end\n\nTake something\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.TurnOff","page":"Interface","title":"MenuAdventures.TurnOff","text":"struct TurnOff <: Action end\n\nTurn something off\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.TurnOn","page":"Interface","title":"MenuAdventures.TurnOn","text":"struct TurnOn <: Action end\n\nTurn something on\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Universe-Tuple{Any}","page":"Interface","title":"MenuAdventures.Universe","text":"function Universe(\n    player;\n    interface = terminal,\n    introduction = \"\",\n    relationships_graph = MetaGraph(DiGraph(), Label = Noun, EdgeMeta = Relationship),\n    directions_graph = MetaGraph(DiGraph(), Label = Location, EdgeMeta = Direction),\n    choices_log::Vector{Int}\n)\n\nThe universe contains a player, a text interface, an introduction, and the relationships between nouns and locations.\n\nThe universe is organized as interlinking web of locations connected by Directions. For any origin and destination, there should be no more than one connection to a particular direction. Each location is the root of a Relationship tree. Every noun should have one and only one parent, (except for locations), which are at the root of trees and have no parent.\n\nYou can add a new thing to the universe, or change its location, by specifying its  relation to another thing:\n\nuniverse[parent_thing, thing, silent = false] = relationship\n\nSet silent = true to suppress the \"Ok\" message.\n\nYou possible_now add a connection between locations too, optionally interspersed by a door:\n\nuniverse[parent_thing, destination, one_way = false] = direction\nuniverse[parent_thing, destination, one_way = false] = door, direction\n\nBy default, this will create a way back in the opposite direction. To suppress this, set one_way = true\n\n\n\n\n\n","category":"method"},{"location":"#MenuAdventures.Unlock","page":"Interface","title":"MenuAdventures.Unlock","text":"struct Unlock <: Action end\n\nUnlock something\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Verb-Tuple{Any}","page":"Interface","title":"MenuAdventures.Verb","text":"function Verb(base; third_person_singular_present = string(base, \"s\"))\n\nCreate an English verb.\n\nUse subject_to_verb to get the form of a verb to agree with a subject.\n\n\n\n\n\n","category":"method"},{"location":"#MenuAdventures.Visible","page":"Interface","title":"MenuAdventures.Visible","text":"struct Visible <: Domain end\n\nAnything the player possible_now see.\n\nPlayers possible_now't see into closed, opaque containers.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.Wear","page":"Interface","title":"MenuAdventures.Wear","text":"struct Wear <: Action end\n\nWear something.\n\n\n\n\n\n","category":"type"},{"location":"#MenuAdventures.argument_domains-Tuple{Union{MenuAdventures.Attach, MenuAdventures.Give}}","page":"Interface","title":"MenuAdventures.argument_domains","text":"function argument_domains(action::Action)\n\nA tuple of the Domains for each argument of an action.\n\n\n\n\n\n","category":"method"},{"location":"#MenuAdventures.blocking-Tuple{MenuAdventures.Reachable,Any,Any,Any}","page":"Interface","title":"MenuAdventures.blocking","text":"blocking(domain, parent_thing, relationship, thing)\n\nparent_thing is blocked from accessing thing via the relationship.\n\nBy default, Reachable parent_things block things they are containing if they are closed. By default, Visible parent_things block things they are containing if they are closed and not is_transparent.\n\n\n\n\n\n","category":"method"},{"location":"#MenuAdventures.ever_possible-Tuple{Any,Any,Any}","page":"Interface","title":"MenuAdventures.ever_possible","text":"ever_possible(action::Action, domain::Domain, noun::Noun)\n\nWhether is is abstractly possible to apply a action to a noun from a particular domain.\n\nFor whether it is concretely possible for the player in at a certain moment, see possible_now. Most possibilities default to false, with some exceptions:\n\never_possible(::PutInto, ::Inventory, _) = true\never_possible(::Drop, ::Inventory, _) = true\never_possible(::PutOnto, ::Inventory, _) = true\never_possible(action::TurnOff, domain::Reachable, noun) = \n    ever_possible(TurnOn(), domain, noun)\never_possible(action::Close, domain::Reachable, noun) = \n    ever_possible(Open(), domain, noun)\never_possible(action::Lock, domain::Reachable, noun) = \n    ever_possible(Unlock(), domain, noun)\never_possible(::Lock, domain::Inventory, noun) = \n    ever_possible(Unlock(), domain, noun)\n\nCertain possibilities come with required fields:\n\never_possible(::TurnOn, ::Reachable, noun) requires that noun has a mutable on::Bool field. ever_possible(::Open, ::Reachable, noun requires that noun has a mutable closed::Bool field. ever_possible(::Unlock, ::Reachable, noun) requires that noun has a key::Noun field and a mutable locked::Bool field. ever_possible(::Take, ::Reachable, noun) requires that noun has a mutable handled::Bool field.\n\n\n\n\n\n","category":"method"},{"location":"#MenuAdventures.get_description-Tuple{Any,MenuAdventures.Noun}","page":"Interface","title":"MenuAdventures.get_description","text":"get_description(universe, thing::Noun) = thing.description\n\nGet the description of a thing.\n\nUnless you overload get_description, nouns are required to have a description field.\n\n\n\n\n\n","category":"method"},{"location":"#MenuAdventures.is_providing_light-Tuple{MenuAdventures.Noun}","page":"Interface","title":"MenuAdventures.is_providing_light","text":"is_providing_light(::Noun) = false\n\nWhether something provides its own light. Naturally lit locations and light sources both are providing light.\n\n\n\n\n\n","category":"method"},{"location":"#MenuAdventures.is_transparent-Tuple{MenuAdventures.Noun}","page":"Interface","title":"MenuAdventures.is_transparent","text":"is_transparent(thing::Noun) = false\n\nWhether you can see through thing into its contents.\n\n\n\n\n\n","category":"method"},{"location":"#MenuAdventures.is_vehicle-Tuple{MenuAdventures.Noun}","page":"Interface","title":"MenuAdventures.is_vehicle","text":"is_vehicle(::Noun) = false\n\nWhether something is a vehicle.\n\n\n\n\n\n","category":"method"},{"location":"#MenuAdventures.opposite-Tuple{MenuAdventures.Direction}","page":"Interface","title":"MenuAdventures.opposite","text":"function opposite(direction::Direction)\n\nThe opposite of a direction.\n\n\n\n\n\n","category":"method"},{"location":"#MenuAdventures.possible_now-NTuple{4,Any}","page":"Interface","title":"MenuAdventures.possible_now","text":"possible_now(universe, sentence, domain, thing)\n\nWhether it is currently ever_possible to apply sentence.action to a thing in a domain.\n\nSee ever_possible for a more abstract possibility. sentence will contain already chosen arguments should you wish to access them.\n\n\n\n\n\n","category":"method"},{"location":"#MenuAdventures.possible_now-Tuple{Any,Any}","page":"Interface","title":"MenuAdventures.possible_now","text":"possible_now(universe, action)\n\nWhether it is possible to conduct an action. Defaults to true; you can set to false for some actions without arguments.\n\n\n\n\n\n","category":"method"},{"location":"#MenuAdventures.print_sentence-Tuple{Any,MenuAdventures.Attach,Any,Any}","page":"Interface","title":"MenuAdventures.print_sentence","text":"function print_sentence(io, action::Action, argument_texts...)\n\nPrint a sentence to io. This allows for adding connectives like with.\n\n\n\n\n\n","category":"method"},{"location":"#MenuAdventures.subject_to_verb-Tuple{Any,Any}","page":"Interface","title":"MenuAdventures.subject_to_verb","text":"subject_to_verb(subject, verb)\n\nFind the Verb form to agree with a subject.\n\n\n\n\n\n","category":"method"},{"location":"#MenuAdventures.turn!-Tuple{Any}","page":"Interface","title":"MenuAdventures.turn!","text":"turn!(universe; introduce = false, should_look_around = false)\n\nStart a turn in the Universe, and keep going until the user wins or quits.\n\n\n\n\n\n","category":"method"}]
}