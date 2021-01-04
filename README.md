# MenuAdventures

[![Latest](https://img.shields.io/badge/docs-dev-blue.svg)](https://bramtayl.github.io/MenuAdventures.jl/dev)
[![CodeCov](https://codecov.io/gh/bramtayl/AudioSchedules.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bramtayl/MenuAdventures.jl)

MenuAdventures is a Julia package for writing menu based adventures.

MenuAdventures is heavily inspired by Inform7. Inform7 is an astounding achievement in terms of natural language programming. However, I've made some different choices for MenuAdventures.

MenuAdventures takes user input as menu choices, rather than unconstrained text. I think this will allow for a much more enjoyable player experience, because players will not have to guess what word the parser will recognize. Moreover, I think this will enhance dialog with non-player characters. Because dialog options are specified by the game designer, they can be much more nuanced.

Game designers will use regular Julia code to create the universe. Inform7 offers many different ways to design identical universes. This can make it difficult to learn how to code in Inform7.

MenuAdventures also takes advantage the magic of multiple dispatch. I've left detailed documentation on how to create your own `Noun` and `Action` subtypes. You can overload various methods to completely customize them.

MenuAdventures features a flexible boolean trait system. This allows you to create nouns with creative combinations of traits, such as edible boxes, or talking bananas. Beyond MenuAdventures, I think this system could serve as a model of how traits might be designed for Base Julia.

I'm very curious to see what kind of games people make with MenuAdventures, mostly because I'd like to play them. Happy to take suggestions for design improvements!

