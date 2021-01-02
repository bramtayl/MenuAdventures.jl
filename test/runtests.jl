using MenuAdventures: Box, Car, Clothes, containing, Door, Food, Key, Lamp, MenuAdventures, north, Person, Room, second_person, Table, turn!, Universe, west
using Documenter: doctest
using Test: @test

doctest(MenuAdventures)

using REPL.Terminals: TTYTerminal

cd(joinpath(pkgdir(MenuAdventures), "test"))

you = Person(name = "matilda", grammatical_person = second_person, description = "a little worse for the wear")
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

output = IOBuffer()
universe = Universe(you, 
    introduction = "Welcome!",
    interface = TTYTerminal("unix", stdin, output, stderr)
)
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

const KEY_PRESS = Dict(:up => "\e[A", :down => "\e[B", :enter => "\r")

function test_turn_sequence(universe, option_numbers)
    for option_number in option_numbers
        for _ in 1:(option_number - 1)
            write(stdin.buffer, KEY_PRESS[:down])
        end
        write(stdin.buffer, KEY_PRESS[:enter])
    end
    turn!(universe; introduce = true, should_look_around = true)
    String(take!(universe.interface.out_stream))
end

@test test_turn_sequence(universe, [6, 2, 2, 5, 1, 10, 6, 1, 4, 5, 2, 9, 9, 2, 5, 7, 5, 8, 2, 8, 6, 3, 1, 2, 11, 7, 2, 1, 7, 2, 3, 2, 2, 1, 8, 4, 2, 1, 8, 6, 4, 5, 2, 1, 1, 2, 2, 3, 4, 2, 1, 5, 2, 2, 2, 2, 8]) == read("transcript.txt", String)

